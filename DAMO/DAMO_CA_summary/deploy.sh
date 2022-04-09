env=dev
cd $(System.DefaultWorkingDirectory)/_damo_ca_summary_lambda
sam build -t damo_ca_summary_lambda.yaml
buildnumber=$(RELEASE.ARTIFACTS._damo_ca_summary_lambda.BUILDNUMBER)
if [ $env = "cert" ] || [ $env = "prod" ] ; then
    export AWS_DEFAULT_REGION=us-east-1
    export AWS_ACCESS_KEY_ID=$(prod.AWS_ACCESS_KEY_ID)
    export AWS_SECRET_ACCESS_KEY=$(prod.AWS_SECRET_ACCESS_KEY)  
else
    export AWS_DEFAULT_REGION=ap-southeast-1
    export AWS_ACCESS_KEY_ID=$(dev.AWS_ACCESS_KEY_ID)
    export AWS_SECRET_ACCESS_KEY=$(dev.AWS_SECRET_ACCESS_KEY)
fi
 sam package --s3-bucket damo-ca-summary-cf-template-$env -t .aws-sam/build/template.yaml --output-template-file packaged-$env.yaml

sam deploy --template-file ./packaged-$env.yaml --stack-name damo-ca-summary-lambda-$env --parameter-overrides UsedEnviron=$env --capabilities CAPABILITY_IAM