# kubernetes
Kubernetes deployments using kustomization

```
export NAMESPACE=test
kustomize build  | envsubst \$NAMESPACE | kubectl apply -f -
```
