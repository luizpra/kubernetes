# Istio - Extenal Control Plane

* [Link Reference](https://preliminary.istio.io/latest/docs/setup/install/external-controlplane/)

We'll follow this design

![External control plane cluster and remote cluster](https://preliminary.istio.io/latest/docs/setup/install/external-controlplane/external-controlplane.svg)


## Creating `control` (conrol-plane) cluster

Create `control` clusters using kind:
```bash
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: external.cluster
nodes:
- role: control-plane
EOF
```

Add load balancer feature with `metallb`. Check docker network for kind and set the ip range for metallb.
```sh
docker network inspect -f '{{.IPAM.Config}}' kind
```
```sh
export LB_IP_RANGE=172.23.255.200-172.23.255.250
```

Install `metallb` and wait for it to be ready.
```sh
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
kubectl wait --namespace metallb-system \
                --for=condition=ready pod \
                --selector=app=metallb \
                --timeout=90s
```

```sh
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: example
  namespace: metallb-system
spec:
  addresses:
  - ${LB_IP_RANGE}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: empty
  namespace: metallb-system
EOF
``` 


## Creating `data` (remote) cluster

Create `data` clusters using kind:
```bash
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: remote.cluster
nodes:
- role: control-plane
EOF
```


## Define enviromt variables

```sh
export ISTIO_HOME=~/dev/istio-1.18.0/bin/
export CTX_EXTERNAL_CLUSTER=kind-control
export CTX_REMOTE_CLUSTER=kind-data-one
export REMOTE_CLUSTER_NAME=data-one
```

Create the Istio install configuration for the ingress gateway that will expose the external control plane ports to other clusters:
```sh
cat <<EOF | ${ISTIO_HOME}/istioctl install --context="${CTX_EXTERNAL_CLUSTER}" --skip-confirmation -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
spec:
  components:
    ingressGateways:
      - name: istio-ingressgateway
        enabled: true
        k8s:
          service:
            ports:
              - port: 15021
                targetPort: 15021
                name: status-port
              - port: 15012
                targetPort: 15012
                name: tls-xds
              - port: 15017
                targetPort: 15017
                name: tls-webhook
EOF
```

Confirm that the ingress gateway is up and running:
```sh
kubectl get po -n istio-system --context="${CTX_EXTERNAL_CLUSTER}"
```

Set the EXTERNAL_ISTIOD_ADDR environment variable to the hostname and SSL_SECRET_NAME environment variable to the secret that holds the TLS certs:
```sh
export EXTERNAL_ISTIOD_ADDR=$(kubectl -n istio-system --context="${CTX_EXTERNAL_CLUSTER}" get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export SSL_SECRET_NAME=NONE
```

### Set up the remote config cluster

```sh
kubectl create namespace external-istiod --context="${CTX_REMOTE_CLUSTER}"

cat <<EOF | ${ISTIO_HOME}/istioctl manifest generate --set values.defaultRevision=default  -f - | kubectl apply --context="${CTX_REMOTE_CLUSTER}" -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: 
spec:
  profile: remote
  values:
    global:
      istioNamespace: external-istiod
      remotePilotAddress: ${EXTERNAL_ISTIOD_ADDR}
      configCluster: true
    pilot:
      configMap: true
    istiodRemote:
      injectionPath: /inject/cluster/${REMOTE_CLUSTER_NAME}/net/network1
EOF
kubectl get mutatingwebhookconfiguration --context="${CTX_REMOTE_CLUSTER}"
kubectl get validatingwebhookconfiguration --context="${CTX_REMOTE_CLUSTER}"
```


Set up the control plane in the external cluster

```sh
kubectl create namespace external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
```

Create a secret with credentials to access the remote cluster’s kube-apiserver and install it in the external cluster
```sh
kubectl create sa istiod-service-account -n external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
${ISTIO_HOME}/istioctl x create-remote-secret \
  --context="${CTX_REMOTE_CLUSTER}" \
  --type=config \
  --namespace=external-istiod \
  --service-account=istiod \
  --server=https://172.23.0.3:6443 \
  --create-service-account=false | \
kubectl apply -f - --context="${CTX_EXTERNAL_CLUSTER}"
```

```sh
cat <<EOF | ${ISTIO_HOME}/istioctl install --context="${CTX_EXTERNAL_CLUSTER}" --skip-confirmation -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: external-istiod
spec:
  profile: empty
  meshConfig:
    rootNamespace: external-istiod
    defaultConfig:
      discoveryAddress: 172.23.255.200:15012
  components:
    pilot:
      enabled: true
      k8s:
        overlays:
        - kind: Deployment
          name: istiod
          patches:
          - path: spec.template.spec.volumes[100]
            value: |-
              name: config-volume
              configMap:
                name: istio
          - path: spec.template.spec.volumes[100]
            value: |-
              name: inject-volume
              configMap:
                name: istio-sidecar-injector
          - path: spec.template.spec.containers[0].volumeMounts[100]
            value: |-
              name: config-volume
              mountPath: /etc/istio/config
          - path: spec.template.spec.containers[0].volumeMounts[100]
            value: |-
              name: inject-volume
              mountPath: /var/lib/istio/inject
        env:
        - name: INJECTION_WEBHOOK_CONFIG_NAME
          value: istio-sidecar-injector-external-istiod
        - name: VALIDATION_WEBHOOK_CONFIG_NAME
          value: istio-validator-external-istiod
        - name: EXTERNAL_ISTIOD
          value: "true"
        - name: LOCAL_CLUSTER_SECRET_WATCHER
          value: "true"
        - name: CLUSTER_ID
          value: data-one
        - name: SHARED_MESH_CONFIG
          value: istio
  values:
    global:
      caAddress: 172.23.255.200:15012
      istioNamespace: external-istiod
      operatorManageWebhooks: true
      configValidation: false
      meshID: mesh1
      multiCluster:
        clusterName: data-one
      network: network1
EOF
kubectl get po -n external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
```

```sh
cat <<EOF | kubectl apply --context="${CTX_EXTERNAL_CLUSTER}" -f -
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: external-istiod-gw
  namespace: external-istiod
spec:
  selector:
    istio: ingressgateway
  servers:
    - port:
        number: 15012
        protocol: tls
        name: tls-XDS
      tls:
        mode: PASSTHROUGH
      hosts:
      - "*"
    - port:
        number: 15017
        protocol: tls
        name: tls-WEBHOOK
      tls:
        mode: PASSTHROUGH
      hosts:
      - "*"
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
   name: external-istiod-vs
   namespace: external-istiod
spec:
    hosts:
    - "*"
    gateways:
    - external-istiod-gw
    tls:
    - match:
      - port: 15012
        sniHosts:
        - "*"
      route:
      - destination:
          host: istiod.external-istiod.svc.cluster.local
          port:
            number: 15012
    - match:
      - port: 15017
        sniHosts:
        - "*"
      route:
      - destination:
          host: istiod.external-istiod.svc.cluster.local
          port:
            number: 443
---
EOF
```


# Mesh admin steps

```sh
kubectl create --context="${CTX_REMOTE_CLUSTER}" namespace sample
kubectl label --context="${CTX_REMOTE_CLUSTER}" namespace sample istio-injection=enabled
kubectl apply -f ~/dev/istio-1.18.0/samples/helloworld/helloworld.yaml -l service=helloworld -n sample --context="${CTX_REMOTE_CLUSTER}"
kubectl apply -f ~/dev/istio-1.18.0/samples/helloworld/helloworld.yaml -l version=v1 -n sample --context="${CTX_REMOTE_CLUSTER}"
kubectl apply -f ~/dev/istio-1.18.0/samples/sleep/sleep.yaml -n sample --context="${CTX_REMOTE_CLUSTER}"
kubectl get pod -n sample --context="${CTX_REMOTE_CLUSTER}"
```

```sh
kubectl exec --context="${CTX_REMOTE_CLUSTER}" -n sample -c sleep \
    "$(kubectl get pod --context="${CTX_REMOTE_CLUSTER}" -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
```




cat <<EOF > istio-ingressgateway.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: empty
  components:
    ingressGateways:
    - namespace: external-istiod
      name: istio-ingressgateway
      enabled: true
  values:
    gateways:
      istio-ingressgateway:
        injectionTemplate: gateway
EOF
istioctl install -f istio-ingressgateway.yaml --set values.global.istioNamespace=external-istiod --context="${CTX_REMOTE_CLUSTER}"
 










 kubectl get pod -l app=istio-ingressgateway -n external-istiod --context="${CTX_REMOTE_CLUSTER}"