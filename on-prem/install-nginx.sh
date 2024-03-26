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
        server kubernetes-master1:6443;
        server kubernetes-master2:6443;
        server kubernetes-master3:6443;
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
