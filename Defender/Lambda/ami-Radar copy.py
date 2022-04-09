# AMI Radar

# The AMI Radar is a Lambda based script that 
# - is used for find the latest AMI from RCE.
# - is run daily via a Scheduled CloudWatch Event.

#%%
import os
import urllib3
import json
import jmespath
import datetime
import boto3
import botocore
import pymsteams
from collections import defaultdict
#from lng_aws_clients import session, ec2

#%%
ami_cache = {}


def cache_ami_data(json_data):
    for image in json_data['Images']:
        if not image['ImageId'] in ami_cache:
            ami_cache[image['ImageId']] = image


def get_qualys_report():
    # Obtain Qualys Vulnerability Report
    report_url = os.getenv('qualys_report_url')
    pool_manager = urllib3.PoolManager(
        retries=urllib3.Retry(
            total=5,
            backoff_factor=.5,
            status_forcelist=[500, 502, 503, 504]
        )
    )
    response = pool_manager.request('GET', report_url)
    if response.status < 300 and response.status >= 200:
        return json.loads(pool_manager.request('GET', report_url).data.decode('utf-8'))
    else:
        print("request url: {}".format(response._request_url))
        print("headers: {}".format(response.headers))
        print("status: {}".format(response.status))
        print("body: {}".format(response.data.decode('utf-8')))
        raise Exception("Getting report failed with {}".format(response.status))


def build_ami_dict_by_sev(report_json):
    # Filter Out Sev 4s and 5s, removing duplicates
    reported_severities = list(set(jmespath.search('query_result.data.rows[].Severity', report_json)))
    ami_dict = defaultdict()

    for sev in sorted(reported_severities, reverse=True):
        ami_dict[sev] = set(
            jmespath.search(
                "query_result.data.rows[?Severity == `{}`].\"Image ID\"".format(sev), report_json
            )
        )

    # ensure each AMI is listed under it's highest sev, and convert to lists
    # TODO Figure out how to do this with any number of severities
    if ami_dict.get(1):
        ami_dict[1] = list(ami_dict[1] - ami_dict[2] - ami_dict[3] - ami_dict[4] - ami_dict[5])
    if ami_dict.get(2):
        ami_dict[2] = list(ami_dict[2] - ami_dict[3] - ami_dict[4] - ami_dict[5])
    if ami_dict.get(3):
        ami_dict[3] = list(ami_dict[3] - ami_dict[4] - ami_dict[5])
    if ami_dict.get(4):
        ami_dict[4] = list(ami_dict[4] - ami_dict[5])
    if ami_dict.get(5):
        ami_dict[5] = list(ami_dict[5])

    return ami_dict


def apply_qualys_tags_to_amis():
    print("Start apply_qualys_tags_to_amis()")
    response = defaultdict()

    # Get AMI Unshare Date Offsets from environment
    dev_offset = int(os.getenv('dev_unshare_offset'))
    cert_offset = int(os.getenv('cert_unshare_offset'))
    prod_offset = int(os.getenv('prod_unshare_offset'))

    # Obtain the Qualys Report
    report_json = get_qualys_report()

    # Extract Report Generation Date
    report_date = datetime.datetime.strptime(report_json["query_result"]["retrieved_at"], "%Y-%m-%dT%H:%M:%S.%f%z")

    # Generate a dictionary with severity as keys and lists of AMIs as values
    # Each AMI only appears once, at it's highest sev
    ami_dict = build_ami_dict_by_sev(report_json)

    # pre-create list

    # For each severity rating in the dictionary
    for rating in ami_dict:
        # Get a list of all Images already flagged with this rating or higher (Max of 5)
        filtered_ami_json = ec2.get_client().describe_images(
            ImageIds=ami_dict[rating],
            Filters=[
                {
                    "Name": 'tag:QualysVulnerability',
                    "Values": list(map(str, list(range(int(rating), 6))))
                }
            ]
        )

        cache_ami_data(filtered_ami_json)

        # Filter the response to a list of AMI IDs
        pre_tagged_amis = jmespath.search('Images[].ImageId', filtered_ami_json)

        # Remove AMIs that are already tagged from the list of AMIs to tag, so that we don't muck up the UnshareDates
        untagged_amis = list(set(ami_dict[rating]) - set(pre_tagged_amis))

        # We need to filter out all untagged AMIs that do not belong to the executing account
        owned_untagged_ami_json = ec2.get_client().describe_images(
            ImageIds=untagged_amis,
            Filters=[
                {
                    'Name': "owner-id",
                    'Values': [
                        boto3.client('sts').get_caller_identity().get('Account')
                    ]
                }
            ]
        )

        cache_ami_data(owned_untagged_ami_json)

        owned_untagged_amis = jmespath.search('Images[].ImageId', owned_untagged_ami_json)

        if len(owned_untagged_amis) > 0:
            # Apply Rating tag and datestamp to all AMIs that aren't already tagged with rating or higher
            try:
                ec2.get_client().create_tags(
                    DryRun=bool(os.getenv('dryRun')),
                    Resources=owned_untagged_amis,
                    Tags=[
                        {
                            "Key": "QualysVulnerability",
                            "Value": str(rating)
                        },
                        {
                            "Key": "QualysVulnerabilityDate",
                            "Value": report_date.isoformat()
                        },
                        {
                            "Key": "UnshareDevOn",
                            "Value": (report_date + datetime.timedelta(days=dev_offset)).isoformat()
                        },
                        {
                            "Key": "UnshareCertOn",
                            "Value": (report_date + datetime.timedelta(days=cert_offset)).isoformat()
                        },
                        {
                            "Key": "UnshareProdOn",
                            "Value": (report_date + datetime.timedelta(days=prod_offset)).isoformat()
                        }
                    ]
                )
            except botocore.exceptions.ClientError as e:
                if e.response['Error']['Code'] != 'DryRunOperation':
                    raise e

            response[rating] = owned_untagged_amis
    return response


def unshare_amis():
    print("Start unshare_amis()")
    response = defaultdict()
    dev_accounts = os.getenv("dev_account_list").replace(" ", "").split(",")
    cert_accounts = os.getenv("cert_account_list").replace(" ", "").split(",")
    prod_accounts = os.getenv("prod_account_list").replace(" ", "").split(",")
    delete_dev_tag_from_amis = []
    delete_cert_tag_from_amis = []
    delete_prod_tag_from_amis = []

    response = ec2.get_client().describe_images(
        Filters=[
            {
                'Name': "owner-id",
                'Values': [
                    boto3.client('sts').get_caller_identity().get('Account')
                ]
            },
            {
                'Name': "tag-key",
                'Values': [
                    "Unshare*On"
                ]
            }
        ]
    )

    cache_ami_data(response)

    for ami in response['Images']:
        print("    Checking AMI: {}".format(ami['ImageId']))
        # Extract unshare dates from tags
        dev_unshare_date = None
        cert_unshare_date = None
        prod_unshare_date = None

        for tag in ami['Tags']:
            if tag['Key'] == "UnshareDevOn" and tag["Value"]:
                dev_unshare_date = datetime.datetime.strptime(tag["Value"], "%Y-%m-%dT%H:%M:%S.%f%z")
            elif tag['Key'] == "UnshareCertOn":
                cert_unshare_date = datetime.datetime.strptime(tag["Value"], "%Y-%m-%dT%H:%M:%S.%f%z")
            elif tag['Key'] == "UnshareProdOn":
                prod_unshare_date = datetime.datetime.strptime(tag["Value"], "%Y-%m-%dT%H:%M:%S.%f%z")
            if dev_unshare_date is not None and cert_unshare_date is not None and prod_unshare_date is not None:
                break

        # Build LaunchPermissions remove list
        remove_launch_perms = []
        if dev_unshare_date and dev_unshare_date <= datetime.datetime.now(datetime.timezone.utc):
            remove_launch_perms += dev_accounts
            delete_dev_tag_from_amis.append(ami['ImageId'])
        if cert_unshare_date and cert_unshare_date <= datetime.datetime.now(datetime.timezone.utc):
            remove_launch_perms += cert_accounts
            delete_cert_tag_from_amis.append(ami['ImageId'])
        if prod_unshare_date and prod_unshare_date <= datetime.datetime.now(datetime.timezone.utc):
            remove_launch_perms += prod_accounts
            delete_prod_tag_from_amis.append(ami['ImageId'])

        # Execute modify_image_attribute call
        if len(remove_launch_perms) > 0:
            print("        Modified Image Attributes")
            try:
                ec2.get_client().modify_image_attribute(
                    DryRun=bool(os.getenv('dryRun')),
                    Attribute='launchPermission',
                    ImageId=ami['ImageId'],
                    OperationType='remove',
                    UserIds=remove_launch_perms
                )
            except botocore.exceptions.ClientError as e:
                if e.response['Error']['Code'] != 'DryRunOperation':
                    raise e

    now = datetime.datetime.now().isoformat()

    # Remove UnshareTags from AMIs to prevent unnecessary future processing
    if len(delete_dev_tag_from_amis) > 0:
        try:
            ec2.get_client().delete_tags(
                DryRun=bool(os.getenv('dryRun')),
                Resources=delete_dev_tag_from_amis,
                Tags=[
                    {
                        'Key': 'UnshareDevOn'
                    }
                ]
            )
        except botocore.exceptions.ClientError as e:
            if e.response['Error']['Code'] != 'DryRunOperation':
                raise e

        try:
            ec2.get_client().create_tags(
                DryRun=bool(os.getenv('dryRun')),
                Resources=delete_dev_tag_from_amis,
                Tags=[
                    {
                        'Key': 'DevUnsharedOn',
                        'Value': now
                    }
                ]
            )
        except botocore.exceptions.ClientError as e:
            if e.response['Error']['Code'] != 'DryRunOperation':
                raise e

    if len(delete_cert_tag_from_amis) > 0:
        try:
            ec2.get_client().delete_tags(
                DryRun=bool(os.getenv('dryRun')),
                Resources=delete_cert_tag_from_amis,
                Tags=[
                    {
                        'Key': 'UnshareCertOn'
                    }
                ]
            )
        except botocore.exceptions.ClientError as e:
            if e.response['Error']['Code'] != 'DryRunOperation':
                raise e
            
        try:
            ec2.get_client().create_tags(
                DryRun=bool(os.getenv('dryRun')),
                Resources=delete_cert_tag_from_amis,
                Tags=[
                    {
                        'Key': 'CertUnsharedOn',
                        'Value': now
                    }
                ]
            )
        except botocore.exceptions.ClientError as e:
            if e.response['Error']['Code'] != 'DryRunOperation':
                raise e
            
    if len(delete_prod_tag_from_amis) > 0:
        try:
            ec2.get_client().delete_tags(
                DryRun=bool(os.getenv('dryRun')),
                Resources=delete_prod_tag_from_amis,
                Tags=[
                    {
                        'Key': 'UnshareProdOn'
                    }
                ]
            )
        except botocore.exceptions.ClientError as e:
            if e.response['Error']['Code'] != 'DryRunOperation':
                raise e
            
        try:
            ec2.get_client().create_tags(
                DryRun=bool(os.getenv('dryRun')),
                Resources=delete_prod_tag_from_amis,
                Tags=[
                    {
                        'Key': 'ProdUnsharedOn',
                        'Value': now
                    }
                ]
            )
        except botocore.exceptions.ClientError as e:
            if e.response['Error']['Code'] != 'DryRunOperation':
                raise e
            
    response['dev'] = delete_dev_tag_from_amis
    response['cert'] = delete_cert_tag_from_amis
    response['prod'] = delete_prod_tag_from_amis
    return response


def notify_flagged_amis(flagged_amis):
    webhook_url = os.getenv('MS_TEAMS_WEBHOOK')
    if not webhook_url or not len(flagged_amis):
        return

    message = pymsteams.connectorcard(webhook_url, http_timeout=15)
    message.title("AMI Janitor")
    message.summary("New Qualys Vulnerabilities Discovered")
    # create the section
    message.text("The following AMIs have known vulnerabilities, recently reported by Qualys.   \nThey will be unshared from our accounts after the configured grace period.")
    section = pymsteams.cardsection()

    # Section Title
    section.title("New Qualys Vulnerabilities Discovered")
    text = "<tr><th>Severity</th><th>AMI</th><th>Name</th></tr>"
    for rating in flagged_amis:
        described_amis = ec2.get_client().describe_images(ImageIds=flagged_amis[rating])
        cache_ami_data(described_amis)
        for ami in flagged_amis[rating]:
            text += "<tr><td>" + str(rating) + "</td><td nowrap>" + ami + "</td><td nowrap>" + ami_cache.get(ami,{}).get("Name", "Unknown") + "</td></tr>"
    section.text("<blockquote><table>" + text + "</table></blockquote>")

    # Add your section to the connector card object before sending
    message.addSection(section)

    try:
        message.send()
    except:
        pass


def notify_unshared_amis(unshared_amis):
    webhook_url = os.getenv('MS_TEAMS_WEBHOOK')
    if not webhook_url or not (len(unshared_amis['dev']) + len(unshared_amis['cert']) + len(unshared_amis['prod'])):
        return

    message = pymsteams.connectorcard(webhook_url, http_timeout=15)
    message.title("AMI Janitor")
    message.summary("Unshared AMIs")
    # create the section
    message.text("The following AMIs have been unshared from AWS accounts due to previously discovered vulnerabilities.")
    section = pymsteams.cardsection()

    if len(unshared_amis['dev']):
        section = pymsteams.cardsection()
        section.title("Unshared from Development Accounts following a {} day grace period.".format(os.getenv('dev_unshare_offset')))
        text = "<tr><th>AMI</th><th>Name</th></tr>"
        for ami in unshared_amis['dev']:
            text += "<tr><td nowrap>" + ami + "</td><td nowrap>" + ami_cache.get(ami,{}).get("Name") + "</td></tr>"
        section.text("<blockquote><table>" + text + "</table></blockquote>")

        # Add your section to the connector card object before sending
        message.addSection(section)

    if len(unshared_amis['cert']):
        section = pymsteams.cardsection()
        section.title("Unshared from Certification Accounts following a {} day grace period.".format(os.getenv('cert_unshare_offset')))
        text = "<tr><th>AMI</th><th>Name</th></tr>"
        for ami in unshared_amis['cert']:
            text += "<tr><td nowrap>" + ami + "</td><td nowrap>" + ami_cache.get(ami,{}).get("Name") + "</td></tr>"
        section.text("<blockquote><table>" + text + "</table></blockquote>")

        # Add your section to the connector card object before sending
        message.addSection(section)

    if len(unshared_amis['prod']):
        section = pymsteams.cardsection()
        section.title("Unshared from Production Accounts following a {} day grace period.".format(os.getenv('prod_unshare_offset')))
        text = "<tr><th>AMI</th><th>Name</th></tr>"
        for ami in unshared_amis['prod']:
            text += "<tr><td nowrap>" + ami + "</td><td nowrap>" + ami_cache.get(ami,{}).get("Name") + "</td></tr>"
        section.text("<blockquote><table>" + text + "</table></blockquote>")

        # Add your section to the connector card object before sending
        message.addSection(section)

    try:
        message.send()
    except:
        pass

def lambda_handler(event, context):
    session.set_session()

    notify_flagged_amis(apply_qualys_tags_to_amis())
    notify_unshared_amis(unshare_amis())

if __name__ == '__main__':
    os.environ["AWS_PROFILE"] = 'operations-bcs-prod'
    os.environ['qualys_report_url'] = 'https://redash2.lexisnexis.com/api/queries/225/results.json?api_key=yGinbATd8kpAQNFZFCilHz9Fwpw3XgRVaRAJaeeo'  # Add API Key for testing
    os.environ['MS_TEAMS_WEBHOOK'] = 'https://outlook.office.com/webhook/c21b6cf6-5b87-4c7a-b2a3-0aff295bd945@9274ee3f-9425-4109-a27f-9fb15c10675d/IncomingWebhook/7819963877604f74bd1d8a448b853743/0c9f8d64-d86e-4e12-bb84-4e08678a887a'
    os.environ['dev_unshare_offset'] = '0'
    os.environ['cert_unshare_offset'] = '0'
    os.environ['prod_unshare_offset'] = '28'
    os.environ['dev_account_list'] = ""
    os.environ['cert_account_list'] = ""
    os.environ['prod_account_list'] = ""
    os.environ['dryRun'] = "True"

    lambda_handler({}, {})
    # notify_webhook(os.getenv('MS_TEAMS_WEBHOOK'))
