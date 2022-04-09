env=dev
us_ca=us

desiredCount=3
cd $(System.DefaultWorkingDirectory)/_devops/DAMO/DAMO-RestAPI
cp -f $(System.DefaultWorkingDirectory)/_devops/core/awscli_cloudformation.sh ./cloudformation.sh  
templatefile="file://./webservice.yaml"

if [ $us_ca = "us" ]; then
    stackname=damo-restapi-$env
    projectName="RestAPI-API"
else
    stackname=damo-carestapi-$env
    projectName="CARestAPI-API"
fi
parameter_filename="parameter"

buildnumber=$(RELEASE.ARTIFACTS._main.BUILDNUMBER)
ecr="damo_rest_api:$buildnumber"


if [ $env = "cert" ] || [ $env = "prod" ] ; then
    export AWS_DEFAULT_REGION=us-east-1
    export AWS_ACCESS_KEY_ID=$(prod.AWS_ACCESS_KEY_ID)
    export AWS_SECRET_ACCESS_KEY=$(prod.AWS_SECRET_ACCESS_KEY)    
    imageid="206710830665.dkr.ecr.us-east-1.amazonaws.com/$ecr"
else
    export AWS_DEFAULT_REGION=ap-southeast-1
    export AWS_ACCESS_KEY_ID=$(dev.AWS_ACCESS_KEY_ID)
    export AWS_SECRET_ACCESS_KEY=$(dev.AWS_SECRET_ACCESS_KEY)
    imageid="476985428237.dkr.ecr.ap-southeast-1.amazonaws.com/$ecr"
fi
region=$AWS_DEFAULT_REGION
command=s@\$cmd@$cmd@
sed -e "s#\$env#"$env"#" < ./$parameter_filename.json |\
sed -e "$command" |\
sed -e "s#\$projectName#"$projectName"#" |\
sed -e "s#\$desiredCount#"$desiredCount"#" |\
sed -e "s#\$imageid#"$imageid"#" > ./$parameter_filename.$env.json
cat ./$parameter_filename.$env.json
parameterfile="file://$parameter_filename.$env.json"
chmod +x ./cloudformation.sh
./cloudformation.sh $region $stackname $templatefile $parameterfile