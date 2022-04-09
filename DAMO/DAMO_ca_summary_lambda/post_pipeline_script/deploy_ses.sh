# bin/bash
echo '--------start deploy  SES --------'
usedEnviron=$1

echo "usedEnviron is $usedEnviron"

#export AWS_DEFAULT_REGION=us-east-1
#
#
#aws cloudformation deploy \
#    --template-file ../template_ses.yaml \
#    --stack-name damo-ca-summary-ses-$usedEnviron --parameter-overrides UsedEnviron=$usedEnviron\
#    --no-fail-on-empty-changeset

status=$?
if [ $status == 0 ]
then
  echo '--------finish deploying ses --------'
else

  exit 1
fi

cd ..
