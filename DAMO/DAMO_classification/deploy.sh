
env=dev
cd $(System.DefaultWorkingDirectory)/_damo_classification/damo-classification.yaml
buildnumber=$(RELEASE.ARTIFACTS._damo_classification.BUILDNUMBER)
if [ $env = "cert" ] || [ $env = "prod" ] ; then
    export AWS_DEFAULT_REGION=us-east-1
    export AWS_ACCESS_KEY_ID=$(prod.AWS_ACCESS_KEY_ID)
    export AWS_SECRET_ACCESS_KEY=$(prod.AWS_SECRET_ACCESS_KEY)  
else
    export AWS_DEFAULT_REGION=ap-southeast-1
    export AWS_ACCESS_KEY_ID=$(dev.AWS_ACCESS_KEY_ID)
    export AWS_SECRET_ACCESS_KEY=$(dev.AWS_SECRET_ACCESS_KEY)
fi
sed -i "s#src/#s3://damo-lambdas/damo_classification.$buildnumber.zip#g" damo-classification.yaml 
cat damo-classification.yaml 
sam deploy --template-file ./damo-classification.yaml --stack-name damo-classification-lambda-$env --parameter-overrides UsedEnviron=$env --capabilities CAPABILITY_IAM