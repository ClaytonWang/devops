env=dev
cd $(System.DefaultWorkingDirectory)/_devops/
if [ $env = "cert" ] || [ $env = "prod" ] ; then
    export AWS_DEFAULT_REGION=us-east-1
    export AWS_ACCESS_KEY_ID=$(prod.AWS_ACCESS_KEY_ID)
    export AWS_SECRET_ACCESS_KEY=$(prod.AWS_SECRET_ACCESS_KEY)
    HardenAMI=$(prod.RCEAMI)
else
    export AWS_DEFAULT_REGION=ap-southeast-1
    export AWS_ACCESS_KEY_ID=$(dev.AWS_ACCESS_KEY_ID)
    export AWS_SECRET_ACCESS_KEY=$(dev.AWS_SECRET_ACCESS_KEY)
    HardenAMI=$(dev.RCEAMI)
    stackname=DAMO-Cluster
fi
region=$AWS_DEFAULT_REGION
templatefile="file://damo.cluster.yaml"
sed -e "s/\$env/"$env"/" < ./DAMO/parameter.json |\
sed -e "s/\$HardenAMI/"$HardenAMI"/" > ./DAMO/parameter.$env.json
cat ./DAMO/parameter.$env.json
parameterfile="file://./DAMO/parameter.json
chmod +x ./core/cloudformation.sh
./core/cloudformation.sh $region $stackname $templatefile $parameterfile