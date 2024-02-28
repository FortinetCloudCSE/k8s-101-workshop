---
title: " K8S Node and Service"
menuTitle: "Node and Service"
weight: 3
---

### Node

Kubernetes runs your workload by placing containers into Pods to run on **Nodes**. A node may be a virtual or physical machine, depending on the cluster. Each node is managed by the control plane and contains the services necessary to run Pods.

In Self Managed kubernets, a Node include kubernetes master node and worker node, while In Azure Kubernetes Service (AKS), the term "Node" typically refers to what is known in Kubernetes terminology as a "worker node." These are the virtual machines (VMs) or physical machines that run your containerized applications and services. In AKS, the control plane (master nodes) is managed by Azure and abstracted from the user, providing a simplified user experience and reducing the operational overhead for cluster management. Unlike with self-managed Kubernetes clusters, you do not have direct access to the control plane VMs or their configurations in AKS. This means you cannot directly log into the control plane nodes or run commands on them as you might with worker nodes.

Typically you have several nodes in a cluster, in a learning or resource-limited environment, you might have only one node. In this AKS deployment, There is only one single worker node exist. 


The components on a worker node include the **kubelet**, a **container runtime**, and the **kube-proxy**. 

**Kubelet**: This is the main guy talking to both the Node it's on and the control plane. It looks after the Pods and containers on the Node, making sure they're running as they should.
**Container Runtime**: This is what actually runs your containers. It pulls the container images from where they're stored, unpacks them, and gets your application up and running. Docker and CRI-O are examples of container runtimes used in Kubernetes environments.
**kube-proxy**: This is essential for the operation of Kubernetes services, allowing Pods to communicate with each other and with the outside world. It enables services to be exposed to the external network, load balances traffic across Pods, and is crucial for the overall networking functionality in Kubernetes.


So, in short, a Worker Node is the workhorse of a Kubernetes cluster, providing the necessary environment for your applications (in containers) to run. The control plane or master node keeps an eye on the resources and health of each Node to ensure the cluster operates efficiently.

![Alt text for the image](https://kubernetes.io/docs/tutorials/kubernetes-basics/public/images/module_03_nodes.svg)


we can use `kubectl get node -o wide` to check the node status in cluster.

```bash
kubectl get node -o wide
```
expected outcome:
on self-managed kubernetes 
```
NAME        STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
nodemaster    Ready    control-plane   55m   v1.26.1   10.0.0.4      <none>        Ubuntu 22.04.3 LTS   6.2.0-1019-azure   cri-o://1.25.4
node-worker   Ready    <none>          54m   v1.26.1   10.0.0.5      <none>        Ubuntu 22.04.3 LTS   6.2.0-1019-azure   cri-o://1.25.4
```
on managed kubernetes like AKS

```
NAME                             STATUS   ROLES   AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
aks-worker-24706581-vmss000000   Ready    agent   7m32s   v1.27.9   10.224.0.4    <none>        Ubuntu 22.04.3 LTS   5.15.0-1054-azure   containerd://1.7.7-1
```

Nodes in Kubernetes can be made unschedulable using the `kubectl cordon <nodename>` command, which is particularly useful when preparing a node for maintenance. When a node is cordoned, the kube-scheduler will no longer schedule new pods onto it, although existing pods on the node are not affected.


use `kubectl uncordon <nodename>` to put worker node back to work. 



### What is Service

A Kubernetes Service is a way to expose an application running on a set of Pods as a network service. It abstracts the details of the pod's IP addresses from consumers, providing a single point of access for a set of pods, typically to ensure that network traffic can be directed to them even as they are created or destroyed. This is crucial for maintaining consistent access to the functionalities these pods provide. 

Services primarily operate at the transport layer (Layer 4 of the OSI model), dealing with IP addresses and ports. They provide a way to access pods within the cluster and, in the case of NodePort and LoadBalancer, expose them externally.


####  Major Types of Kubernetes Services:

- **ClusterIP** to expose service to cluster internal

This is the default service type that exposes the service on an internal IP within the cluster, making the service reachable only from within the cluster.

![clusterIP svc ](https://learn.microsoft.com/en-us/azure/aks/media/concepts-network/aks-clusterip.png)
 

To check the services in your Kubernetes cluster, you can use the following command:

use `kubectl get svc` to check service 
```bash
kubectl get svc --show-labels
```
expected output 
```bash
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE   LABELS
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   49m   component=apiserver,provider=kubernetes
```

This output shows the built-in kubernetes service, which serves as the internal endpoint for the Kubernetes API service. The ClusterIP 10.96.0.1 assigned to services like the Kubernetes API server (kubernetes service) is a virtual IP (VIP) and does not correspond to a physical network interface. It is part of Kubernetes' service discovery and networking mechanism, which relies on kube-proxy (running on each node) and the cluster's network configuration to route traffic to the appropriate endpoints.

The ClusterIP is only accessible from within the cluster, which means it cannot be directly accessed from the master node using kubectl. To interact with it, one must use another pod within the same cluster.

- kubernetes API clusterIP service 

Below, we launch a pod using the curl command to access the HTTPS port on 10.96.0.1 which is kubernetes API.  Receiving either 401 or 403  response indicates that connectivity is working fine, but the request is not authorized. This lack of authorization occurs because curl did not supply a certificate to authenticate itself:


```bash
kubectl run curlpod --image=appropriate/curl --restart=Never --rm -it --  curl -I -k https://10.96.0.1/
```

Expected output:
```bash
HTTP/1.1 401 Unauthorized
```
or 
```bash
HTTP/1.1 403 Forbidden
```

"401" or "403" is because curl need to supply a certificate to authenticate itself which we did not supply, however, above is enough to show you the 10.96.0.1 is reachable via clusterIP Service.

 

- Exploring the Kubernetes Default ClusterIP type Service: kube-dns

Kubernetes includes several built-in services essential for its operation  , with **kube-dns** being a key component. The **kube-dns** service is responsible for DNS resolution within the Kubernetes cluster, allowing pods to resolve the IP addresses of other services and external domains.

![clusterIP svc ](https://www.tigera.io/app/uploads/2023/05/image13-1.png)

*In this workshop, the kube-dns svc has configured with ip 10.96.0.10 instead of 10.0.0.10*

To check the kube-dns services in your Kubernetes cluster namespace kube-system , use 

```bash
kubectl get svc --namespace=kube-system -l k8s-app=kube-dns
```

You should see kube-dns listed among the services, typically with a ClusterIP type, indicating it's internally accessible within the cluster.

Verifying DNS Resolution with kube-dns
To verify that kube-dns is correctly resolving domain names within the cluster, you can perform a DNS lookup from a pod. Here’s how to launch a temporary pod for testing DNS resolution using the busybox image, the FQDN name for kubernetes service is in format "svcname.namespace.svc.cluster.local". kube-dns service help how to solve cluster internal and external FQDN to IP address.

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

- **NodePort**:  expose service to cluster external 


Exposes the service externally on the same port of each selected node in the cluster via NAT. Accessible by NodeIP:NodePort within the range 30000-32767.

![nodePort svc ](https://learn.microsoft.com/en-us/azure/aks/media/concepts-network/aks-nodeport.png) 




- **LoadBalancer**: expose service to cluster external 

Exposes the service externally using a cloud provider's load balancer or an on-premise solution like MetalLB, assigning a fixed, external IP to the service."

![LoadBalancer svc ](https://learn.microsoft.com/en-us/azure/aks/media/concepts-network/aks-loadbalancer.png)


### Summary


Worker nodes host your pods. A ClusterIP service enables internal cluster access to these pods, while NodePort and LoadBalancer services provide external access.

You have sucessfully bring up a managed kubernetes (AKS) and walked throught the concept of POD, Deployment, Replicas, Namespace, Label, Node, different type of services etc in kubernetes. We will continue to install a self-managed kubernets to continue our jourey.




### clean up

{{< notice warning >}}  


Do not forget to remove your AKS cluster. We will use self-managed k8s for hands-on activites.

 {{< /notice >}} 
delete your aks cluster with below command, this will took around 5 minutes.


```bash
clustername=$(whoami)
resourcegroupname=$(az group list --tag FortiLab="k8s101-lab" | jq -r .[].name)
az aks delete --name ${clustername} -g $resourcegroupname  -y
```


### Review Questions

- What is the role of a worker node in Kubernetes, and what are three key components that run on every Kubernetes Worker Node?
- What is a Kubernetes Service, and why is it important?
- Describe the difference between ClusterIP, NodePort, and LoadBalancer Service types in Kubernetes.