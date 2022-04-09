env=${env:-dev}

while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
        # echo $1 $2 // Optional to see the parameter:value result
   fi

   shift
done


if  [[ -z "${devopsFolder}" ]] || [[ -z "${codeUri}" ]] ; then
  echo "Need to pass all the  variables:  devopsFolder, codeUri"
  exit 1
fi

if [[ -z "${region}" ]] || [[ -z "${awsId}" ]] || [[ -z "${awsKey}" ]] ; then
  echo "Need to pass all the aws variables: region, awsId, awsKey"
  exit 1
fi


export AWS_ACCESS_KEY_ID=${awsId}
export AWS_SECRET_ACCESS_KEY=${awsKey}
export AWS_DEFAULT_REGION=${region}


projectName=$RELEASE_DEFINITIONNAME
artifactFolder=_$projectName


cp -rf _devops/DAMO/$devopsFolder/*  $artifactFolder/Artifact
cp -rf _devops/DAMO/DAMO_base/*  $artifactFolder/Artifact


if [ $? == 0  ]; then
    cd $artifactFolder/Artifact

    chmod +x ./DAMO_script/setup_role.sh
    . ./DAMO_script/setup_role.sh $env $projectName


    chmod +x ./DAMO_script/deploy_lambda.sh
    . ./DAMO_script/deploy_lambda.sh $env $region $projectName $codeUri

    if [ $? != 0  ]
    then
      exit 1
    fi

    if [ -d "post_pipeline_script" ]; then

      cd post_pipeline_script

      for f in *.sh; do
        bash "$f" $env
      done

      cd ..
    fi

else
  exit 1
fi

