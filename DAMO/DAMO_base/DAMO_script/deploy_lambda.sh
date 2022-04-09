# bin/bash
echo '--------start build lambda--------'

usedEnviron=$1
region=$2
projectName=$3
codeUri=$4

backendName=$projectName-backend-$usedEnviron

cd lambda

aws cloudformation deploy \
    --template-file ../DAMO_template/template_s3.yaml \
    --stack-name $backendName \
    --capabilities  CAPABILITY_IAM \
    --parameter-overrides S3BucketName=$backendName \
    --no-fail-on-empty-changeset

backendStatus=$?

if [ $backendStatus == 0 ]
then

  be_S3=$(aws cloudformation describe-stacks \
            --stack-name $backendName --query "Stacks[0].Outputs[0].OutputValue"  --output text)

  echo $region
  echo $be_S3

  python3.7 -m pip install aws-sam-cli

  pwd
  ls

  aws s3 cp $BUILD_BUILDNUMBER.zip s3://$be_S3/$BUILD_BUILDNUMBER.zip
  sed -i "s#$codeUri#s3://$be_S3/$BUILD_BUILDNUMBER.zip#g" template.yaml
  cat template.yaml
  sam deploy --template-file template.yaml \
            --stack-name $projectName-backend-api-$usedEnviron \
            --capabilities  CAPABILITY_NAMED_IAM \
            --parameter-overrides UsedEnviron=$usedEnviron \
            --no-fail-on-empty-changeset

  finalState=$?
  echo "backend state: $finalState"

else
  exit 1
fi

cd ..
echo "finish deploying lambda"

