---
title: "Task 2 - Basic Concepts of Kubernetes"
menuTitle: "Basic Concepts of Kubernetes"
chapter: false
weight: 2
---

### Objective
Learn the basic building blocks of Kubernetes.

## Description

Dive into the foundational concepts of Kubernetes, including Pods, ReplicaSets, Deployments, Services, and Namespaces. Understand the lifecycle of a Pod and how Kubernetes manages application deployment and scaling.

### Let’s Start with Deploying an Application on Your Cluster

Once you have a running Kubernetes cluster, you can deploy your containerized applications on top of it. To do this, you create a Kubernetes Deployment.

A **Deployment** instructs Kubernetes on how to create and update instances of your application. After creating a Deployment, the Kubernetes control plane schedules the application instances included in that Deployment to run on individual nodes in the cluster.

Once the application instances are created, a Kubernetes Deployment controller continuously monitors those instances. If the node hosting an instance goes down or is deleted, the Deployment controller replaces the instance with an instance on another node in the cluster. This mechanism provides self-healing to address machine failure or maintenance.

We use the kubectl command to create deployments in Kubernetes. kubectl relies on a configuration file found at ~/.kube/config for authentication and communication with the kube-api-server. Running `kubectl config view` displays details about the kube-API server, including its address, name, and the client's key and certificate.

To use kubectl from your personal client machine, you need to copy the ~/.kube/config file from the server to your client machine. Additionally, ensure your client machine can connect to the kube-API server's address. It's also important for the kube-API server to recognize your client's IP address as a trusted source by adding it to a whitelist. This setup ensures secure communication between your client machine and the Kubernetes cluster's control plane.

We have configured the master node's Ubuntu VM to also serve as a client node for accessing the Kubernetes cluster. Therefore, once you SSH into the master node VM, you can directly use kubectl for cluster management and operations.


- **kubectl** 

The common format of a kubectl command is: **kubectl action resource**

This performs the specified action (like create, describe or delete) on the specified resource (like node or deployment). You can use --help after the subcommand to get additional info about possible parameters (for example: kubectl get nodes --help).

Check that kubectl is configured to talk to your cluster, by running the `kubectl version` command.

Check that kubectl is installed and you can see both the client and the server versions.

To view the nodes in the cluster, run the `kubectl get nodes` command.

You see the available nodes. Later, Kubernetes will choose where to deploy our application based on Node available resources.


### Deploying an Application with a Deployment

Deploy your first application on Kubernetes using the `kubectl create deployment` command. This requires specifying the deployment name and the location of the application image (including the full repository URL for images not hosted on Docker Hub).

```bash
kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1

```

Congratulations! You've just deployed your first application by creating a deployment. This process automates several steps:

Identifies a suitable node where the application instance can be run (assuming there's only one available node in this scenario).
Schedules the application to run on that chosen node.
Ensures the cluster is configured to reschedule the instance to a new node if necessary.

To view your deployments, use the kubectl get deployments command:
```bash
kubectl get deployment -l app=kubernetes-bootcamp
```

We see that there is 1 deployment running a single instance of your app. The instance is running inside a POD which include container on your node.

```
$ kubectl get deployment -l app=kubernetes-bootcamp
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   1/1     1            1           20m
```
In this output:

**kubernetes-bootcamp** is the name of the deployment managing your application.
**READY 1/1** indicates that there is one pod targeted by the deployment, and it is ready.

A **Pod** in Kubernetes is a group of one or more containers that share the same network and storage. These containers are deployed together on the same host machine.


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

scale down deployment from 10 replicas to 1 just need 
```bash
kubectl scale deployment kubernetes-bootcamp --replicas=1
```

### What is POD

A Pod in Kubernetes is like a single instance of an application. It can hold closely related containers that work together. All containers in a Pod share the same IP address and ports, and they are always placed together on the same server (Node) in the cluster. This setup means they can easily communicate with each other.  Pods provide the environment in which containers run and offer a way to logically group containers together.

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

 A Node in Kubernetes is where a Pod gets to run. Think of a Node as a worker machine that could be either a virtual machine or a physical one, depending on how the cluster is set up. These Nodes are overseen by the cluster's control plane, which ensures everything runs smoothly.

Each Node can host multiple Pods. It's up to the control plane to smartly schedule these Pods across the Nodes, making sure that each Node's resources (like CPU and memory) are used efficiently.

There are a couple of key components you'll find running on every Kubernetes Node:

Kubelet: This is the main guy talking to both the Node it's on and the control plane. It looks after the Pods and containers on the Node, making sure they're running as they should.
Container Runtime: This is what actually runs your containers. It pulls the container images from where they're stored, unpacks them, and gets your application up and running. Docker and CRI-O are examples of container runtimes used in Kubernetes environments.
So, in short, a Node is the workhorse of a Kubernetes cluster, providing the necessary environment for your applications (in containers) to run. The control plane keeps an eye on the resources and health of each Node to ensure the cluster operates efficiently.

![Alt text for the image](https://kubernetes.io/docs/tutorials/kubernetes-basics/public/images/module_03_nodes.svg)


we can use `kubectl get node -o wide` to check the node status in cluster.

```bash
ubuntu@ubuntu22:~$ kubectl get node -o wide
NAME        STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
ubuntu22    Ready    control-plane   55m   v1.26.1   10.0.0.4      <none>        Ubuntu 22.04.3 LTS   6.2.0-1019-azure   cri-o://1.25.4
worker001   Ready    <none>          54m   v1.26.1   10.0.0.5      <none>        Ubuntu 22.04.3 LTS   6.2.0-1019-azure   cri-o://1.25.4
```

Nodes in Kubernetes can be made unschedulable using the kubectl cordon <nodename> command, which is particularly useful when preparing a node for maintenance. When a node is cordoned, the kube-scheduler will no longer schedule new pods onto it, although existing pods on the node are not affected.

By default, Kubernetes master nodes are tainted to prevent workloads from being scheduled on them. This is a security and resource management measure designed to keep master nodes dedicated to managing the cluster. However, there might be scenarios, such as in a single-node cluster or for development purposes, where you might need to schedule pods on the master node.

To enable pod scheduling on the master node, the taint that blocks pod scheduling must be removed. This can be achieved with the kubectl taint command:


```bash
kubectl taint nodes ubuntu22 node-role.kubernetes.io/control-plane-
```
This command removes the control-plane taint from the node named ubuntu22, thus allowing it to schedule pods like any other node in the cluster. This action is especially relevant for Kubernetes versions 1.17 and later, where the control plane components are marked with node-role.kubernetes.io/control-plane, in addition to, or instead of, node-role.kubernetes.io/master.

To verify that the taint has been successfully removed, you can inspect the taints on the master node: 
```bash
ubuntu@ubuntu22:~$ kubectl describe node ubuntu22 | grep Taints
Taints:             <none>
```
If the taint has been removed successfully, you will see Taints: <none> in the output.

To reapply the taint and make the master node unschedulable by the kube-scheduler again, use `kubectl taint nodes ubuntu22 node-role.kubernetes.io/control-plane:NoSchedule`  This command adds the NoSchedule taint back to the node ubuntu22, preventing new pods from being scheduled on it, while not affecting already running pods. This step is useful for reverting the master node back to a dedicated control plane node after maintenance or development activities are complete.




### What is ReplicaSet 

A ReplicaSet is a Kubernetes resource that ensures a specified number of replicas of a pod are running at any given time. It is one of the key controllers used for pod replication and management, offering both scalability and fault tolerance for applications. The primary purpose of a ReplicaSet is to maintain a stable set of replica Pods running at any given time. As such, it is often used to guarantee the availability of a specified number of identical Pods.

**Deployment** is a higher-level resource in Kubernetes that actually manages ReplicaSets and provides declarative updates to applications. 

use below command to check the ReplicaSet (rs) that created when using Deployment to scale the application.

```bash
kubectl get rs kubernetes-bootcamp
kubectl describe rs kubernetes-bootcamp
```
from the output , we can found a line that saying "Controlled By:  Deployment/kubernetes-bootcamp" 

### What is namespace

A namespace in Kubernetes is like a folder that helps you organize and separate your cluster's resources (like applications, services, and pods) into distinct groups. It's useful for managing different projects, environments (such as development, staging, and production), or teams within the same Kubernetes cluster. Namespaces help avoid conflicts between names and make it easier to apply policies, limits, and permissions on a per-group basis

Understand the default namespace
By default, a Kubernetes cluster will instantiate a default namespace when provisioning the cluster to hold the default set of Pods, Services, and Deployments used by the cluster.

`kubectl get deployment kubernetes-bootcamp -n default` is same as `kubectl get deployment kubernetes-bootcamp`.

we can use `kubectl create namespace` to create different namespace name. below we create two new deployment in two different namespace. 

Let's imagine a scenario where an organization is using a shared Kubernetes cluster for development and production use cases.

The development team would like to maintain a space in the cluster where they can get a view on the list of Pods, Services, and Deployments they use to build and run their application. In this space, Kubernetes resources come and go, and the restrictions on who can or cannot modify resources are relaxed to enable agile development.

The operations team would like to maintain a space in the cluster where they can enforce strict procedures on who can or cannot manipulate the set of Pods, Services, and Deployments that run the production site.

One pattern this organization could follow is to partition the Kubernetes cluster into two namespaces: development and production.

```bash
# Create namespaces
kubectl create namespace production
kubectl create namespace development

# Create the kubernetes-bootcamp deployment in production
kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1 --namespace=production

# Create the kubernetes-bootcamp deployment in developement
kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1 --namespace=development

kubectl get pod --namespace=production 
kubectl get pod -n=development
```
use `kubectl delete namespace production` and `kubectl delete namespace development` will delete both namespace and everything in that namespace.


### What is Service

A Kubernetes Service is a way to expose an application running on a set of Pods as a network service. It abstracts the details of the pod's IP addresses from consumers, providing a single point of access for a set of pods, typically to ensure that network traffic can be directed to them even as they are created or destroyed. This is crucial for maintaining consistent access to the functionalities these pods provide. 

Services primarily operate at the transport layer (Layer 4 of the OSI model), dealing with IP addresses and ports. They provide a way to access pods within the cluster and, in the case of NodePort and LoadBalancer, expose them externally.



Major Types of Kubernetes Services:
ClusterIP: This is the default service type that exposes the service on an internal IP within the cluster, making the service reachable only from within the cluster.

To check the services in your Kubernetes cluster, you can use the following command:

use `kubectl get svc` to check service 
```bash
kubectl get svc
```
With a default Kubernetes installation, you should see something similar to the following:
```bash
ubuntu@ubuntu22:~$ k get svc --show-labels
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE   LABELS
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   49m   component=apiserver,provider=kubernetes
```

This output shows the built-in kubernetes service, which serves as the internal endpoint for the Kubernetes API service. The ClusterIP 10.96.0.1 assigned to services like the Kubernetes API server (kubernetes service) is a virtual IP (VIP) and does not correspond to a physical network interface. It is part of Kubernetes' service discovery and networking mechanism, which relies on kube-proxy (running on each node) and the cluster's network configuration to route traffic to the appropriate endpoints.

The ClusterIP is only accessible from within the cluster, which means it cannot be directly accessed from the master node using kubectl. To interact with it, one must use another pod within the same cluster.

Below, we launch a pod (container) using the curl command to access the HTTPS port on 10.96.0.1. Receiving a 403 Forbidden response indicates that connectivity is working fine, but the request is not authorized. This lack of authorization occurs because curl did not supply a certificate to authenticate itself:



```bash
ubuntu@ubuntu22:~$ kubectl run curlpod --image=appropriate/curl --restart=Never --rm -it --  curl -I -k https://10.96.0.1
```

Expected output:
```bash
HTTP/1.1 403 Forbidden
```
"403" is because curl need to supply a certificate to authenticate itself which we did not supply, however, above is enough to show you the 10.96.0.1 is reachable. 

kube-proxy manages traffic from within the cluster to the actual Kubernetes API endpoint using iptables rules, such as:

```bash
sudo iptables-save  | grep 10.96.0.1/32
-A KUBE-SERVICES -d 10.96.0.1/32 -p tcp -m comment --comment "default/kubernetes:https cluster IP" -j KUBE-SVC-NPX46M4PTMTKRN6Y
-A KUBE-SVC-NPX46M4PTMTKRN6Y ! -s 10.244.0.0/16 -d 10.96.0.1/32 -p tcp -m comment --comment "default/kubernetes:https cluster IP" -j KUBE-MARK-MASQ

```
To check the endpoint for the Kubernetes API service, use: 
This command reveals the underlying endpoint that the kubernetes service directs traffic to:

```bash
use `ubuntu@ubuntu22:~$ k get ep 
NAME         ENDPOINTS       AGE
kubernetes   10.0.0.4:6443   56m`
```



### Exploring the Kubernetes Default ClusterIP type Service: kube-dns

Kubernetes includes several built-in services essential for its operation  , with `kube-dns` being a key component. The `kube-dns` service is responsible for DNS resolution within the Kubernetes cluster, allowing pods to resolve the IP addresses of other services and external domains.

#### Major Types of Kubernetes Services:

- **ClusterIP**: The default service type that exposes the service on an internal IP within the cluster. This type is used for `kube-dns`, making it accessible only from within the cluster.

To check the services in your Kubernetes cluster, including `kube-dns`, use the following command:

```bash
kubectl get svc --namespace=kube-system
```
You should see kube-dns listed among the services, typically with a ClusterIP type, indicating it's internally accessible within the cluster.

Verifying DNS Resolution with kube-dns
To verify that kube-dns is correctly resolving domain names within the cluster, you can perform a DNS lookup from a pod. Here’s how to launch a temporary pod for testing DNS resolution using the busybox image:
```bash
kubectl run dns-test --image=busybox --restart=Never --rm -it -- nslookup  kubernetes.default.svc.cluster.local
```


and 
```bash
kubectl run dns-test --image=busybox --restart=Never --rm -it -- nslookup  www.google.com
```

This command does the following:

Launches a temporary pod named dns-test using the busybox image.
Executes the nslookup command to resolve the domain name kubernetes.default.svc.cluster.local, which should be the internal DNS name for the Kubernetes API server.
Automatically removes the pod after the command execution (--rm flag).

Expected Output
If kube-dns is functioning correctly, you should see output similar to the following, indicating the IP address that kubernetes.default resolves to:

```bash
Server:         10.96.0.10
Address:        10.96.0.10:53


Name:   kubernetes.default.svc.cluster.local
Address: 10.96.0.1

and
Server:         10.96.0.10
Address:        10.96.0.10:53

Non-authoritative answer:
Name:   www.google.com
Address: 142.250.189.164

Non-authoritative answer:
Name:   www.google.com
Address: 2607:f8b0:4005:802::2004


```

The kube-dns service is vital for internal name resolution in Kubernetes, enabling pods to communicate with each other and access various cluster services using DNS names. Verifying DNS resolution functionality with kube-dns is straightforward with a temporary pod and can help diagnose connectivity issues within the cluster.


NodePort: Exposes the Service on the same port of each selected node in the cluster using NAT. It makes the Service accessible from outside the cluster by <NodeIP>:<NodePort>. 

LoadBalancer: Exposes the Service externally using a cloud provider’s load balancer. It assigns a fixed, external IP address to the Service.


### Use Label

Labels in Kubernetes are key/value pairs attached to objects, such as Pods, Services, and Deployments. They serve to organize, select, and group objects in ways meaningful to users, allowing the mapping of organizational structures onto system objects in a loosely coupled fashion without necessitating clients to store these mappings.

Labels can be utilized to filter resources when using kubectl commands. For example, executing `kubectl get pods -l app=kubernetes-bootcamp` retrieves all Pods labeled with app=kubernetes-bootcamp.

Many kubectl commands include the option `--show-labels`` to display the labels attached to objects. This can be used with various resource types, such as nodes, pods, services, and deployments, through commands like `kubectl get nodes --show-labels``, `kubectl get pods --show-labels``, `kubectl get svc --show-labels``, and `kubectl get deployments --show-labels``.

Labels can be added to an object using the `kubectl label`` command. For instance, executing `kubectl label deployment nginx stage=development`` will add the key:value pair stage=development to the deployment named nginx.




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


### kube-API

Kubernetes is fundamentally built around APIs that adhere to the OpenAPI specification, defining resources and their operations. Based on API input, Kubernetes creates objects and stores them in the etcd database. Let's explore using the Kubernetes API to create a Pod, utilizing the kubectl api-resources and kubectl explain commands for guidance. 

- Finding the API Resource for Pods


First, identify the API resource needed to create a Pod. You can list all API resources with `kubectl api-resources``:

This command filters the list of API resources to show only those related to Pods. The output will look something like this:

```bash
ubuntu@ubuntu22:~$ kubectl  api-resources | head  -n 1
NAME 
NAME                              SHORTNAMES                                      APIVERSION                             NAMESPACED   KIND
ubuntu@ubuntu22:~$ kubectl  api-resources | grep pods
pods                              po                                              v1                                     true         Pod
pods                                                                              metrics.k8s.io/v1beta1                 true         PodMetrics
```

From the output, we see that the "KIND" for Pods is "Pod", and the API version is v1.


- Understanding Pod Specifications

Next, use kubectl explain to understand how to structure a YAML definition for a Pod specification. Execute the following commands to explore the Pod resource specifications:

kubectl explain Pod
kubectl explain Pod.apiVersion
kubectl explain Pod.kind
kubectl explain Pod.metadata

- Crafting a Minimal YAML Definition for a Pod 

Now, we can construct a minimal YAML file to create a Pod. The essential elements include the Pod's name and the container image:


```bash
cat << EOF | sudo tee minimalyamlforpod.yaml 
apiVersion: v1
kind: Pod
metadata: 
  name: test-pod 
spec:
  containers: 
    - name: nginx
      image: nginx
EOF
```
To understand the format for containers, use kubectl explain pod.spec.containers. This field accepts a list, indicating that a Pod can contain multiple containers. Further exploration with kubectl explain pod.spec.containers.image reveals that the image field expects a string.

- Creating the Pod

With the YAML file ready, create the Pod using:
```bash
kubectl create -f minimalyamlforpod.yaml
```

Verifying Pod Creation

To see the details of the created Pod, including any default values Kubernetes applied during creation, use:
```bash
kubectl get pod test-pod -o yaml
```

This command outputs the complete configuration of the Pod, test-pod, showing all properties set by Kubernetes, many of which use default values that you can customize in the Pod YAML definition.





### Challenge

- Task 1 

Try to use curl command instead `kubectl` to get namespace for cluster. you have to give client key and certificate to authenticate to kube-API server.

Answer

```bash
sudo snap install yq
cat ~/.kube/config | yq .users[0].user.client-certificate-data | base64 -d > k8sadmin.crt
cat ~/.kube/config | yq .users[0].user.client-key-data | base64 -d > k8sadmin.key

SERVER="10.0.0.4"
curl --key k8sadmin.key --cert k8sadmin.crt https://$SERVER:6443/api/v1/pods --insecure -s -w "\n" |
  jq -r '.items[] | "\(.metadata.namespace)\t\(.metadata.name)\t\(.status.containerStatuses[0].ready)\t\(.status.phase)\t\(.status.containerStatuses[0].restartCount)\t\(.spec.containers|length)"' |
  column -t -s $'\t'

```

- Task 2
 
Use `kubectl` to find minial API specifction for create a namespace. 

Answer 

```bash

```

- Task 3 

Use `kubectl` to find the specifcation for imagePullPolicy which is need for create a POD. answer which kubectl cli and answer what is the imagePullPolicy avaiable to choose. 
Answer 

```bash
kubectl explain Pod.spec.containers.imagePullPolicy
```
Answer 
```bash
Always, Never, IfNotPresent
```






