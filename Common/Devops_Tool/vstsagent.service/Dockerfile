ARG DOCKER_IMAGE_VERSION=20210610.5
FROM 476985428237.dkr.ecr.ap-southeast-1.amazonaws.com/common_ubuntu_python:${DOCKER_IMAGE_VERSION}

RUN sudo apt-get update --fix-missing 
RUN sudo apt upgrade -y
RUN sudo apt-get install -y --no-install-recommends \
    mysql-client libmysqlclient-dev

WORKDIR /usr/bin
RUN sudo touch twistcli;
RUN sudo chmod 777 twistcli;
RUN curl --progress-bar -L -k --header "authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjoidGF5bG9yLndhbmdAbGV4aXNuZXhpcy5jb20iLCJyb2xlIjoiYWRtaW4iLCJncm91cHMiOm51bGwsInByb2plY3RzIjpudWxsLCJzZXNzaW9uVGltZW91dFNlYyI6ODY0MDAsImV4cCI6MTYyMzM5ODI3NSwiaXNzIjoidHdpc3Rsb2NrIn0.TAjPh12V4u3qEn0n1LNhudToYCya5qMzSNoZrJ5UjfY" https://twistlock.aicat.me/api/v1/util/twistcli > twistcli; 
RUN sudo chmod a+x twistcli;

# RUN export VER='1.5.4' \
# && sudo wget https://releases.hashicorp.com/packer/${VER}/packer_${VER}_linux_amd64.zip \
# && sudo unzip -o packer_${VER}_linux_amd64.zip \
# && sudo mv packer /usr/local/bin   

RUN sudo python3.7 -m pip install --no-cache-dir --upgrade pip setuptools wheel awscli twine pytest pytest-cov mock


# RUN az config set extension.use_dynamic_install=yes_without_prompt
# RUN az extension add --name azure-devops

WORKDIR /azp
COPY  ./run.sh .
RUN sudo chmod +x run.sh

RUN sudo chmod 777 /azp
RUN sudo apt-get update --fix-missing 
RUN sudo apt upgrade -y

RUN sudo apt-get install -y build-essential
# RUN sudo curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
# RUN sudo apt-get install -y nodejs

# RUN sudo npm install -g path-parse@1.0.7
RUN sudo groupadd docker
RUN sudo usermod -aG docker dockeru
RUN python3 -V
CMD ["./run.sh"]