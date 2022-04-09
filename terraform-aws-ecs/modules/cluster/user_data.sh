#!/bin/bash -xe

mkdir -p /etc/ecs
touch /etc/ecs/ecs.config
cat <<'EOF' >>/etc/ecs/ecs.config
ECS_CLUSTER=$${ECSCluster}
ECS_INSTANCE_ATTRIBUTES={"purpose": "infra"}
EOF
sudo yum install -y amazon-linux-extras
amazon-linux-extras disable docker
amazon-linux-extras install -y ecs
systemctl enable --now --no-block ecs         
yum install -y awslogs
sudo systemctl start awslogsd
# chkconfig awslogs.service on          
cat <<'EOF' >>/etc/awslogs/awslogs.conf
[/var/log/secure]
datetime_format = %b %d %H:%M:%S
file = /var/log/secure
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = /var/log/secure
[/var/ossec/logs/alerts/alerts.json]
file = /var/ossec/logs/alerts/alerts.json
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
mode: "000644"
owner: "root"
group: "root"
log_group_name = /var/ossec/logs/alerts/alerts.json
[/var/log/cloud-init-output.log]
datetime_format = %b %d %H:%M:%S
file = /var/log/cloud-init-output.log
buffer_duration = 5000
log_stream_name = {instance_id}
initial_position = start_of_file
log_group_name = /var/log/cloud-init-output.log
EOF
sed -i 's/us-east-1/$${AWS::Region}/g' /etc/awslogs/awscli.conf
sudo systemctl restart awslogsd
sudo systemctl start amazon-ssm-agent
sudo systemctl enable awslogsd.service