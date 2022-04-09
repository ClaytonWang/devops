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
from operator import itemgetter, attrgetter

#%%
ec2 = boto3.client('ec2')

#%%
response = ec2.describe_images(
    Filters=[
        {
            'Name': 'name',
            'Values': [
                'RCE-Ubuntu-18.04*',
            ]
        },
    ]
)
# %%
images=sorted(response['Images'],key=lambda x: x['CreationDate'],reverse=True)
print(images)

#%%
if len(images)>0:
    image=images[0]
    print(image['ImageId'],image['Name'])
# %%
