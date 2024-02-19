---
title: "Task 6 - Exposing Applications with Services, Load Balancers, and Ingress"
menuTitle: "Exposing application"
chapter: false
weight: 5
---



We have cover basic service expose with cluster-ip, nodeport etc in previous chapter. 
in this chapter, we will focus on Ingress and Ingress controller.


#### install metallb loadbalancer 

In a self-managed Kubernetes environment, external traffic management and service exposure are not handled automatically by the infrastructure, unlike managed Kubernetes services in cloud environments (e.g., AWS ELB with EKS, Azure Load Balancer with AKS, or Google Cloud Load Balancer with GKE). This is where solutions like MetalLB and the Kong Ingress Controller become essential

MetalLB provides a network load balancer implementation for Kubernetes clusters that do not run on cloud providers, offering a LoadBalancer type service. In cloud environments, when you create a service of type LoadBalancer, the cloud provider provisions a load balancer for your service. In contrast, on-premises or self-managed clusters do not have this luxury. MetalLB fills this gap by allocating IP addresses from a configured pool and managing access to services through these IPs, enabling external traffic to reach the cluster services.




```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
kubectl rollout status deployment controller -n metallb-system

```



**create ippool for metallb to use** 

```bash 
cd $HOME
local_ip=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}') 
cat <<EOF | sudo tee metallbippool.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - $local_ip/32
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
EOF
kubectl apply -f metallbippool.yaml
```
use `kubectl get ipaddresspool -n metallb-system` to check installed ippool


#### Install Kong ingress controller 
The Kong Ingress Controller is an Ingress controller for Kubernetes that manages external access to HTTP services within a cluster using Kong Gateway. It processes Ingress resources to configure HTTP routing, load balancing, authentication, and other functionalities, leveraging Kong's powerful API gateway features for Kubernetes services.  Kong will use the ippool that managed by metallb. 


```bash
kubectl apply -f  https://raw.githubusercontent.com/Kong/kubernetes-ingress-controller/v2.10.0/deploy/single/all-in-one-dbless.yaml
kubectl rollout status deployment proxy-kong -n kong
kubectl rollout status deployment ingress-kong -n kong

```

use `kubectl get svc kong-proxy -n kong` to check installed load balancer which is kong-proxy
use `kubectl get ingressclasses` to check kong become the ingress controller. 


after done all above, now you have completed the setup of kubernetes master node. 
it's time to setup worker node and join cluster. remember without worker node. you will not able to create application POD unless you ask speically to create POD on master node which usually is not the option for production deployment. 
 
#### Create nginx deployment  

create nginx deployment with replicas set to 2. the container also configured resource usage limition for cpu and memory.

```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"  # Minimum memory requested to start the container
            cpu: "10m"     # 100 millicpu (0.1 CPU) requested to start the container
          limits:
            memory: "128Mi" # Maximum memory limit for the container
            cpu: "40m"     # 200 millicpu (0.2 CPU) maximum limit for the container
EOF
kubectl rollout status deployment nginx-deployment
```

#### create nginx clusterIP svc for nginx-deployment 

```bash
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  labels:
    app: nginx
  name: nginx-deployment
  namespace: default
spec:
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: nginx
  sessionAffinity: None
  type: ClusterIP
EOF
```
user can use `kubectl get svc nginx-deployment` to check the installed **ClusterIP** service. which essentially created an iptables entry to loadbalancer traffic from cluster-internal to nginx pod regardless the pod is on same worker node or different worker node. ClusterIP is only for cluster-internal traffic, traffic outside of cluster will not able to reach clusterIP.  to make traffic outside cluster like from internet to reach nginx container. user will require to create loadbalancer type service or ingress service.





#### Create https ingress rule for nginx-deployment 
to support https, a certificate for ingress controller is required. user can choose "cert-manager" for manage and deploy certificate. 

use below cli to deploy cert-manager which is used to issue certificate needed for service

```bash
kubectl get namespace cert-manager || kubectl create namespace cert-manager 
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.3.1/cert-manager.yaml
kubectl rollout status deployment cert-manager -n cert-manager
```
 

once deployed. we need to create a certificate for service. 

```bash
cat << EOF | kubectl apply -f -
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer-test
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: test-tls-test
spec:
  secretName: test-tls-test
  duration: 2160h # 90d
  renewBefore: 360h # 15d
  issuerRef:
    name: selfsigned-issuer-test
    kind: ClusterIssuer
  commonName: kong.example
  dnsNames:
  - ubuntu22
EOF

```
use `kubectl get secret  test-tls-test` and `kubectl get cert test-tls-test` to check deployment

create ingress rule for nginx 

```
cat <<EOF  | kubectl apply -f - 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx
  annotations:
    konghq.com/strip-path: 'true'
    cert-manager.io/cluster-issuer: selfsigned-issuer-test
spec:
  tls:
  - hosts:
    - ubuntu22 
  ingressClassName: kong
  rules:
  - host: ubuntu22
    http:
      paths:
      - path: /default
        pathType: ImplementationSpecific
        backend:
          service:
            name: nginx-deployment
            port:
              number: 80
EOF
```
use `kubectl get ingress nginx` and `kubectl describe ingress nginx` to check status

use `curl -k  https://ubuntu22/default` and `curl http://ubuntu22/default` to verify 




after deploy ingress rule. now you shall able to access nginx via `curl http://ubuntu22/default`, while use `curl http://ubuntu22/` will got error message  

use `kubectl get ingress nginx` and `kubectl describe ingress nginx` to check the ingress rule


<TODO>
HTTP redirect etc.,
