---
title: "Task 3 - Node and Service"
menuTitle: "Task 3: Node and Service"
chapter: false
weight: 3
---

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
kubectl get node -o wide
```
```
kubectl get node -o wide
NAME        STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
ubuntu22    Ready    control-plane   55m   v1.26.1   10.0.0.4      <none>        Ubuntu 22.04.3 LTS   6.2.0-1019-azure   cri-o://1.25.4
worker001   Ready    <none>          54m   v1.26.1   10.0.0.5      <none>        Ubuntu 22.04.3 LTS   6.2.0-1019-azure   cri-o://1.25.4
```

Nodes in Kubernetes can be made unschedulable using the `kubectl cordon <nodename>` command, which is particularly useful when preparing a node for maintenance. When a node is cordoned, the kube-scheduler will no longer schedule new pods onto it, although existing pods on the node are not affected.
```bash
kubectl cordon worker001
```
you will expect to see output
```
ubuntu@ubuntu22:~$ kubectl get node
NAME        STATUS                     ROLES           AGE   VERSION
ubuntu22    Ready                      control-plane   15m   v1.26.1
worker001   Ready,SchedulingDisabled   <none>          13m   v1.26.1
```
use `kubectl uncordon` to put worker node back to work. 
```bash
kubectl uncordon worker001
```

check node again 
```bash
kubectl get node
```
you will expect to see output
```
ubuntu@ubuntu22:~$ kubectl get node
NAME        STATUS   ROLES           AGE   VERSION
ubuntu22    Ready    control-plane   19m   v1.26.1
worker001   Ready    <none>          17m   v1.26.1
```


By default, Kubernetes master nodes are tainted to prevent workloads from being scheduled on them. This is a security and resource management measure designed to keep master nodes dedicated to managing the cluster. However, there might be scenarios, such as in a single-node cluster or for development purposes, where you might need to schedule pods on the master node.

To enable pod scheduling on the master node, the taint that blocks pod scheduling must be removed. This can be achieved with the kubectl taint command:


```bash
kubectl taint nodes ubuntu22 node-role.kubernetes.io/control-plane-
```
This command removes the control-plane taint from the node named ubuntu22, thus allowing it to schedule pods like any other node in the cluster. This action is especially relevant for Kubernetes versions 1.17 and later, where the control plane components are marked with node-role.kubernetes.io/control-plane, in addition to, or instead of, node-role.kubernetes.io/master.

To verify that the taint has been successfully removed, you can inspect the taints on the master node: 
```bash
kubectl describe node ubuntu22 | grep Taints
```
expected result 
```
Taints:             <none>
```
If the taint has been removed successfully, you will see Taints: <none> in the output.



To reapply the taint and make the master node unschedulable by the kube-scheduler again, use 
```bash
kubectl taint nodes ubuntu22 node-role.kubernetes.io/control-plane:NoSchedule
```

This command adds the NoSchedule taint back to the node ubuntu22, preventing new pods from being scheduled on it, while not affecting already running pods. This step is useful for reverting the master node back to a dedicated control plane node after maintenance or development activities are complete.

check node again with `kubectl get node --show-labels` and `kubectl describe node ubuntu22 | grep Taints` 
shall see worker node removed from  "NoSchedule" , and Taints shall be "None".

```bash
kubectl get node --show-labels
```
expected result
```
NAME        STATUS   ROLES           AGE   VERSION   LABELS
ubuntu22    Ready    control-plane   22m   v1.26.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=ubuntu22,kubernetes.io/os=linux,node-role.kubernetes.io/control-plane=,node.kubernetes.io/exclude-from-external-load-balancers=
worker001   Ready    <none>          20m   v1.26.1   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=worker001,kubernetes.io/os=linux
```
and
```bash
kubectl describe node ubuntu22 | grep Taints
```
expected result 

```
Taints:             <none>
```

### What is Service

A Kubernetes Service is a way to expose an application running on a set of Pods as a network service. It abstracts the details of the pod's IP addresses from consumers, providing a single point of access for a set of pods, typically to ensure that network traffic can be directed to them even as they are created or destroyed. This is crucial for maintaining consistent access to the functionalities these pods provide. 

Services primarily operate at the transport layer (Layer 4 of the OSI model), dealing with IP addresses and ports. They provide a way to access pods within the cluster and, in the case of NodePort and LoadBalancer, expose them externally.


1. Major Types of Kubernetes Services:

**ClusterIP**: This is the default service type that exposes the service on an internal IP within the cluster, making the service reachable only from within the cluster.

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

Below, we launch a pod (container) using the curl command to access the HTTPS port on 10.96.0.1. Receiving a 403 Forbidden response indicates that connectivity is working fine, but the request is not authorized. This lack of authorization occurs because curl did not supply a certificate to authenticate itself:


```bash
kubectl run curlpod --image=appropriate/curl --restart=Never --rm -it --  curl -I -k https://10.96.0.1
```

Expected output:
```bash
HTTP/1.1 403 Forbidden
```
"403" is because curl need to supply a certificate to authenticate itself which we did not supply, however, above is enough to show you the 10.96.0.1 is reachable. 

kube-proxy manages traffic from within the cluster to the actual Kubernetes API endpoint using iptables rules, such as:

```bash
sudo iptables-save  | grep 10.96.0.1/32
```
expected output 

```bash
-A KUBE-SERVICES -d 10.96.0.1/32 -p tcp -m comment --comment "default/kubernetes:https cluster IP" -j KUBE-SVC-NPX46M4PTMTKRN6Y
-A KUBE-SVC-NPX46M4PTMTKRN6Y ! -s 10.244.0.0/16 -d 10.96.0.1/32 -p tcp -m comment --comment "default/kubernetes:https cluster IP" -j KUBE-MARK-MASQ

```
To check the endpoint for the Kubernetes API service, use: 
This command reveals the underlying endpoint that the kubernetes service directs traffic to:

```bash
kubectl get ep
```
expected output 
```bash
NAME         ENDPOINTS       AGE
kubernetes   10.0.0.4:6443   56m`
```

Exploring the Kubernetes Default ClusterIP type Service: kube-dns

Kubernetes includes several built-in services essential for its operation  , with **kube-dns** being a key component. The **kube-dns** service is responsible for DNS resolution within the Kubernetes cluster, allowing pods to resolve the IP addresses of other services and external domains.


To check the kube-dns services in your Kubernetes cluster namespace kube-system , use 

```bash
kubectl get svc --namespace=kube-system -l k8s-app=kube-dns
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

**NodePort**: Exposes the Service on the same port of each selected node in the cluster using NAT. It makes the Service accessible from outside the cluster by ****NodeIP:NodePort**, the NodePort has fixed range from **30000-32767**

**LoadBalancer**: Exposes the Service externally using a cloud provider’s load balancer. It assigns a fixed, external IP address to the Service.
