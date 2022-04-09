ARG DOCKER_IMAGE_VERSION=20210204.4
FROM 476985428237.dkr.ecr.ap-southeast-1.amazonaws.com/common_ubuntu_python:${DOCKER_IMAGE_VERSION}

COPY ./dist /usr/share/nginx/html
COPY ./cli/nginx.conf /etc/nginx/nginx.conf
RUN sudo chmod +r /usr/share/nginx/html
COPY ./cli/run.sh .
RUN sudo chmod +x run.sh

USER dockeru

EXPOSE 8080



CMD ["./run.sh"]