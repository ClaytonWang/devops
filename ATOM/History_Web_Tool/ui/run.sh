#!/bin/bash
sed -i "s#{APIURL}#$APIURL#g" /etc/nginx/nginx.conf
sed -i "s#{MNCRURL}#$MNCRURL#g" /etc/nginx/nginx.conf
nginx -g 'daemon off;'