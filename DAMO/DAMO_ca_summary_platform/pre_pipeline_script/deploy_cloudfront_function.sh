# bin/bash
echo '--------start deploy cloudfront function --------'
usedEnviron=$1

echo "usedEnviron is $usedEnviron"

#python3 -m pip install --upgrade --user awscli
#
#aws --version

#aws cloudfront create-function \
#    --name cloudfront-function-routing-$usedEnviron \
#    --function-config Comment="Cloudfront function for routing",Runtime="cloudfront-js-1.0" \
#    --function-code fileb://cloudfront_routing.js

aws cloudformation deploy \
    --template-file ../template_cloudfront_function.yaml \
    --stack-name damo-ca-summary-platform-routing-$usedEnviron --parameter-overrides UsedEnviron=$usedEnviron\
    --no-fail-on-empty-changeset

status=$?
if [ $status == 0 ]
then

  functionArn=$(aws cloudformation describe-stacks \
            --stack-name damo-ca-summary-platform-routing-$usedEnviron \
            --query "Stacks[0].Outputs[?OutputKey=='FunctionArn'].OutputValue" \
            --output text)

  echo "functionArn is $functionArn"

else

  exit 1
fi

echo '--------finish deploying cloudfront function --------'
#cd ..
