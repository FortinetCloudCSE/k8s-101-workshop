---
title: "Task 6 - Exposing Applications with Services, Load Balancers, and Ingress"
menuTitle: "Exposing application"
chapter: false
weight: 5
---




#### ClusterIP

Below we created a ClusterIP service for kubernetes-bootcamp deployment. 
```bash
kubectl expose deployment kubernetes-bootcamp --port 80 --type=ClusterIP --target-port=8080

```
we can check the service with command `kubectl get svc kubernetes-bootcamp`

```bash
ubuntu@ubuntu22:~$ kubectl get svc kubernetes-bootcamp
NAME                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
kubernetes-bootcamp   ClusterIP   10.105.106.151   <none>        80/TCP    15s
```

the IP address 10.105.106.151 is the VIP created by IPTables or IPVS which can only be accessed from cluster internal. once traffic reach 10.105.106.151, the traffic will be load balancered to acutal backend 10 nginx containers 

we can use `kubectl get ep -l app=kubernetes-bootcamp`  to check the backend endpoints.
```bash
ubuntu@ubuntu22:~$ kubectl get ep -l app=kubernetes-bootcamp
NAME                  ENDPOINTS                                                              AGE
kubernetes-bootcamp   10.244.222.16:8080,10.244.222.17:8080,10.244.222.18:8080 + 7 more...   3m33s

```
Let's try to access kubernetes-bootcamp via cluster-ip from other pod.

first find the ip and port for kubernetes-bootcamp service
```bash
ubuntu@ubuntu22:~$ k get svc kubernetes-bootcamp
NAME                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
kubernetes-bootcamp   ClusterIP   10.105.106.151   <none>        80/TCP    8m10s
```

then create a POD which has curl command to access kubernetes-bootcamp svc (service)
```bash
kubectl run curlpod --image=appropriate/curl --restart=Never --rm -it -- curl http://10.105.106.151:80

```
you shall see output after a while 

```bash
ubuntu@ubuntu22:~$ kubectl run curlpod --image=appropriate/curl --restart=Never --rm -it -- curl http://10.105.106.151:80
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-bcbb7fc75-fn29h | v=1
pod "curlpod" deleted

```
the ngnix server return "Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-bcbb7fc75-fn29h" telling you that the response is from which POD.

try run it again, you will find the response now come from different POD.
```bash
ubuntu@ubuntu22:~$ kubectl run curlpod --image=appropriate/curl --restart=Never --rm -it -- curl http://10.105.106.151:80
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-bcbb7fc75-5kjd7 | v=1
pod "curlpod" deleted
```

#### NodePort



To allow access the app from cluster external for example internet , we need to expose the service for app via NodePort or Loadbalancer. 

With NodePort, the worker node that actually running that container will open a NATTed PORT to external , you will also need whitelist the port if you have external firewall.
the NATTED PORT use default range 30000-32767. This means when you create a service of type NodePort without specifying a particular port, Kubernetes will automatically allocate a port for that service from within this default range.

```bash
kubectl expose deployment kubernetes-bootcamp --port 80 --type=NodePort --target-port=8080 --name kubernetes-bootcamp-nodeportsvc
kubectl get svc kubernetes-bootcamp-nodeportsvc
``````
we shall see output like

```bash
ubuntu@ubuntu22:~$ kubectl expose deployment kubernetes-bootcamp --port 80 --type=NodePort --target-port=8080 --name kubernetes-bootcamp-nodeportsvc
service/kubernetes-bootcamp-nodeportsvc exposed
ubuntu@ubuntu22:~$ kubectl get svc kubernetes-bootcamp-nodeportsvc
NAME                              TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kubernetes-bootcamp-nodeportsvc   NodePort   10.103.189.68   <none>        80:30913/TCP   24s
ubuntu@ubuntu22:~$ 
```
the NATTED PORT on worker node that running POD is 30913.  we also need to find the IP address of worker node that running kubernetes-bootcamp container.

```bash
kubectl get pod -l app=kubernetes-bootcamp -o wide
```
from output, we can see that the pod is running on worker001 node. then we need to find out the ip address for worker001 node via `kubectl get node -o wide`


```
ubuntu@ubuntu22:~$ k get node worker001 -o wide
NAME        STATUS   ROLES    AGE    VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
worker001   Ready    worker   115m   v1.26.1   10.0.0.5      <none>        Ubuntu 22.04.3 LTS   6.2.0-1019-azure   cri-o://1.25.4
```

so the address is 10.0.0.5 , or use domain k8strainingworker001.westus.cloudapp.azure.com:30913 for internet users.
use `curl http://10.0.0.5:30913` to access application 

```bash
ubuntu@ubuntu22:~$ curl http://10.0.0.5:30913
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-bcbb7fc75-q7sqc | v=1
```
or `curl k8strainingworker001.westus.cloudapp.azure.com:30913`

```
ubuntu@ubuntu22:~$ curl k8strainingworker001.westus.cloudapp.azure.com:30913
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-bcbb7fc75-nh9sn | v=1
```

Using NodePort services in Kubernetes, while useful for certain scenarios, comes with several disadvantages, especially when considering the setup where traffic is directed through the IP of a single worker node has limitation of Inefficient Load Balancing, Exposure to External Traffic,Lack of SSL/TLS Termination etc., so NodePort services are often not suitable for production environments, especially for high-traffic applications that require robust load balancing, automatic scaling, and secure exposure to the internet. For scenarios requiring exposure to external traffic, using an Ingress controller or a cloud provider's LoadBalancer service is generally recommended. These alternatives offer more flexibility, better load distribution, and additional features like SSL/TLS termination and path-based routing, making them more suitable for production-grade applications.

### LoadBalancer Service

A LoadBalancer service in Kubernetes is a way to expose an application running on a set of Pods to the external internet in a more accessible manner than NodePort.  

we can use the kubectl expose command as follow to create a loadbalancer service for deployment kubernetes-bootcamp.

```bash
kubectl expose deployment kubernetes-bootcamp --port=80 --type=LoadBalancer --target-port=8080 --name=kubernetes-bootcamp-lb-svc 
```
then check the svc, the External-IP  
```bash
ubuntu@ubuntu22:~$ kubectl get svc kubernetes-bootcamp-lb-svc
NAME                         TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kubernetes-bootcamp-lb-svc   LoadBalancer   10.106.121.27   10.0.0.4      80:32537/TCP   26s
```
and verify with `curl http://10.0.0.4`
```bash
curl http://10.0.0.4
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-bcbb7fc75-nh9sn | v=1
```

When we use the `kubectl expose` command to create a LoadBalancer service in a Kubernetes cluster with MetalLB installed in Layer 2 (L2) advertisement mode, the process simplifies to these key points:

Creating the Service: The command creates a LoadBalancer type service named kubernetes-bootcamp-lb-svc, which targets the kubernetes-bootcamp deployment.

Assigning an External IP: MetalLB automatically assigns an external IP address from its configured IP pool to the service, making it accessible outside the Kubernetes cluster.

L2 Advertisement: MetalLB advertises the assigned IP address across the local network using ARP, directing traffic to the Kubernetes node responsible for the service.

Traffic Routing: Incoming traffic to the external IP is routed to the targeted pods within the cluster, enabling external access to the application.

This streamlined process allows MetalLB to provide external IPs for services, enabling external access in environments without native cloud provider LoadBalancer support.

If you use cloud managed kubernetes like EKS, GKE, AKE, then cloud provider will responsible for create loadbalancer instance and assign ip address , then Metallb is not reqiured in that case. 

### What is ingress and ingress controller
Ingress is not classified as a type of Kubernetes Service because it operates at a higher layer in the network stack and serves a different purpose. 

Ingress operates at the application layer (Layer 7 of the OSI model), dealing with HTTP and HTTPS traffic. It allows for more complex routing based on the request's URL path or host, and can manage SSL/TLS termination, name-based virtual hosting, and more.

It's designed to give developers more control over the access to services from outside the Kubernetes cluster, including URL path-based routing, domain name support, and managing SSL/TLS certificates.

An Ingress typically routes traffic to one or more Kubernetes Services. It acts as an entry point to the cluster that forwards incoming requests to the appropriate Services based on the configured rules. In this sense, Ingress depends on Services to function, but it provides a more flexible and sophisticated way to expose those Services to the outside world.

Ingress requires an Ingress controller to be running in the cluster, which is a separate component that watches the Ingress resources and processes the rules they define. While Kubernetes supports Ingress resources natively, the actual routing logic is handled by this external component. There are many Ingress controller you can use for example, nginx based ingress controller, kong ingress controller, also some vendor like fortinet offer fortiweb as ingress controller.

 


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
