# Contour 

[Getting Started](https://projectcontour.io/getting-started/)
[Getting Started with Kind](https://projectcontour.io/docs/1.25/guides/kind/)


## Ingress controller

On `Kind` cluster:
```yaml
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    listenAddress: "0.0.0.0"
  - containerPort: 443
    hostPort: 443
    listenAddress: "0.0.0.0"
EOF
```

Apply manifests
```sh
kubectl apply -f https://projectcontour.io/quickstart/contour.yaml
```
Verify pods
```sh
kubectl get pods -n projectcontour -o wide
```

Test it out!
```sh
kubectl apply -f https://projectcontour.io/examples/httpbin.yaml
```
Verify it!
```sh
kubectl get po,svc,ing -l app=httpbin
```