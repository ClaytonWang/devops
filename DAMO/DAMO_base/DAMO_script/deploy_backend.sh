# bin/bash
echo '--------start build back end--------'

usedEnviron=$1
region=$2
projectName=$3
codeUri=$4
privateAPI=$5

cd backend

backendName=$projectName-backend-$usedEnviron

python3.7 -m pip install --user --upgrade aws-sam-cli

aws cloudformation deploy \
    --template-file ../DAMO_template/template_backend.yaml \
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

  aws s3 cp $BUILD_BUILDNUMBER.zip s3://$be_S3/$BUILD_BUILDNUMBER.zip
  sed -i "s#$codeUri#s3://$be_S3/$BUILD_BUILDNUMBER.zip#g" template.yaml
  cat template.yaml


  if $privateAPI
  then

    aws cloudformation deploy --template-file ../DAMO_template/template_vpce.yaml --stack-name damo-backend-vpce  \
        --parameter-overrides UsedEnviron=$usedEnviron \
        --no-fail-on-empty-changeset

    vpceStatus=$?

    if [ $vpceStatus != 0 ]
    then
      exit 1
    fi

    vpce=$(aws cloudformation describe-stacks \
            --stack-name damo-backend-vpce  --query "Stacks[0].Outputs[0].OutputValue" --output text)

    echo $vpce
    sam deploy --template-file template.yaml \
          --stack-name $projectName-backend-api-$usedEnviron \
          --capabilities  CAPABILITY_NAMED_IAM \
          --parameter-overrides UsedEnviron=$usedEnviron VPCE=$vpce \
          --no-fail-on-empty-changeset

  else
    sam deploy --template-file template.yaml \
      --stack-name $projectName-backend-api-$usedEnviron \
      --capabilities  CAPABILITY_NAMED_IAM \
      --parameter-overrides UsedEnviron=$usedEnviron \
      --no-fail-on-empty-changeset
  fi

  [ $? -eq 0 ] || exit 1
else
  exit 1
fi

cd ..
echo "finish deploying backend"

