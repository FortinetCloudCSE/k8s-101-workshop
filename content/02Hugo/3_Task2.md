---
title: "Task 2 - Basic Concepts of Kubernetes"
menuTitle: "Basic Concepts of Kubernetes"
chapter: false
weight: 2
---

### Objective: Learn the basic building blocks of Kubernetes.

Description: 

Dive into the foundational concepts of Kubernetes, including Pods, ReplicaSets, Deployments, Services, and Namespaces. Understand the lifecycle of a Pod and how Kubernetes manages application deployment and scaling.


Let's start with deploy an application on your cluster 

Once you have a running Kubernetes cluster, you can deploy your containerized applications on top of it. To do so, you create a Kubernetes **Deployment**.

The **Deployment** instructs Kubernetes how to create and update instances of your application. Once you've created a **Deployment**, the Kubernetes control plane schedules the application instances included in that Deployment to run on individual Nodes in the cluster.

Once the application instances are created, a Kubernetes Deployment controller continuously monitors those instances. If the Node hosting an instance goes down or is deleted, the Deployment controller replaces the instance with an instance on another Node in the cluster. This provides a self-healing mechanism to address machine failure or maintenance.

We use **kubectl** to do deployment. kubectl will use the configure file which under `~/kube/config` to authenticate iteself to interactive with kube-api-server. 


### kubectl basics
The common format of a kubectl command is: **kubectl action resource**

This performs the specified action (like create, describe or delete) on the specified resource (like node or deployment). You can use --help after the subcommand to get additional info about possible parameters (for example: kubectl get nodes --help).

Check that kubectl is configured to talk to your cluster, by running the `kubectl version` command.

Check that kubectl is installed and you can see both the client and the server versions.

To view the nodes in the cluster, run the `kubectl get nodes` command.

You see the available nodes. Later, Kubernetes will choose where to deploy our application based on Node available resources.


### Deploy an app

Let’s deploy our first app on Kubernetes with the kubectl create deployment command. We need to provide the deployment name and app image location (include the full repository url for images hosted outside Docker Hub).

```bash
kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1
```

`Great! You just deployed your first application by creating a deployment. This performed a few things for you:

searched for a suitable node where an instance of the application could be run (we have only 1 available node)
scheduled the application to run on that Node
configured the cluster to reschedule the instance on a new Node when needed
To list your deployments use the `kubectl get deployments kubernetes-bootcamp` command

We see that there is 1 deployment running a single instance of your app. The instance is running inside a container on your node.

```
$ kubectl get deployment -l app=kubernetes-bootcamp
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   1/1     1            1           20m
```
**kubernetes-bootcamp** is the name of deployment for your application
**READY 1/1**  mean  there is one **POD** targeted by the deployment, and it is ready

the **POD** is the group of your containers which share common storage and network. 

### What is Deployment

We have just used deployment to deploy the application , so what is Deployment ?
A Deployment in Kubernetes is like a manager for your apps running in containers, a Deployment in Kubernetes manages a set of replicas of your application, ensuring they are running and updating them in a controlled way. It makes managing and scaling your applications easier, handling the details of how many instances should run and how updates to those instances are rolled out.  for example, we can use kubectl to scale your POD from 1 to 10 to server more users.
```bash
kubectl scale deployment kubernetes-bootcamp --replicas=10
```
use `kubectl get pod` to check the pod now become 10.

```bash
kubectl get pod
```

### What is POD

A Pod models an application-specific "logical host" and can contain different application containers which are relatively tightly coupled. The containers in a Pod share an IP Address and port space, are always co-located and co-scheduled, and run in a shared context on the same Node. POD is the smallest unit in Kubernetes, not the container. 

We can use `kubectl get pod` to list the pod, use `-l` to select which pod to list.
**app=kubernetes-bootcamp** is the label assigned to pod during creating.

```bash
kubectl get pod -l app=kubernetes-bootcamp -o wide
```
we shall got output 
```bash
ubuntu@ubuntu22:~$ k get pod -o wide -l app=kubernetes-bootcamp
NAME                                  READY   STATUS    RESTARTS   AGE   IP              NODE         
kubernetes-bootcamp-bcbb7fc75-5r649   1/1     Running   0          73s   10.244.222.16   worker001    

```

Above output is from the kubectl get pod -o wide -l app=kubernetes-bootcamp command, which requests Kubernetes to list pods with additional information (wide output) that match the label app=kubernetes-bootcamp. Here's a breakdown of the output:

NAME: kubernetes-bootcamp-bcbb7fc75-5r649 - This is the name of the pod. Kubernetes generates pod names automatically based on the deployment name and a unique identifier to ensure each pod within a namespace has a unique name.

READY: 1/1 - This indicates the readiness state of the pod. It means that 1 out of 1 container within the pod is ready. Readiness is determined by readiness probes, which are used to know when a container is ready to start accepting traffic.

STATUS: Running - This status indicates that the pod is currently running without issues.

RESTARTS: 0 - This shows the number of times the containers within the pod have been restarted. A restart usually occurs if the container exits with an error or is killed for some other reason. In this case, 0 restarts indicate that the pod has been stable since its creation.

AGE: 73s - This shows how long the pod has been running. In this case, the pod has been up for 73 seconds.

IP: 10.244.222.16 - This is the internal IP address assigned to the pod within the Kubernetes cluster network. This IP is used for communication between pods within the cluster.

NODE: worker001 - This indicates the name of the node (physical or virtual machine) within the Kubernetes cluster on which this pod is running. The scheduler decides the placement of pods based on various factors like resources, affinity/anti-affinity rules, etc. In this case, the pod is running on a node named worker001.
Below diagram show a POD can have 1 container or multiple container, with or without shared storage. 

all the containers within a single Pod in Kubernetes follow  "shared fate" principle. This means that containers in a Pod are scheduled on the same node (physical or virtual machine) and share the same lifecycle, network namespace, IP address, and storage volumes. 

![Alt text for the image](https://kubernetes.io/docs/tutorials/kubernetes-basics/public/images/module_03_pods.svg)


 ### Node

 A Pod always runs on a Node. A Node is a worker machine in Kubernetes and may be either a virtual or a physical machine, depending on the cluster. Each Node is managed by the control plane. A Node can have multiple pods, and the Kubernetes control plane automatically handles scheduling the pods across the Nodes in the cluster. The control plane's automatic scheduling takes into account the available resources on each Node.

Every Kubernetes Node runs at least:

Kubelet, a process responsible for communication between the Kubernetes control plane and the Node; it manages the Pods and the containers running on a machine.
A container runtime (like Docker or CRI-O) responsible for pulling the container image from a registry, unpacking the container, and running the application.

![Alt text for the image](https://kubernetes.io/docs/tutorials/kubernetes-basics/public/images/module_03_nodes.svg)


we can use `kubeclt get node -o wide` to check the node status in cluster.

```bash
ubuntu@ubuntu22:~$ kubectl get node -o wide
NAME        STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
ubuntu22    Ready    control-plane   55m   v1.26.1   10.0.0.4      <none>        Ubuntu 22.04.3 LTS   6.2.0-1019-azure   cri-o://1.25.4
worker001   Ready    <none>          54m   v1.26.1   10.0.0.5      <none>        Ubuntu 22.04.3 LTS   6.2.0-1019-azure   cri-o://1.25.4
```

### What is ReplicaSet 

A ReplicaSet is a Kubernetes resource that ensures a specified number of replicas of a pod are running at any given time. It is one of the key controllers used for pod replication and management, offering both scalability and fault tolerance for applications. The primary purpose of a ReplicaSet is to maintain a stable set of replica Pods running at any given time. As such, it is often used to guarantee the availability of a specified number of identical Pods.

**Deployment** is a higher-level resource in Kubernetes that actually manages ReplicaSets and provides declarative updates to applications. 

use below command to check the ReplicaSet (rs) that created when using Deployment to scale the application.

```bash
kubectl get rs kubernetes-bootcamp
kubectl describe rs kubernetes-bootcamp
```
from the output , we can found a line that saying "Controlled By:  Deployment/kubernetes-bootcamp" 

### What is Service

A Kubernetes Service is a way to expose an application running on a set of Pods as a network service. It abstracts the details of the pod's IP addresses from consumers, providing a single point of access for a set of pods, typically to ensure that network traffic can be directed to them even as they are created or destroyed. This is crucial for maintaining consistent access to the functionalities these pods provide. 

Services primarily operate at the transport layer (Layer 4 of the OSI model), dealing with IP addresses and ports. They provide a way to access pods within the cluster and, in the case of NodePort and LoadBalancer, expose them externally


Major Types of Kubernetes Services:
ClusterIP: The default type, it exposes the Service on an internal IP in the cluster, making the Service only reachable within the cluster.

NodePort: Exposes the Service on the same port of each selected node in the cluster using NAT. It makes the Service accessible from outside the cluster by <NodeIP>:<NodePort>.

LoadBalancer: Exposes the Service externally using a cloud provider’s load balancer. It assigns a fixed, external IP address to the Service.

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

We will cover more about ingress and ingress controller in <placehold>

### What is namespace

A namespace in Kubernetes is like a folder that helps you organize and separate your cluster's resources (like applications, services, and pods) into distinct groups. It's useful for managing different projects, environments (such as development, staging, and production), or teams within the same Kubernetes cluster. Namespaces help avoid conflicts between names and make it easier to apply policies, limits, and permissions on a per-group basis

Kubernetes come with a namespace with name "default", anything created without specify the namespace is place in namespace "default".
`kubectl get deployment kubernetes-bootcamp -n default` is same as `k get deployment kubernetes-bootcamp`.

we can use `kubectl create namespace` to create different namespace name. below we create two new deployment in two different namespace. 

```bash
# Create namespaces
kubectl create namespace namespace-a
kubectl create namespace namespace-b

# Create the kubernetes-bootcamp deployment in namespace-a
kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1 --namespace=namespace-a

# Create the kubernetes-bootcamp deployment in namespace-b
kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1 --namespace=namespace-b

kubectl get pod --namespace=namespace-a 
kubectl get pod -n=namespace-b
```
use `kubectl delete namespace namespace-a` and `kubectl delete namespace namespace-b` will delete both namespace and everything in that namespace.

### POD life-cycle 

The life cycle of a Kubernetes Pod involves several key stages from creation to termination. Here's a brief overview of these stages, illustrated with commands related to deploying a Pod using the `gcr.io/google-samples/kubernetes-bootcamp:v1` image:

1 **Pod Creation**

A Pod is created when you deploy it using a YAML file or directly via the kubectl command.

2 **Pending**
The Pod enters the Pending state as Kubernetes schedules the Pod on a node and the container image is being pulled from the registry.

3 **Running**
Once the image is pulled and the Pod is scheduled, it moves to the Running state. The Pod remains in this state until it is terminated or stopped for some reason.

4 **Succeeded/Failed**

A Pod reaches Succeeded if all of its containers exit without error and do not restart.
A Pod is marked as Failed if any of its containers exit with an error.

5 **CrashLoopBackOff**

This status indicates that a container in the Pod is failing to start properly and Kubernetes is repeatedly trying to restart it.

6 **Termination** 
Pods can be terminated gracefully by deleting them. Kubernetes first sends a SIGTERM signal to allow containers to shut down gracefully.

7 **Deletion**
The Pod's entry remains in the system for a period after termination, allowing you to inspect its status posthumously. Eventually, Kubernetes cleans it up automatically.

Through these stages, Kubernetes manages the application's lifecycle, ensuring that the desired state specified by the deployment configurations is maintained. Monitoring the Pod's lifecycle helps in managing and troubleshooting applications running on Kubernetes.

we can use `kubectl get pod` and `kbuectl describe pod` to check the detail state for a POD.










