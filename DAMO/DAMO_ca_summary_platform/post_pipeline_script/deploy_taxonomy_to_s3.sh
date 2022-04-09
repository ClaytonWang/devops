# bin/bash
echo '--------start deploy taxonomy to s3 --------'
usedEnviron=$1

echo "usedEnviron is $usedEnviron"


aws cloudformation deploy \
    --template-file ../template_s3_taxonomy.yaml \
    --stack-name damo-ca-summary-platform-taxonomy-$usedEnviron --parameter-overrides UsedEnviron=$usedEnviron\
    --no-fail-on-empty-changeset

status=$?
if [ $status == 0 ]
then

  fe_S3=$(aws cloudformation describe-stacks \
            --stack-name damo-ca-summary-platform-frontend-$usedEnviron \
            --query "Stacks[0].Outputs[?OutputKey=='FrontendS3Bucket'].OutputValue" \
            --output text)

  tax_S3=$(aws cloudformation describe-stacks \
          --stack-name damo-ca-summary-platform-taxonomy-$usedEnviron \
          --query "Stacks[0].Outputs[?OutputKey=='TaxonomyS3Bucket'].OutputValue" \
          --output text)

  aws s3 mv "$fe_S3/current/ca" "$tax_S3" --exclude '*' --include "*taxonomy.json" --recursive
  aws s3 mv "$fe_S3/current/ca" "$tax_S3" --exclude '*' --include "*taxonomy.json.gz"  \
                                       --content-encoding "gzip"  --metadata-directive REPLACE --recursive

else

  exit 1
fi

echo '--------finish deploying taxonomy to s3 --------'
cd ..
