# kubernetes
Kubernetes deployments using kustomization

```
export NAMESPACE=test
kustomize build  | envsubst \$NAMESPACE | kubectl apply -f -
```

# Docker 

Connect a container to a network
```sh
docker network connect bridgeB container1
```

# Kustomization

[Kustomize](https://kubectl.docs.kubernetes.io/references/kustomize/)
[Kustomization file](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/)

### [Kustomization Resources](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/resource/)
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- myNamespace.yaml
- sub-dir/some-deployment.yaml
- ../../commonbase
# on browser https://github.com/kubernetes-sigs/kustomize/tree/v1.0.6/examples/multibases
- github.com/kubernetes-sigs/kustomize/examples/multibases?ref=v1.0.6
- deployment.yaml
- github.com/kubernets-sigs/kustomize/examples/helloWorld?ref=test-branch
```



https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/resource/


# Helm cheat sheet

```sh
helm repo add <name> <url>
helm list
helm search repo <reponame>
# Examine chart for possibles issues
helm lint
# Helm show values from vepoo
helm show values <repo>/<chart>

# Generate the necessary manifests
helm template <name> <repo>/<chart> --values <files> -n <namespace>

# Install directly on the cluster
helm install <name> <repo>/<chart> --values <files> -n <namespace>
```


# Rolldice exampele

```
curl -iL rolldice.k8s.local
```


[GoGetter](https://github.com/hashicorp/go-getter#url-format)
[Rancher and Kind](https://github.com/ozbillwang/rancher-in-kind)


# Kuberntes on alpine
vagrant box -> `generic/alpine318`

[Link](https://wiki.alpinelinux.org/wiki/K8s)
