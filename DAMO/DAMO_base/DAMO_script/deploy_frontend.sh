# bin/bash
echo '--------start build front end--------'
usedEnviron=$1
region=$2
projectName=$3
webSite=$4
folder=$5
acm=$6
prefix=$7
functionArn=$8

cd frontend

if [ $usedEnviron == dev ] || [ $usedEnviron == qa ]
then
  aws cloudformation deploy --template-file ../DAMO_template/template_acm.yaml --stack-name $projectName-acm-$usedEnviron \
    --region us-east-1 \
    --parameter-overrides UsedEnviron=$usedEnviron \
    --no-fail-on-empty-changeset

  acmStatus=$?

  if [ $acmStatus == 0 ]
  then
    acm=$(aws cloudformation describe-stacks \
            --stack-name $projectName-acm-$usedEnviron --query "Stacks[0].Outputs[0].OutputValue" \
            --region us-east-1 --output text)
  else
    exit 1
  fi
fi

echo "webSite is $webSite"

echo "acm is $acm"

echo "prefix is $prefix"

echo "functionArn is $functionArn"


aws cloudformation deploy \
    --template-file ../DAMO_template/template_frontend.yaml \
    --stack-name $projectName-frontend-$usedEnviron \
    --parameter-overrides ACM=$acm OriginPathParameter="$folder" \
    UsedEnviron=$usedEnviron WebSite=$webSite ProjectName=$projectName \
    Prefix=$prefix CloudfrontFunctionArn=$functionArn\
    --no-fail-on-empty-changeset

frontendStatus=$?
echo "frontendStatus: $frontendStatus"
if [ $frontendStatus == 0 ]
then

  fe_S3=$(aws cloudformation describe-stacks \
            --stack-name $projectName-frontend-$usedEnviron --query "Stacks[0].Outputs[0].OutputValue"  --output text)


  aws s3 sync . "$fe_S3/${BUILD_BUILDNUMBER//./_}" --delete
  aws s3 sync . "$fe_S3$folder/$prefix" --delete
else

  exit 1
fi



export fe_S3 folder
cd ..

echo "finish deploying frontend"
