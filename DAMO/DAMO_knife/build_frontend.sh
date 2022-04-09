# bin/bash
echo '--------start build front end--------'
folder="/current"
usedEnviron=$1

cd frontend

if [ $usedEnviron == dev ] || [ $usedEnviron == qa ]
then
  aws cloudformation deploy --template-file ../template_acm.yaml --stack-name damo-knife-acm-$usedEnviron --region us-east-1 \
    --parameter-overrides UsedEnviron=$usedEnviron \
    --no-fail-on-empty-changeset

  acmStatus=$?

  if [ $acmStatus == 0 ]
  then
    acm=$(aws cloudformation describe-stacks \
            --stack-name damo-knife-acm-$usedEnviron --query "Stacks[0].Outputs[0].OutputValue" --region us-east-1 --output text)
  else
    exit 1
  fi
else
  acm=$usedEnviron
fi

aws cloudformation deploy \
    --template-file ../template_frontend.yaml \
    --stack-name damo-knife-frontend-$usedEnviron --parameter-overrides DevACM=$acm OriginPathParameter=$folder UsedEnviron=$usedEnviron\
    --no-fail-on-empty-changeset

frontendStatus=$?
echo "frontendStatus: $frontendStatus"
if [ $frontendStatus == 0 ]
then

  fe_S3=$(aws cloudformation describe-stacks \
            --stack-name damo-knife-frontend-$usedEnviron --query "Stacks[0].Outputs[?OutputKey=='FrontendS3Bucket'].OutputValue" \
             --output text)

  tax_S3=$(aws cloudformation describe-stacks \
          --stack-name damo-knife-frontend-$usedEnviron --query "Stacks[0].Outputs[?OutputKey=='TaxonomyS3Bucket'].OutputValue" \
           --output text)



  aws s3 sync . "$fe_S3/${BUILD_BUILDNUMBER//./_}" --exclude "taxonomy.json*"
  aws s3 sync . "$fe_S3$folder" --exclude "taxonomy.json*"
  aws s3 sync . "$tax_S3" --exclude '*' --include "taxonomy.json"
else

  exit 1
fi


export fe_S3 folder
cd ..
