#!/bin/bash

sudo apt update -y
sudo apt install nginx -y

sudo cat <<EOF >/etc/nginx/nginx.conf
load_module /usr/lib/nginx/modules/ngx_stream_module.so;

events {
    worker_connections 1024;
}

stream {
    upstream backend_server {
        zone   backend_server 64k;
        server 192.168.56.101:6443 fail_timeout=10s max_fails=3;  
        server 192.168.56.102:6443 fail_timeout=10s max_fails=3;
        server 192.168.56.103:6443 fail_timeout=10s max_fails=3;
    }

    server {
        listen 6443;
        proxy_pass backend_server;
    }
}
EOF

sudo cat /etc/nginx/nginx.conf
sudo service nginx restart
sudo service nginx status
