# celery monitor

docker build -t history_monitor:20200311.1 -f ./ci/monitor.Dockerfile .


docker run -it -e env=dev -e broker='redis://atom-qa.nvfhva.0001.apse1.cache.amazonaws.com:6379/1' history_monitor:20200311.1 bash

docker tag history_monitor:20200311.1  476985428237.dkr.ecr.ap-southeast-1.amazonaws.com/history_monitor:20200311.1
$(aws ecr get-login --no-include-email --region ap-southeast-1)
docker push 476985428237.dkr.ecr.ap-southeast-1.amazonaws.com/history_monitor:20200311.1

https://docs.aws.amazon.com/zh_cn/AWSCloudFormation/latest/UserGuide/GettingStarted.Walkthrough.html




--Design and maintain ci/cd pipelines and infrastructure, 100% satisfy the  reasonable   needs of  project.
100% satisfy the  reasonable  needs of  project.
