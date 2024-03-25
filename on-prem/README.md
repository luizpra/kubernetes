# On premisse K8s installation

# References

[Installing kubeadmin](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
[Creating a cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)

```
#server {
#    listen 6443;
#    listen [::]:6443;
#
#    server_name kube-api;
#
#    location / {
#        proxy_pass https://backend_server;
#        proxy_set_header Host \$host;
#        proxy_set_header X-Real-IP \$remote_addr;
#        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
#        proxy_set_header X-Forwarded-Proto \$scheme;
#        proxy_ssl_verify off;
#    }
#}
```
```sh
kubeadm init --control-plane-endpoint="kube-api:6443" \
    --apiserver-advertise-address=192.168.56.101 \
    --apiserver-bind-port=6443 \
    --kubernetes-version=v1.29.0 \
    --pod-network-cidr=10.244.0.0/16 \
    --upload-certs --v=5
```
```
kubeadm join kube-api:6443 --token eghnoy.yzpxi23wtkwwgdsc --discovery-token-ca-cert-hash sha256:f46683464a7b287c055d6b1874cfa8cbbf6c2cff32a3e29dcb045894c2859430 \
    --control-plane \
    --apiserver-advertise-address=192.168.56.102 \
    --apiserver-bind-port=6443 
```

