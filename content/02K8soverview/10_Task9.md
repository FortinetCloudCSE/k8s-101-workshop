---
title: "Task 8 - Service Mesh"
menuTitle: "Service Mesh"
chapter: false
weight: 5
---

### Preparation

Before installing Istio/Envoy, check if there is a free external IP available for a load balancer, as Istio will install an ingress gateway that requires a load balancer with an external IP.

If a `kong-proxy` load balancer exists with an external IP, delete it, as we have only one external IP available for use.

```bash
kubectl delete svc kong-proxy -n kong

```
Also, ensure CoreDNS is using an IP from Calico. Otherwise:

```
kubectl rollout restart deployment kube-dns -n kube-system
kubectl rollout status deployment kube-dns -n kube-system
```
### install istio-envoy

Download and Extract Istio
```
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.20.3 sh -
cd istio-1.20.3
```
The istioctl command-line tool is in the bin directory; you might want to add it to your path for ease of use:
```
export PATH=$PWD/bin:$PATH
```

Install Istio Using istioctl

Istio offers different configuration profiles for installation. For a standard installation (which is suitable for most use cases), you can use the default profile:
```bash
istioctl install --set profile=default -y
```
This command uses istioctl to install Istio with the default profile.  

### Enable Automatic Sidecar Injection

Enable automatic sidecar injection for your namespace:

```bash
kubectl label namespace client istio-injection=enabled

```
### Verify the Installation
Check that the Istio control plane services and pods are up and running:

And verify that the corresponding Istio control plane pods are all in a RUNNING state:

```
kubectl get pods -n istio-system
```

### Demo

Ensure Automatic Sidecar Injection is Enabled
```bash
kubectl label namespace client istio-injection=enabled
```

Create a Backend Service

Deploy a simple HTTP echo service as the backend:


### deploy backend service 
```bash
cat << EOF | backend.yaml
apiVersion: v1
kind: Service
metadata:
  name: echo-service
  namespace: client
spec:
  ports:
  - port: 80
    name: http
    targetPort: 5678
  selector:
    app: echo
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-deployment
  namespace: client
spec:
  replicas: 1
  selector:
    matchLabels:
      app: echo
  template:
    metadata:
      labels:
        app: echo
    spec:
      containers:
      - name: echo
        image: hashicorp/http-echo
        args:
        - "-text=Hello from backend service"
        ports:
        - containerPort: 5678
EOF
kubectl apply -f backend.yaml

```
deploy frontend application

```bash
cat <<EOF | client.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: client-deployment
  namespace: client
spec:
  replicas: 1
  selector:
    matchLabels:
      app: client
  template:
    metadata:
      labels:
        app: client
    spec:
      containers:
      - name: client
        image: curlimages/curl
        command: ["/bin/sh", "-c"]
        args:
        - >
          while true; do
            sleep 10;
            curl echo-service.client.svc.cluster.local;
          done
EOF
```
kubectl apply -f client.yaml

Verify Traffic Flow Through the Envoy Proxy
Verify the setup by checking the logs of the client pod to see responses from the backend service:

Check the Logs of the Client Pod


```bash
kubectl logs -n client -l app=client -c client
```

### install kiali
Install Kiali for observability:

```bash
kubectl apply -f ${ISTIO_HOME}/samples/addons/kiali.yaml
```
### expose kiali dashboard

Forward the Kiali dashboard port to make it accessible:


```bash
kubectl port-forward svc/kiali 20001:20001 -n istio-system &
socat TCP-LISTEN:30001,reuseaddr,fork TCP:127.0.0.1:20001
```

Verify access: 
```bash

curl http://k8strainingmaster001.westus.cloudapp.azure.com:30001
<a href="/kiali/">Found</a>.
```


### How service mesh works in general

Istio injects a sidecar container (Envoy proxy) into each client application pod labeled for Istio injection. This is achieved using Kubernetes' Mutating Admission Webhook, which intercepts pod creation requests to include the Envoy sidecar containers automatically.

below find each pod in client namespace has two container  with one is injected as sidecar container.

```bash
ubuntu@ubuntu22:~/istio-1.20.3$ k get pod -n client
NAME                                READY   STATUS    RESTARTS   AGE
client-deployment-965cf5696-jvfsq   2/2     Running   0          71m
echo-deployment-ddd46554c-bqpzw     2/2     Running   0          48m
```

This setup allows all inbound and outbound traffic from the client application to be proxied through the Envoy sidecar, enabling advanced traffic management, security, and observability features provided by Istio.

Istio uses the istio-ingressgateway service as a LoadBalancer for the service mesh, directing external traffic into the mesh.


`kubectl get svc istio-ingressgateway -n istio-system` 

```bash
ubuntu@ubuntu22:~/istio-1.20.3$ k get svc istio-ingressgateway -n istio-system
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                                      AGE
istio-ingressgateway   LoadBalancer   10.107.233.181   10.0.0.4      15021:30938/TCP,80:30244/TCP,443:32419/TCP   90m
```
Istio use iptables for steer traffic from client application to be proxyed by envoy proxy instead directly go to backend.


