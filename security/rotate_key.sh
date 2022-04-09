# env="dev"
# export AZURE_DEVOPS_EXT_PAT=$(AZURE_DEVOPS_EXT_PAT)
# if [ $env = "cert" ] || [ $env = "prod" ] ; then
#     export AWS_DEFAULT_REGION=us-east-1
#     export AWS_ACCESS_KEY_ID=$(prod.AWS_ACCESS_KEY_ID)
#     export AWS_SECRET_ACCESS_KEY=$(prod.AWS_SECRET_ACCESS_KEY) 
# else
#     export AWS_DEFAULT_REGION=ap-southeast-1
#     export AWS_ACCESS_KEY_ID=$(dev.AWS_ACCESS_KEY_ID)
#     export AWS_SECRET_ACCESS_KEY=$(dev.AWS_SECRET_ACCESS_KEY)
# fi
# cd $(System.DefaultWorkingDirectory)/_devops/security
# . rotate_key.sh
# __main__
VARIABLE_GROUP='aicat-common-variables'
VARIABLE_GROUP_id=21
get_new_secret_key(){
        data=$(aws iam create-access-key --user-name 'cicd-user')       
        temp=${data#*"AccessKeyId\": \""}
        AccessKeyId=${temp%%\"*}
        temp=${data#*"SecretAccessKey\": \""}
        SecretAccessKey=${temp%%\"*}
        echo "Get new secret key success! AccessKeyId:$AccessKeyId"
}
delete_old_security_key(){    
    aws iam delete-access-key --user-name 'cicd-user' --access-key-id $AWS_ACCESS_KEY_ID
}
install_az() {
    #https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt
    
    # apt-get update
    # apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg
    # #signing key
    # curl -sL https://packages.microsoft.com/keys/microsoft.asc | \
    # gpg --dearmor | \
    # tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
    #add repo
    # AZ_REPO=$(lsb_release -cs)
    # echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
    # tee /etc/apt/sources.list.d/azure-cli.list
    # #install az
    # apt-get update
    # apt-get install -y azure-cli
    python3 -m pip install azure-cli
    az config set extension.use_dynamic_install=yes_without_prompt
    az extension add --name azure-devops
    echo "install az success!"
}
install_awscli(){
    apt-get update 
    apt-get install -y python3-distutils python3-pip
    python3 -m pip install --upgrade pip
    python3 -m pip install --upgrade awscli  
    echo "install aws cli success!"
}
login_az() {
    AZ_ORGANIZATION='tfs-glo-apac'
    AZ_PROJECT='APAC-AI'
	# echo $AZURE_DEVOPS_EXT_PAT
	az devops configure --defaults organization=https://dev.azure.com/$AZ_ORGANIZATION/ project=$AZ_PROJECT
    echo 'login sucess!'
}
update_new_security_key_to_azure_libs() {  
    if [ $AccessKeyId ] && [ $SecretAccessKey ];then
        az pipelines variable-group variable update --id $VARIABLE_GROUP_id --name "$env.AWS_ACCESS_KEY_ID" --value $AccessKeyId
        az pipelines variable-group variable update --id $VARIABLE_GROUP_id --name "$env.AWS_SECRET_ACCESS_KEY" --value $SecretAccessKey
        echo "update success!"
    fi
}

__main__(){
    # install_az
    # install_awscli
    login_az
    get_new_secret_key
    update_new_security_key_to_azure_libs
    # delete_old_security_key
}

# if [ __main__ ]; then 
#     __main__
# fi