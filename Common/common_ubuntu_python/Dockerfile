FROM ubuntu:18.04

# To make it easier for build and release pipelines to run apt-get,
# configure apt to not require confirmation (assume the -y argument by default)
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

RUN apt-get update \
&& apt-get install -y --no-install-recommends \
        #支持请求easy-to-use client-side URL transfer library (OpenSSL flavour)                
        libcurl4 curl wget \
        #支持https请求
        ca-certificates \
        #自符串处理
        jq \
        git \
        #支持ping,tracepath,arping,tftpd,rarpd,clockdiff,rdisc
        iputils-ping \
        #library to determine the call-chain of a program - runtime
        libunwind8 \
        #TCP/IP swiss army knife -- transitional package
        netcat \
        # java 
        default-jre \
        #GNU C compiler
        gcc \
        #package management related utility programs
        apt-utils \
        #tool for creating machine images for multiple platforms
        packer \
        awscli \
        # mysql-client
        mysql-client \
        libmysqlclient-dev

# timezone environment
ENV TZ Asia/Shanghai

# language environment
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

#python3.7        
# manage the repositories that you install software from (common) \    
RUN apt-get install -y --no-install-recommends software-properties-common \    
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        python3.7-dev \
        python3-pip

RUN apt-get install -y --no-install-recommends \
    sudo \
    && groupadd -r dockerg \
    && adduser dockeru --disabled-password \
    && usermod -aG dockerg dockeru \
    && echo dockeru ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/dockeru \
    && chmod 0440 /etc/sudoers.d/dockeru

RUN chown -R dockeru:dockerg /home/dockeru
RUN chown dockeru:dockerg /home/dockeru

# RUN curl -sL https://deb.nodesource.com/setup_lts.x | sudo bash -
# RUN apt-get install -y nodejs

RUN add-apt-repository -y ppa:nginx/stable && \
    apt-get update  &&\
    apt-get install -y nginx && \
    rm -rf /var/lib/apt/lists/* 

#requirements
WORKDIR /home/dockeru

RUN mkdir -p /var/cache/nginx
RUN mkdir -p /var/run
RUN mkdir -p /var/log/nginx
RUN chgrp -R dockerg /var/cache/nginx /var/run /var/log/nginx && \
    chmod -R 770 /var/cache/nginx /var/run /var/log/nginx /etc/nginx

RUN chown -R dockeru:dockerg /var/lib/nginx 
RUN chown dockeru:dockerg /var/run
RUN chown dockeru:dockerg /etc/nginx
RUN chown -R dockeru:dockerg /etc/nginx

RUN apt update --fix-missing
RUN apt-get install unzip
RUN wget https://download.oracle.com/otn_software/linux/instantclient/193000/instantclient-basic-linux.x64-19.3.0.0.0dbru.zip
RUN unzip  instantclient-basic-linux.x64-19.3.0.0.0dbru.zip
ENV LD_LIBRARY_PATH=/home/dockeru/instantclient_19_3

RUN apt update --fix-missing
RUN apt upgrade -y

RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/.cache/*

USER dockeru
ENV PATH="/home/dockeru/.local/bin:$PATH"
RUN /usr/bin/python3.7 -m pip install --upgrade pip \
    && /usr/bin/python3.7 -m pip install --upgrade setuptools wheel
RUN /usr/bin/python3.7 -m pip install spacy==2.1.6
RUN /usr/bin/python3.7 -m spacy download en_core_web_lg
COPY ./ ./
RUN /usr/bin/python3.7 -m pip install --ignore-installed -r requirements.txt
RUN /usr/bin/python3.7 -m pip install --ignore-installed -r requirements.etl-core.txt
RUN rm -rf  /home/dockeru/.local/lib/python3.7/site-packages/future/backports/test/*

#####更新补丁2021.02.04
#####更新补丁2021.05.13
RUN sudo apt update --fix-missing
RUN sudo apt upgrade -y

RUN sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/.cache/*