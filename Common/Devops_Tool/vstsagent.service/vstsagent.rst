start
########

docker build -f vstsagent.Dockerfile -t vstsagent:latest .

AZP_URL	The URL of the Azure DevOps or Azure DevOps Server instance
AZP_TOKEN	Personal Access Token (PAT) granting access to AZP_URL
AZP_AGENT_NAME	Agent name (default value: the container hostname)
AZP_POOL	Agent pool name (default value: Default)
AZP_WORK	Work directory (default value: _work)

docker run -e AZP_URL=https://tfs-glo-apac.visualstudio.com/ -e AZP_TOKEN=7whop2c3mwo3kk2vzpegfu4vdp3yqd663tgwzeogamfnn7faggga -e AZP_POOL=dev-cluster vstsagent:latest

docker tag vstsagent:latest  476985428237.dkr.ecr.ap-southeast-1.amazonaws.com/vstsagent:latest
$(aws ecr get-login --no-include-email --region ap-southeast-1)
docker push 476985428237.dkr.ecr.ap-southeast-1.amazonaws.com/vstsagent:latest

https://docs.aws.amazon.com/zh_cn/AWSCloudFormation/latest/UserGuide/GettingStarted.Walkthrough.html

