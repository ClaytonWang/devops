#!/usr/bin/env bash

# install packages
yum install gcc zlib-devel zip jq awslogs openssl-devel -y

yum install bzip2-devel libffi-devel libsqlite3-dev sqlite-devel -y

#yum install python3 python3-devel -y

cd /usr/src
wget https://www.python.org/ftp/python/3.7.5/Python-3.7.5.tgz
tar xzf Python-3.7.5.tgz

cd Python-3.7.5
./configure --enable-optimizations
make altinstall

rm -f /usr/src/Python-3.7.5.tgz

# verification
/usr/local/bin/python3.7 -V
/usr/local/bin/pip3.7 --version

yes | cp /usr/local/bin/python3.7 /usr/bin/python3
yes | cp /usr/local/bin/pip3.7 /usr/bin/pip3

pip install awscli

# create project folder
mkdir -p /usr/local/damo_rest_api
tar -xzvf /tmp/damo_rest_api.tar -C /usr/local/

ls -al /usr/local/
ls -al /usr/local/damo_rest_api

chown -R root:root /usr/local/damo_rest_api
cd /usr/local/damo_rest_api
/usr/local/bin/pip3.7 install -r requirements.txt

# TBD
# pip3 install werkzeug==0.16.0
# pip3 install torch===1.4.0 torchvision===0.5.0 -f https://download.pytorch.org/whl/torch_stable.html

# werkzeug hack for rest-plus
# pip3 uninstall werkzeug -y
# pip3 install werkzeug==0.16.0

# pip3 install --index-url https://azure-feed:snym54gqoxdanlritavsqpngharg573rzb6k3gs7k433xmezngza@tfs-glo-apac.pkgs.visualstudio.com/_packaging/azure-feed/pypi/simple/ etl-core==3.0.5
# pip3 install alembic

# pip3 install uWSGI
/usr/local/bin/pip3.7 show werkzeug torch etl-core

# move awslogs agent conf file
rm -f /etc/awslogs/awscli.conf
mv /tmp/awscli.conf /etc/awslogs/awscli.conf

rm -f /etc/awslogs/awslogs.conf
mv /tmp/awslogs.conf /etc/awslogs/awslogs.conf


#################################
# install security requirements #
#################################

# Install and configure ossec
aws s3 --region ap-southeast-1 cp s3://damo-ai-data/app/ossec-wazuh-local-binary-installation.tar.gz /tmp/ossec-wazuh-local-binary-installation.tar.gz
tar -xzvf /tmp/ossec-wazuh-local-binary-installation.tar.gz -C /tmp/
/tmp/ossec-wazuh/install.sh 
/bin/cp -f /tmp/ossec-wazuh/ossec.conf /var/ossec/etc/ossec.conf
rm -rf /tmp/ossec-wazuh*

# Install SNOW Client 
aws s3 --region ap-southeast-1 cp s3://damo-ai-data/app/xClientSIOS-1.9.02-1-external.x86_64.rpm /tmp/xClientSIOS-1.9.02-1-external.x86_64.rpm
rpm -ivh /tmp/xClientSIOS-1.9.02-1-external.x86_64.rpm
rm -rf /tmp/xClientSIOS-1.9.02-1-external.x86_64.rpm

# Install and activate the Qualys Vulnerability Agent
aws s3 --region ap-southeast-1 cp s3://damo-ai-data/app/qualys-cloud-agent.rpm /opt/qualys/qualys-cloud-agent.rpm
rpm -ivh /opt/qualys/qualys-cloud-agent.rpm
/usr/local/qualys/cloud-agent/bin/qualys-cloud-agent.sh CustomerId=564896bd-efd2-6cde-8182-82e5936636d1 ActivationId=a0734882-b79c-4620-a3bd-85e49ba6a5a7

yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm