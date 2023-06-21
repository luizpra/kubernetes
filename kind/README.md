# Kubernetes -  Kind

* [Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/)
* [Ingress](https://kind.sigs.k8s.io/docs/user/ingress)
* [Load balancer](https://kind.sigs.k8s.io/docs/user/loadbalancer)
* [Kind Github Releases](https://github.com/kubernetes-sigs/kind/releases)
* [Configuration](https://kind.sigs.k8s.io/docs/user/configuration/)
* [Docker Registry](https://hub.docker.com/_/registry)


```sh
kind create cluster --config kind.yml
```



### Deploy dashboard

Deploy dashboard
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```
Verify that Dashboard is deployed and running
```
kubectl get pod -n kubernetes-dashboard
```
Create a ServiceAccount and ClusterRoleBinding to provide admin access to the newly created cluster.
```
kubectl create serviceaccount -n kubernetes-dashboard admin-user
kubectl create clusterrolebinding -n kubernetes-dashboard admin-user --clusterrole cluster-admin --serviceaccount=kubernetes-dashboard:admin-user
```
To login to Dashboard, you need a Bearer Token. Use the following command to store the token in a variable.
```
export token=$(kubectl -n kubernetes-dashboard create token admin-user)
echo $token
```

You can Access Dashboard using the kubectl command-line tool by running the following command
```
kubectl proxy
```

## Istio 

[Ref](https://istio.io/latest/docs/setup/platform-setup/kind/)

