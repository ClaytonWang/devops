# bin/bash
echo '--------start build back end--------'
cd backend
usedEnviron=$1
region=$2

aws cloudformation deploy --template-file ../template_vpce.yaml --stack-name damo-backend-vpce  \
    --parameter-overrides UsedEnviron=$usedEnviron \
    --no-fail-on-empty-changeset
vpceStatus=$?

if [ $vpceStatus != 0 ]
then
  exit 1
fi

vpce=$(aws cloudformation describe-stacks \
          --stack-name damo-backend-vpce  --query "Stacks[0].Outputs[0].OutputValue" --output text)

aws cloudformation deploy \
    --template-file ../template_backend.yaml \
    --stack-name damo-knife-backend-$usedEnviron \
    --capabilities  CAPABILITY_IAM \
    --parameter-overrides UsedEnviron=$usedEnviron \
    --no-fail-on-empty-changeset

backendStatus=$?

if [ $backendStatus == 0 ]
then

  be_S3=$(aws cloudformation describe-stacks \
            --stack-name damo-knife-backend-$usedEnviron --query "Stacks[0].Outputs[0].OutputValue"  --output text)

  fe_S3=$(aws cloudformation describe-stacks \
            --stack-name damo-knife-frontend-$usedEnviron --query "Stacks[0].Outputs[?OutputKey=='FrontendS3Bucket'].OutputValue" \
              --output text)


  echo $region
  echo $be_S3

  python3 -m pip install aws-sam-cli

  aws s3 cp $BUILD_BUILDNUMBER.zip s3://$be_S3/$BUILD_BUILDNUMBER.zip
  sed -i "s#source/lambdas#s3://$be_S3/$BUILD_BUILDNUMBER.zip#g" template.yaml
  cat template.yaml
  sam deploy --template-file template.yaml \
            --stack-name damo-knife-backend-api-$usedEnviron \
            --capabilities  CAPABILITY_NAMED_IAM \
            --parameter-overrides UsedEnviron=$usedEnviron VPCE=$vpce \
#            ACM=$acm

  apiGateId=$(aws cloudformation describe-stacks \
          --stack-name damo-knife-backend-api-$usedEnviron \
          --query "Stacks[0].Outputs[?OutputKey=='APIGateId'].OutputValue" \
          --output text)



  finalState=$?
  baseUrl="https://$apiGateId-$vpce.execute-api.$region.amazonaws.com/$usedEnviron"
  echo "backend state: $finalState"
  echo $apiGateId
  echo $vpce
  echo $baseUrl

else
  exit 1
fi


export baseUrl fe_S3 folder="/current"
cd ..

