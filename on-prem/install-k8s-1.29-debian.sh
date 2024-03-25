#!/bin/bash

# Conntainer runtime prerequisites
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
## Network setup
sudo modprobe overlay
sudo modprobe br_netfilter
# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
# Apply sysctl params without reboot
sudo sysctl --system

###################################################################################################
##### Installing docker with containerd
# Add Docker's official GPG key:
sudo apt-get update -y
sudo apt-get install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io -y

###################################################################################################
########## kubeadmin kubelet kubectl
sudo apt-get update -y
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
# sudo systemctl enable --now kubelet # optional

###################################################################################################
##########  Configurrations
# cat <<EOF >kubeadm-config.yaml
# # kubeadm-config.yaml
# kind: ClusterConfiguration
# apiVersion: kubeadm.k8s.io/v1beta3
# #kubernetesVersion: v1.21.0
# networking:
#   podSubnet: 10.244.0.0/16
# ---
# kind: KubeletConfiguration
# apiVersion: kubelet.config.k8s.io/v1beta1
#   cgroupDriver: systemd
# EOF

# containerd config to work with Kubernetes >=1.26
echo "SystemdCgroup = true" > /etc/containerd/config.toml
systemctl restart containerd

# Just disable ufw
sudo systemctl stop ufw
sudo systemctl disable ufw

#########################################################
# DigitalOcean with firewall (VxLAN with Flannel) - could be resolved in the future by allowing IP-in-IP in the firewall settings
#echo "deploying kubernetes (with canal)..."
#kubeadm init --config kubeadm-config.yaml # add --apiserver-advertise-address="ip" if you want to use a different IP address than the main server IP
#kubeadm init --config kubeadm-config.yaml # add --apiserver-advertise-address="ip" if you want to use a different IP address than the main server IP
#export KUBECONFIG=/etc/kubernetes/admin.conf
#curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/canal.yaml -O
#kubectl apply -f canal.yaml
#echo "HINT: "
#echo "run the command: export KUBECONFIG=/etc/kubernetes/admin.conf if kubectl doesn't work"

#kubeadm join 192.168.56.2:6443 --token w45v86.m6hh90rsyiaalkmm \
#    --discovery-token-ca-cert-hash sha256:8fc8310b4fc3f69720c3b77209253a93b0d4c409553c6bd865d07978ddacb80a 
