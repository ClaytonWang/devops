env=${env:-dev}
frontendFolder=${frontendFolder:-'/current'}
prefix=${prefix:-''}
privateAPI=${privateAPI:-true}

while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
        # echo $1 $2 // Optional to see the parameter:value result
   fi

   shift
done


if [[ -z "${website}" ]] || [[ -z "${devopsFolder}" ]] || [[ -z "${codeUri}" ]] ; then
  echo "Need to pass all the  variables: website, devopsFolder, codeUri"
  exit 1
fi

if [[ -z "${region}" ]] || [[ -z "${awsId}" ]] || [[ -z "${awsKey}" ]] ; then
  echo "Need to pass all the aws variables: region, awsId, awsKey"
  exit 1
fi

if [ $env == cert ] || [ $env == prod ]; then
  if  [[ -z "${acm}" ]] ; then
  echo "Need to pass acm for cert and prod environment"
  exit 1
  fi
fi


export AWS_ACCESS_KEY_ID=${awsId}
export AWS_SECRET_ACCESS_KEY=${awsKey}
export AWS_DEFAULT_REGION=${region}


frontend=false
backend=false
projectName=$RELEASE_DEFINITIONNAME
artifactFolder=_$projectName


cp -rf _devops/DAMO/$devopsFolder/*  $artifactFolder/Artifact
cp -rf _devops/DAMO/DAMO_base/*  $artifactFolder/Artifact


if [ $? == 0  ]; then
    cd $artifactFolder/Artifact

    chmod +x ./DAMO_script/setup_role.sh
    . ./DAMO_script/setup_role.sh $env $projectName

     if [ -d "pre_pipeline_script" ]; then

      cd pre_pipeline_script

      for f in *.sh; do
        chmod +x "$f"
        source "$f" $env
        echo "functionArn is $functionArn"
      done

      cd ..
    fi
    if [ $? != 0  ]
    then
      exit 1
    fi

    #check if deploy frontend
    if [ -d "frontend" ]; then
      frontend=true
      chmod +x ./DAMO_script/deploy_frontend.sh
      echo "prefix is $prefix"
      echo "acm is $acm"
      . ./DAMO_script/deploy_frontend.sh $env $region $projectName $website $frontendFolder "$acm" "$prefix" "$functionArn"
    fi

    if [ $? != 0  ]
    then
      exit 1
    fi
    ls
    #check if deploy backend
    if [ -d "backend" ]; then
      backend=true
      chmod +x ./DAMO_script/deploy_backend.sh
      . ./DAMO_script/deploy_backend.sh $env $region $projectName $codeUri $privateAPI

    fi
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
    if [ $? != 0  ]
    then
      exit 1
    fi

    chmod +x ./DAMO_script/build_baseURL.sh
    . ./DAMO_script/build_baseURL.sh $env $region $projectName $frontend $backend $frontendFolder "$prefix" $privateAPI

else
  exit 1
fi

