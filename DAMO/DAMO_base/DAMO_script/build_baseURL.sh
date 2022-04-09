# bin/bash
echo '--------start build base url--------'
usedEnviron=$1
region=$2
projectName=$3
frontend=$4
backend=$5
folder=$6
prefix=$7
privateAPI=$8

backendName=$projectName-backend-$usedEnviron
frontendName=$projectName-frontend-$usedEnviron

be_S3=$(aws cloudformation describe-stacks \
          --stack-name $backendName --query "Stacks[0].Outputs[0].OutputValue"  --output text)

fe_S3=$(aws cloudformation describe-stacks \
          --stack-name $frontendName --query "Stacks[0].Outputs[0].OutputValue"  --output text)

apiGateId=$(aws cloudformation describe-stacks \
        --stack-name $projectName-backend-api-$usedEnviron  --query "Stacks[0].Outputs[?OutputKey=='APIGateId'].OutputValue" --output text)



if $privateAPI
then

  vpce=$(aws cloudformation describe-stacks \
            --stack-name damo-backend-vpce  --query "Stacks[0].Outputs[0].OutputValue" --output text)

  baseUrl="https://$apiGateId-$vpce.execute-api.$region.amazonaws.com/$usedEnviron"

else
  baseUrl="https://$apiGateId.execute-api.$region.amazonaws.com/$usedEnviron"

fi

echo $baseUrl


if [ $backend == true ]; then

    echo "{\"baseUrl\": \"$baseUrl\"}" >> base-url.json
    cat base-url.json
    aws s3 sync . "$fe_S3/baseUrl" --exclude "*" --include="base-url.json"
    aws s3 sync . "$fe_S3$folder/$prefix" --exclude "*" --include="base-url.json"
fi

if [ $frontend == true ]; then
    aws s3 sync "$fe_S3/baseUrl" "$fe_S3$folder/$prefix" --exclude "*" --include="base-url.json"
fi

echo '--------finish building base url--------'


