#!/bin/bash

echo ""
echo $IS_MASTER
echo $IP_ADDRESS
echo ""

apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update -y
apt-get install -y kubelet kubeadm kubectl containerd
apt-mark hold kubelet kubeadm kubectl
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
## Network setup
modprobe overlay
modprobe br_netfilter
# sysctl params required by setup, params persist across reboots
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update -y
apt-get install -y kubelet kubeadm kubectl containerd
apt-mark hold kubelet kubeadm kubectl
mkdir /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl stop ufw
systemctl disable ufw

if [ $IS_MASTER = "true" ]; then
    if [ $IP_ADDRESS = "192.168.56.11" ]; then
        rm /vagrant/admin.conf
        rm /vagrant/join.sh
        rm /vagrant/join-control-plane.sh
        echo "Kubeadm initializing ...." 
        sleep 3
        kubeadm init --config /vagrant/kube.yml --upload-certs --v=5
        cp /etc/kubernetes/admin.conf /vagrant/
        export KUBECONFIG=/vagrant/admin.conf
        # kubectl apply -f /vagrant/canal.yaml
        kubectl apply -f /vagrant/calico.yaml
        sleep 3
        kubectl get pod --all-namespaces
        JOIN_CMD=$(kubeadm token create --print-join-command)
        JOIN_CMD_CONTROL_PLANE="$JOIN_CMD --control-plane --certificate-key $CERT_KEY"
        echo "$JOIN_CMD" > /vagrant/join.sh
        echo "$JOIN_CMD_CONTROL_PLANE" > /vagrant/join-control-plane.sh
        chmod +x /vagrant/join.sh
        chmod +x /vagrant/join-control-plane.sh
    else
        echo "Joining control plane node ..."
        CMD=$(cat /vagrant/join-control-plane.sh)
        CMD=$(echo "$CMD --apiserver-advertise-address $IP_ADDRESS --v=5")
        echo "Running $CMD"
        eval "$CMD"
    fi
else
    echo "Joining worker node ..."
    echo "Running $(cat /vagrant/join.sh)"
    /vagrant/join.sh
fi

