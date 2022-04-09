#!/bin/bash

echo '--------start setup role--------'

usedEnviron=$1
projectName=$2
echo "aws id is ${AWS_ACCESS_KEY_ID}"
echo "aws key is ${AWS_SECRET_ACCESS_KEY}"

userArn=$(aws sts get-caller-identity --output text --query 'Arn')

echo "user arn is ${userArn}"

aws cloudformation deploy --template-file template_role.yaml --stack-name $projectName-role-$usedEnviron  \
  --parameter-overrides UsedEnviron=$usedEnviron UserArn=$userArn\
  --capabilities  CAPABILITY_NAMED_IAM \
  --no-fail-on-empty-changeset

roleStatus=$?

if [ $roleStatus == 0 ]
then

  roleArn=$(aws cloudformation describe-stacks \
            --stack-name $projectName-role-$usedEnviron  --query "Stacks[0].Outputs[0].OutputValue" --output text)

  echo $roleArn
  aws sts assume-role --role-arn $roleArn --role-session-name $projectName --output=json > aws_cred.json

  cat aws_cred.json

  export AWS_ACCESS_KEY_ID=`cat aws_cred.json | jq .Credentials.AccessKeyId | tr -d '"'`;
  export AWS_SECRET_ACCESS_KEY=`cat aws_cred.json | jq .Credentials.SecretAccessKey | tr -d '"'`;
  export AWS_SESSION_TOKEN=`cat aws_cred.json | jq .Credentials.SessionToken | tr -d '"'`;

else

  exit 1

fi

echo '--------finish setup role--------'

