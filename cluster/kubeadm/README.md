# Kuberenetes On Prem using kubeadm

# Key takeway

* k8s version: 1.30
* debian/ubuntu machine
* enable br_netfilter and overlay modules
* enable ip_forward capabilitie
* using containerd as CRI, set it properly for cgroup.
* using systemd as cgroup, drivers (https://kubernetes.io/docs/setup/production-environment/container-runtimes/#systemd-cgroup-driver)
** configure /etc/containerd/config.toml to use cgrup
** configure kubelet to use systemd 
* deploy first control plane node with kubeadmin
** configure APIs propely 
** use the options --upload-certs to store cert key on k8s config (find it!)
** check variables as lb and node dns/ip
** apply CNI
** get control plane join and worker cmd
* launch others control plane
* launch workds
