#!/bin/bash


apt update -y
apt install nginx -y
cat <<EOF >/etc/nginx/nginx.conf
load_module /usr/lib/nginx/modules/ngx_stream_module.so;
events {
    worker_connections 1024;
}
stream {
    upstream backend_server {
        zone   backend_server 64k;
        server master1:6443;
        server master2:6443;
        server master3:6443;
    }
    server {
        listen 6443;
        proxy_pass backend_server;
    }
}
EOF
cat /etc/nginx/nginx.conf
service nginx restart
service nginx status
systemctl stop ufw
systemctl disable ufw