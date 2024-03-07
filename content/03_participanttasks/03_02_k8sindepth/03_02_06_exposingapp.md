---
title: "Task 6 - Exposing Applications with Loadbalancer and Ingress"
menuTitle: "Task 6 -  Exposing application"
weight: 6
---

## Objective: 

1. Expose your deployment to external of cluster.

2. We have covered Kubernetes clusterIP svc in previous chapter, in this chapter, we focus on expose application to cluster external service which are NodePort, LoadBalancer and Ingress.

3. Before We can continue, let's create a deployment first with 

```bash
kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1 --replicas=2
```
check with
```bash
kubectl get deployment kubernetes-bootcamp
``` 
4. expected Outcome 
```
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   2/2     2            2           4s
```

#### NodePort

1. To allow access the app from cluster external for example internet , we need to expose the service for app via NodePort or Loadbalancer. 

2. With NodePort, the worker node that actually running that container will open a NATTed PORT to external , you will also need whitelist the port if you have external firewall.
the NATTED PORT use default range 30000-32767. This means when you create a service of type NodePort without specifying a particular port, Kubernetes will automatically allocate a port for that service from within this default range.

3. We can use `kubectl expose` command to expose it or we can create service yaml definition  then use `kubectl create -f` to create service. use `kubectl create -f` give more flexibility. 

4. use kubectl expose 

```bash
kubectl expose deployment kubernetes-bootcamp --port 80 --type=NodePort --target-port=8080 --name kubernetes-bootcamp-nodeportsvc --save-config

```

5. expected Outcome

```bash
service/kubernetes-bootcamp-nodeportsvc exposed
```

6. using yaml file give more flexbility, for example , you can assign static nodePort as long as it's not being used.

```bash
cat << EOF | tee kubernetes-bootcamp-nodeportsvc.yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: kubernetes-bootcamp
  name: kubernetes-bootcamp-nodeportsvc
spec:
  ports:
  - nodePort: 30913
    port: 80
    protocol: TCP
    targetPort: 8080
  selector:
    app: kubernetes-bootcamp
  type: NodePort
EOF
kubectl apply -f kubernetes-bootcamp-nodeportsvc.yaml
```
7. expected outcome
```
service/kubernetes-bootcamp-nodeportsvc configured
```

8. check service detail

check service detail with `kubectl get svc kubernetes-bootcamp-nodeportsvc` 

expected Outcome
```
kubectl get svc kubernetes-bootcamp-nodeportsvc
NAME                              TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kubernetes-bootcamp-nodeportsvc   NodePort   10.103.189.68   <none>        80:30913/TCP   24s

```
9. the NATTED PORT on worker node that running POD is **30913**.

NodePort service will  exposes the service on a static port which is **30913** in this example on every node in the cluster, including both master and worker nodes. This means you can access the service using the IP address of **any node** in the cluster followed by the NodePort. you also need to config azure cloud to allow incoming traffic to **30913** from internet.

10. from azure shell , access the application via nodeport service 

use
```bash
curl http://$(whoami)-master.eastus.cloudapp.azure.com:30913
``` 
or 
```bash
curl http://$(whoami)-worker.eastus.cloudapp.azure.com:30913
```

11. expected outcome

```
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-bcbb7fc75-q7sqc | v=1
```

12. you can find the actual endpoint for nodeport service through command
```bash
kubectl get ep  -l app=kubernetes-bootcamp
```
expected output
```
NAME                              ENDPOINTS                                 AGE
kubernetes-bootcamp-nodeportsvc   10.244.152.116:8080,10.244.152.117:8080   20m
```

### summary 

Using NodePort services in Kubernetes, while useful for certain scenarios, comes with several disadvantages, especially when considering the setup where traffic is directed through the IP of a single worker node has limitation of Inefficient Load Balancing, Exposure to External Traffic,Lack of SSL/TLS Termination etc., so NodePort services are often not suitable for production environments, especially for high-traffic applications that require robust load balancing, automatic scaling, and secure exposure to the internet. For scenarios requiring exposure to external traffic, using an Ingress controller or a cloud provider's LoadBalancer service is generally recommended. These alternatives offer more flexibility, better load distribution, and additional features like SSL/TLS termination and path-based routing, making them more suitable for production-grade applications.

- clean up

```bash
kubectl delete svc kubernetes-bootcamp-nodeportsvc
kubectl delete deployment kubernetes-bootcamp
```

### What is LoadBalancer Service

A LoadBalancer service in Kubernetes is a way to expose an application running on a set of Pods to the external internet in a more accessible manner than NodePort.  

we can use the `kubectl expose` command as follow to create a loadbalancer service for deployment kubernetes-bootcamp.

LoadBalancer service require an **external IP** to use which we use metallb and create an ippool to assign external ip to loadbalancer 

#### install metallb loadbalancer 

In a self-managed Kubernetes environment, external traffic management and service exposure are not handled automatically by the infrastructure, unlike managed Kubernetes services in cloud environments (e.g., AWS ELB with EKS, Azure Load Balancer with AKS, or Google Cloud Load Balancer with GKE). This is where solutions like MetalLB and the Kong Ingress Controller become essential

MetalLB provides a network load balancer implementation for Kubernetes clusters that do not run on cloud providers, offering a LoadBalancer type service. In cloud environments, when you create a service of type LoadBalancer, the cloud provider provisions a load balancer for your service. In contrast, on-premises or self-managed clusters do not have this luxury. MetalLB fills this gap by allocating IP addresses from a configured pool and managing access to services through these IPs, enabling external traffic to reach the cluster services.


```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
kubectl rollout status deployment controller -n metallb-system

```

#### create ippool for metallb 


```bash 
cd $HOME
#local_ip=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}') 
local_ip=$(kubectl get node -o wide | grep 'control-plane' | awk '{print $6}')
cat <<EOF | tee metallbippool.yaml
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
Check created ipaddresspool

```bash
kubectl get ipaddresspool -n metallb-system
```
expected Outcome
```
NAME         AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES
first-pool   true          false             ["10.0.0.4/32"]
```

### Create loadBalacncer Service 

1. create kubernetes-bootcamp deployment 

We need create deployment first 

```bash
kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1 --replicas=2
``` 

2. create loadBalancer service 

since loadBalancer service require an dedicated external ip, if IP has already occupied by other loadBalancer, we will not able to create new loadBalancer. so if you have kong loadbalaner installed, delete it first with
```bash
kubectl delete svc kong-proxy -n kong
``` 

3. then create new loadBalancer 

```bash
kubectl expose deployment kubernetes-bootcamp --port=80 --type=LoadBalancer --target-port=8080 --name=kubernetes-bootcamp-lb-svc 
```
- check external ip assigned to LoadBalancer
```bash
kubectl get svc kubernetes-bootcamp-lb-svc
```
4. expected outcome
```
NAME                         TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kubernetes-bootcamp-lb-svc   LoadBalancer   10.106.121.27   10.0.0.4      80:32537/TCP   26s
```

5. verify with curl or external browser 

```bash
curl http://$(whoami)-master.eastus.cloudapp.azure.com
```
expected outcome 
```
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-bcbb7fc75-nh9sn | v=1
```
6. how it works 

When we use the `kubectl expose` command to create a LoadBalancer service in a Kubernetes cluster with MetalLB installed in Layer 2 (L2) advertisement mode, the process simplifies to these key points:

**Creating the Service**: The command creates a LoadBalancer type service named kubernetes-bootcamp-lb-svc, which targets the kubernetes-bootcamp deployment.

**Assigning an External IP**: MetalLB automatically assigns an external IP address from its configured IP pool to the service, making it accessible outside the Kubernetes cluster.

**L2 Advertisement**: MetalLB advertises the assigned IP address across the local network using ARP, directing traffic to the Kubernetes node responsible for the service.

**Traffic Routing**: Incoming traffic to the external IP is routed to the targeted pods within the cluster, enabling external access to the application.

This streamlined process allows MetalLB to provide external IPs for services, enabling external access in environments without native cloud provider LoadBalancer support.

If you use cloud managed kubernetes like EKS, GKE, AKE, then cloud provider will responsible for create loadbalancer instance and assign ip address , then Metallb is not reqiured in that case. 

### clean up

```bash
kubectl delete svc kubernetes-bootcamp-lb-svc
kubectl delete deployment kubernetes-bootcamp
```

### What is ingress and ingress controller

Ingress is not classified as a type of Kubernetes Service because it operates at a higher layer in the network stack and serves a different purpose. 

Ingress operates at the application layer (Layer 7 of the OSI model), dealing with HTTP and HTTPS traffic. It allows for more complex routing based on the request's URL path or host, and can manage SSL/TLS termination, name-based virtual hosting, and more.

It's designed to give developers more control over the access to services from outside the Kubernetes cluster, including URL path-based routing, domain name support, and managing SSL/TLS certificates.

An Ingress typically routes traffic to one or more Kubernetes Services. It acts as an entry point to the cluster that forwards incoming requests to the appropriate Services based on the configured rules. In this sense, Ingress depends on Services to function, but it provides a more flexible and sophisticated way to expose those Services to the outside world.

Ingress requires an Ingress controller to be running in the cluster, which is a separate component that watches the Ingress resources and processes the rules they define. While Kubernetes supports Ingress resources natively, the actual routing logic is handled by this external component. There are many Ingress controller you can use for example, nginx based ingress controller, kong ingress controller, also some vendor like fortinet offer fortiweb as ingress controller.


#### Install Kong ingress controller 
1. The Kong Ingress Controller is an Ingress controller for Kubernetes that manages external access to HTTP services within a cluster using Kong Gateway. It processes Ingress resources to configure HTTP routing, load balancing, authentication, and other functionalities, leveraging Kong's powerful API gateway features for Kubernetes services.  Kong will use the ippool that managed by metallb. 


```bash
kubectl apply -f  https://raw.githubusercontent.com/Kong/kubernetes-ingress-controller/v2.10.0/deploy/single/all-in-one-dbless.yaml
kubectl rollout status deployment proxy-kong -n kong
kubectl rollout status deployment ingress-kong -n kong

```
2. check installed load balancer

```bash
kubectl get svc kong-proxy -n kong
``` 
3. expected outcome
```
kong-proxy   LoadBalancer   10.97.121.60   10.0.0.4      80:32477/TCP,443:31364/TCP   2m10s
```

4. check ingressclass 
```bash
kubectl get ingressclasses
```
expected outcome
```
NAME   CONTROLLER                            PARAMETERS   AGE
kong   ingress-controllers.konghq.com/kong   <none>       9h
```

 
#### Create nginx deployment  

5. create nginx deployment with replicas set to 2. the container also configured resource usage limition for cpu and memory.

```bash
cd $HOME
cat <<EOF | tee nginx-deployment.yaml
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
kubectl apply -f nginx-deployment.yaml
kubectl rollout status deployment nginx-deployment
```

#### 6. create nginx clusterIP svc for nginx-deployment 

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
check created deployment
```bash
kubectl get deployment nginx-deployment
```
expected outcome
```
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   2/2     2            2           5m41s
```
check created svc 
```bash
kubectl get svc nginx-deployment
```
expected outcome 

```
NAME               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
nginx-deployment   ClusterIP   10.103.221.158   <none>        80/TCP    4m53s
```

#### 7. Create https ingress rule for nginx-deployment 
to support https, a certificate for ingress controller is required. user can choose "cert-manager" for manage and deploy certificate. 

use below cli to deploy cert-manager which is used to issue certificate needed for service

```bash
kubectl get namespace cert-manager || kubectl create namespace cert-manager 
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.3.1/cert-manager.yaml
kubectl rollout status deployment cert-manager -n cert-manager
kubectl rollout status deployment cert-manager-cainjector -n cert-manager
kubectl rollout status deployment cert-manager-webhook -n cert-manager 
```
 

once deployed. we need to create a certificate for service. 

```bash
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
cd $HOME
cat << EOF | tee certIssuer-${nodename}.yaml
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer-test
spec:
  selfSigned: {}
EOF
sleep 10
kubectl apply -f certIssuer-${nodename}.yaml
cat << EOF | tee cert-${nodename}.yaml
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
  - ${nodename}
EOF
kubectl apply -f cert-${nodename}.yaml
```

use `kubectl get secret  test-tls-test` and `kubectl get cert test-tls-test` to check deployment

- create ingress rule for nginx svc 

```bash
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
cd $HOME
cat <<EOF  | tee nginx_ingress_rule_with_cert_${nodename}.yaml
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
    - ${nodename} 
  ingressClassName: kong
  rules:
  - host: ${nodename}
    http:
      paths:
      - path: /default
        pathType: ImplementationSpecific
        backend:
          service:
            name: nginx-deployment
            port:
              number: 80
      - path: /bootcamp
        pathType: ImplementationSpecific
        backend:
          service:
            name: kubernetes-bootcamp
            port:
              number: 80  
EOF
kubectl apply -f nginx_ingress_rule_with_cert_${nodename}.yaml
```

8. check status 
```bash
kubectl get ingress nginx
```
expected outcome
```
NAME    CLASS   HOSTS               ADDRESS    PORTS     AGE
nginx   kong    k8s50-master.eastus.cloudapp.azure.com,k8s50-master.eastus.cloudapp.azure.com    10.0.0.4   80, 443   7m58s
```
- check ingress detail 
```bash
kubectl describe ingress nginx
```
expected outcome
```
Name:             nginx
Labels:           <none>
Namespace:        default
Address:          10.0.0.4
Ingress Class:    kong
Default backend:  <default>
TLS:
  SNI routes k8s50-master.eastus.cloudapp.azure.com
Rules:
  Host                                    Path  Backends
  ----                                    ----  --------
  k8s50-master.eastus.cloudapp.azure.com  
                                          /default   nginx-deployment:80 (10.244.152.118:80,10.244.152.119:80)
  
Annotations:                              cert-manager.io/cluster-issuer: selfsigned-issuer-test
                                          konghq.com/strip-path: true
Events:                                   <none>
```

9. verify 
```bash
curl -I -k https://$nodename/default

```
both shall return 200 OK with response from nginx server 


10. verify with not configured path 

```bash
curl -k https://$nodename/
```
expected result
```
{
  "message":"no Route matched with those values"
}
```
 this is because in ingress rule, we did not config path "/". therefore, ingress controller will complain there is no Route match.

now let's create another path but point to a different service. 


11. create Kubernetes-bootcamp deployment and service

```bash
cat << EOF | tee kubernetes-bootcamp.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kubernetes-bootcamp
spec:
  replicas: 1 # Default value for replicas when not specified
  selector:
    matchLabels:
      app: kubernetes-bootcamp
  template:
    metadata:
      labels:
        app: kubernetes-bootcamp
    spec:
      containers:
      - name: kubernetes-bootcamp
        image: gcr.io/google-samples/kubernetes-bootcamp:v1
EOF
kubectl create -f kubernetes-bootcamp.yaml

cat << EOF | tee kubernetes-bootcamp-clusterip.yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: kubernetes-bootcamp
  name: kubernetes-bootcamp-deployment
  namespace: default
spec:
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - port: 80
    protocol: TCP
    targetPort: 8080
  selector:
    app: kubernetes-bootcamp
  sessionAffinity: None
  type: ClusterIP
EOF

kubectl create -f kubernetes-bootcamp-clusterip.yaml
```
12. update the ingress rule 

also add a new rule with path configured to /bootcamp with backendservice set to kubernetes-bootcamp-deployment

```bash
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
cd $HOME
cat <<EOF  |  tee nginx_ingress_rule_with_cert_${nodename}_two_svc.yaml
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
    - ${nodename}
  ingressClassName: kong
  rules:
  - host: ${nodename}
    http:
      paths:
      - path: /default
        pathType: ImplementationSpecific
        backend:
          service:
            name: nginx-deployment
            port:
              number: 80
  - host: ${nodename}
    http:
      paths:
      - path: /bootcamp
        pathType: ImplementationSpecific
        backend:
          service:
            name: kubernetes-bootcamp-deployment
            port:
              number: 80
EOF
kubectl apply -f nginx_ingress_rule_with_cert_${nodename}_two_svc.yaml
```


13. Verify ingress rule with 
```bash
curl http://${nodename}/bootcamp
curl http://${nodename}/default
```
or 
```bash
curl -k https://${nodename}/bootcamp
curl -k https://${nodename}/default 
```
Expected result

```
curl -k https://${nodename}/default
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5485cc6795-zcstb | v=1
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>

```

### Review Questions
- Create juice-shop with v15.0.0 deployment and ClusterIP svc
- Create juice-shop with v16.0.0 deployment and ClusterIP svc
- Create https ingress rule with path /v15 point to v15.0.0 deployment
- Create https ingress rule with path /v16 point to v16.0.0 deployment


### clean up

```bash
kubectl delete ingress nginx
kubectl delete svc nginx-deployment 
kubectl delete svc kubernetes-bootcamp-deployment
kubectl delete deployment nginx-deployment
kubectl delete deployment kubernetes-bootcamp
```

you can also remove  below if you no longer need loadbalancer , ingress controller and cert-manager. 

```bash
kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
kubectl delete -f https://raw.githubusercontent.com/Kong/kubernetes-ingress-controller/v2.10.0/deploy/single/all-in-one-dbless.yaml
kubectl delete -f https://github.com/jetstack/cert-manager/releases/download/v1.3.1/cert-manager.yaml
```