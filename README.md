# kubernetes
Kubernetes deployments using kustomization

```
export NAMESPACE=test
kustomize build  | envsubst \$NAMESPACE | kubectl apply -f -
```

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