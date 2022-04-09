#!/bin/sh
#set -e
region=$1
stackname=$2
templatefile=$3
parameterfile=$4

if [ "$(aws cloudformation describe-stacks --region $region --query 'Stacks[?StackName==`'$stackname'`].StackName' --output text)" = $stackname ]; then
    type1=UPDATE
    waittype1=stack-update-complete
    echo "will update stack..."
else
    type1=CREATE
    waittype1=stack-create-complete
    echo "will create stack..."
fi
echo "deleting old Changeset..."
aws cloudformation delete-change-set --region $region --stack-name $stackname --change-set-name $stackname

echo "Creating Changeset..."
aws cloudformation create-change-set \
--change-set-type $type1 \
--stack-name $stackname \
--change-set-name $stackname \
--template-body  $templatefile \
--parameters $parameterfile \
--capabilities CAPABILITY_IAM
 

echo "querying Changeset..."
status1=$(aws cloudformation describe-change-set --region $region --stack-name $stackname --change-set-name $stackname --query "Status" --output text)
reason1=$(aws cloudformation describe-change-set --region $region --stack-name $stackname --change-set-name $stackname --query "StatusReason" --output text)
echo "$stackname ChangeSet STATUS: $status1, REASON: $reason1"

echo " waiting ChangeSet complete...."
aws cloudformation wait change-set-create-complete --region $region --stack-name $stackname --change-set-name $stackname
status1=$(aws cloudformation describe-change-set --region $region --stack-name $stackname --change-set-name $stackname --query "Status" --output text)
reason1=$(aws cloudformation describe-change-set --region $region --stack-name $stackname --change-set-name $stackname --query "StatusReason" --output text)
echo "$stackname ChangeSet STATUS: $status1, REASON: $reason1"

if [ $status1 = "CREATE_COMPLETE" ]; then
    echo "Executing Changeset..."
    aws cloudformation execute-change-set --region $region --stack-name $stackname --change-set-name $stackname
    echo "Waiting Changeset..."
    aws cloudformation wait $waittype1  --region $region --stack-name $stackname
    echo "Descirbe Changeset..."
    aws cloudformation describe-stacks  --region $region --stack-name $stackname --output table 
    echo "$stackname ChangeSet STACK COMPLETE."
fi
