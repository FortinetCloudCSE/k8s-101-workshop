---
title: " K8S Node and Service"
linkTitle: "Node and Service"
weight: 3
---

### Node

Kubernetes orchestrates containerized workloads by scheduling containers into Pods on Nodes, which can be either virtual or physical machines, depending on the cluster setup.  Each node is managed by the control plane and contains the services necessary to run Pods.

In self-managed Kubernetes, the cluster includes both master and worker nodes. However, in Azure Kubernetes Service (AKS), "Node" usually refers to what's traditionally known as a "worker node"—the machines that run your applications and services. AKS abstracts and manages the control plane for you, enhancing simplicity and reducing management overhead. Users don't have direct access to control plane machines or their settings in AKS, unlike with self-managed Kubernetes clusters, you do not have direct access to the control plane VMs or their configurations in AKS. This means you cannot directly log into the control plane nodes or run commands on them as you might with worker nodes. This AKS deployment example has just one worker node.


The components on a worker node include the **kubelet**, a **container runtime**, and the **kube-proxy**. 

**Kubelet**: This is the main guy talking to both the Node it's on and the control plane. It looks after the Pods and containers on the Node, making sure they're running as they should.
**Container Runtime**: This is what runs your containers. It pulls the container images from where they're stored, unpacks them, and gets your application up and running. Docker and CRI-O are examples of container runtimes used in Kubernetes environments.
**kube-proxy**: This is essential for the operation of Kubernetes services, allowing Pods to communicate with each other and with the outside world. It enables services to be exposed to the external network, load balances traffic across Pods, and is crucial for the overall networking functionality in Kubernetes.


So, in short, a Worker Node is the workhorse of a Kubernetes cluster, providing the necessary environment for your applications (in containers) to run. The control plane or master node keeps an eye on the resources and health of each Node to ensure the cluster operates efficiently.

![Alt text for the image](https://kubernetes.io/docs/tutorials/kubernetes-basics/public/images/module_03_nodes.svg)

*in above diagram , the Docker is used as container runtime, but in our AKS cluster, the container runtime is **containerd***

we can use `kubectl get node -o wide` to check the node status in cluster.

{{< tabs >}}
{{% tab title="Check Detail" %}}

1. Check the node detail

```bash
kubectl get node -o wide
```
{{% /tab %}}
{{% tab title="Expected Output self managed" style="info" %}}

expected outcome:
on self-managed Kubernetes 
```
NAME        STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
nodemaster    Ready    control-plane   55m   v1.26.1   10.0.0.4      <none>        Ubuntu 22.04.3 LTS   6.2.0-1019-azure   cri-o://1.25.4
node-worker   Ready    <none>          54m   v1.26.1   10.0.0.5      <none>        Ubuntu 22.04.3 LTS   6.2.0-1019-azure   cri-o://1.25.4
```
{{% /tab %}}
{{% tab title="Expected Output AKS" style="info" %}}

on managed Kubernetes like AKS

```
NAME                             STATUS   ROLES   AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
aks-worker-24706581-vmss000000   Ready    agent   7m32s   v1.27.9   10.224.0.4    <none>        Ubuntu 22.04.3 LTS   5.15.0-1054-azure   containerd://1.7.7-1
```
{{% /tab %}}
{{< /tabs >}}

### Cordon worker node 

Nodes in Kubernetes can be made un-schedulable using the `kubectl cordon <nodename>` command, which is particularly useful when preparing a node for maintenance. When a node is cordoned, the kube-scheduler will no longer schedule new pods onto it, although existing pods on the node are not affected.


use `kubectl uncordon <nodename>` to put worker node back to work. 
{{< tabs >}}
{{% tab title="Cordon first node" %}}

Cordon first node
since this cluster only have one node, Cordon first node mean all nodes.

```bash
firstNodeName=$(kubectl get node -o json | jq -r .items[0].metadata.name)
kubectl cordon $firstNodeName
```
{{% /tab %}}
{{% tab title="Check Cordon Status" %}}
- Check node status
```bash
kubectl get node 
```
{{% /tab %}}
{{% tab title="Expected Output Cordon" style="info" %}}

expected result
```
aks-worker-29142279-vmss000000   Ready,SchedulingDisabled   agent   29m   v1.27.9
```
the Node now marked with "SchedulingDisabled".

{{% /tab %}}
{{% tab title="Create Pod" %}}

Create Pod
```bash
kubectl run juiceshop3 --image=bkimminich/juice-shop
```
{{% /tab %}}
{{% tab title="Check Status" %}}

Check the Pod status
```bash
kubectl get pod juiceshop3
```
{{% /tab %}}
{{% tab title="Expected Output Pending" style="info" %}}

expected result
```
NAME         READY   STATUS    RESTARTS   AGE
juiceshop3   0/1     Pending   0          42s
```

The Pod Juiceshop3 will remain in Pending status, as the only worker node now is disabled for scheduling. if you have multiple worker node. then the Pod will be scheduled to other worker node.

{{% /tab %}}
{{< /tabs >}}

{{< tabs >}}
{{% tab title="Uncordon"  %}}

Put node back to work
```bash
firstNodeName=$(kubectl get node -o json | jq -r .items[0].metadata.name)
kubectl uncordon $firstNodeName
```
{{% /tab %}}
{{% tab title="Uncordon Check"  %}}

Check node status
```bash
kubectl get node 
```
{{% /tab %}}
{{% tab title="Expected Output Uncordon" style="info" %}}
expected result
```
aks-worker-29142279-vmss000000   Ready    agent   29m   v1.27.9
```
{{% /tab %}}
{{% tab title="Check Pod status" style="info" %}}
Check the Pod Juiceshop3 status 
```bash
kubectl get pod juiceshop3
```
The Pod juiceshop3 shall move to "Runing" status.
{{% /tab %}}
{{< /tabs >}}

### What is Service

A Kubernetes Service is a way to expose an application running on a set of Pods as a network service. It abstracts the details of the pod's IP addresses from consumers, providing a single point of access for a set of pods, typically to ensure that network traffic can be directed to them even as they are created or destroyed. This is crucial for maintaining consistent access to the functionalities these pods provide. 

Services primarily operate at the transport layer (Layer 4 of the OSI model), dealing with IP addresses and ports. They provide a way to access pods within the cluster and, in the case of NodePort and LoadBalancer, expose them externally.


####  Major Types of Kubernetes Services:

- **ClusterIP** to expose service to cluster internal

This is the default service type that exposes the service on an internal IP within the cluster, making the service reachable only from within the cluster.

![clusterIP svc ](https://learn.microsoft.com/en-us/azure/aks/media/concepts-network/aks-clusterip.png)
 

To check the services in your Kubernetes cluster, you can use the following command:
{{< tabs >}}
{{% tab title="Check Service" %}}
1. Check Kubernetes build-in service 

use `kubectl get svc` to check service 
```bash
kubectl get svc --show-labels
```
{{% /tab %}}
{{% tab title="Expected Output" style="info" %}}
expected output 
```
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE   LABELS
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   49m   component=apiserver,provider=kubernetes
```

This output shows the built-in Kubernetes service, which serves as the internal endpoint for the Kubernetes API service. The ClusterIP 10.96.0.1 assigned to services like the Kubernetes API server (Kubernetes service) is a virtual IP (VIP) and does not correspond to a physical network interface. It is part of Kubernetes' service discovery and networking mechanism, which relies on kube-proxy (running on each node) and the cluster's network configuration to route traffic to the appropriate endpoints.
{{% /tab %}}
{{< /tabs >}}

The ClusterIP is only accessible from within the cluster, which means it cannot be directly accessed from the master node using kubectl. To interact with it, one must use another pod within the same cluster.

- Kubernetes API clusterIP service 

Below, we launch a pod using the curl command to access the HTTPS port on 10.96.0.1 which is Kubernetes API.  Receiving either 401 or 403  response indicates that connectivity is working fine, but the request is not authorized. This lack of authorization occurs because curl did not supply a certificate to authenticate itself:

{{< tabs >}}
{{% tab title="API reachable?" %}}

Verify whether kubernetes svc API is reachable

```bash
kubectl run curlpod --image=appropriate/curl --restart=Never --rm -it --  curl -I -k https://10.96.0.1/
```
{{% /tab %}}
{{% tab title="Expected Output" style="info" %}}

Expected output:
```
HTTP/1.1 401 Unauthorized
```
or 
```
HTTP/1.1 403 Forbidden
```

"401" or "403" is because curl need to supply a certificate to authenticate itself which we did not supply, however, above is enough to show you the 10.96.0.1 is reachable via clusterIP Service.

{{% /tab %}}
{{< /tabs >}}


#### Verify the Kube-dns service 
- Exploring the Kubernetes Default ClusterIP type Service: kube-dns

Kubernetes includes several built-in services essential for its operation  , with **kube-dns** being a key component. The **kube-dns** service is responsible for DNS resolution within the Kubernetes cluster, allowing pods to resolve the IP addresses of other services and external domains.

![clusterIP svc ](https://www.tigera.io/app/uploads/2023/05/image13-1.png)

*In this workshop, the kube-dns svc has configured with ip 10.96.0.10 instead of 10.0.0.10*

To check the kube-dns services in your Kubernetes cluster namespace kube-system , use 
{{< tabs >}}
{{% tab title="Check kube-dns" %}}

Check kube-dns API in namespace kube-system

```bash
kubectl get svc --namespace=kube-system -l k8s-app=kube-dns
```
{{% /tab %}}
{{% tab title="Expected Output" style="info" %}}

expected output
```
NAME       TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)         AGE
kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP   33m
```
You should see kube-dns listed among the services, typically with a ClusterIP type, indicating it's internally accessible within the cluster.
{{% /tab %}}
{{< /tabs >}}

- Verifying DNS Resolution with kube-dns 


To verify that kube-dns is correctly resolving domain names within the cluster, you can perform a DNS lookup from a pod. Here’s how to launch a temporary pod for testing DNS resolution using the busybox image, the FQDN name for Kubernetes service is in format "svcname.namespace.svc.cluster.local". kube-dns service help how to solve cluster internal and external FQDN to IP address.
{{< tabs >}}
{{% tab title="Verify internal dns" %}}

4. Verify whether kube-dns can resolve cluster internal svc

```bash
kubectl run dns-test --image=busybox --restart=Never --rm -it -- nslookup  kubernetes.default.svc.cluster.local
```
{{% /tab %}}
{{% tab title="Expected Output Internal" style="info" %}}

expected output
```
Server:         10.96.0.10
Address:        10.96.0.10:53

Name:   kubernetes.default.svc.cluster.local
Address: 10.96.0.1


pod "dns-test" deleted
```
{{% /tab %}}
{{% tab title="Verify public DNS" %}}

5. Verify whether kube-dns can resolve public fqdn dns name
```bash
kubectl run dns-test --image=busybox --restart=Never --rm -it -- nslookup  www.google.com
```
{{% /tab %}}
{{% tab title="Expected Output Public" style="info" %}}

expected output
```
Server:         10.96.0.10
Address:        10.96.0.10:53

Non-authoritative answer:
Name:   www.google.com
Address: 142.251.16.147
Name:   www.google.com
Address: 142.251.16.104
Name:   www.google.com
Address: 142.251.16.105
Name:   www.google.com
Address: 142.251.16.99
Name:   www.google.com
Address: 142.251.16.103
Name:   www.google.com
Address: 142.251.16.106

Non-authoritative answer:
Name:   www.google.com
Address: 2607:f8b0:4004:c07::67
Name:   www.google.com
Address: 2607:f8b0:4004:c07::6a
Name:   www.google.com
Address: 2607:f8b0:4004:c07::63
Name:   www.google.com
Address: 2607:f8b0:4004:c07::68

pod "dns-test" deleted
```
{{% /tab %}}
{{< /tabs >}}

Above two commands does the following:

Launches a temporary pod named dns-test using the busybox image.
Executes the nslookup command to resolve the domain name Kubernetes.default.svc.cluster.local, which should be the internal DNS name for the Kubernetes API server.
Automatically removes the pod after the command execution (--rm flag).

The kube-dns service is vital for internal name resolution in Kubernetes, enabling pods to communicate with each other and access various cluster services using DNS names. Verifying DNS resolution functionality with kube-dns is straightforward with a temporary pod and can help diagnose connectivity issues within the cluster.

- **NodePort**:  expose service to cluster external 


Exposes the service externally on the same port of each selected node in the cluster via NAT. Accessible by NodeIP:NodePort within the range 30000-32767.

![nodePort svc ](https://learn.microsoft.com/en-us/azure/aks/media/concepts-network/aks-nodeport.png) 




- **LoadBalancer**: expose service to cluster external 

Exposes the service externally using a cloud provider's load balancer or an on-premises solution like MetalLB, assigning a fixed, external IP to the service."

![LoadBalancer svc ](https://learn.microsoft.com/en-us/azure/aks/media/concepts-network/aks-loadbalancer.png)


### Expose deployment with LoadBalancer Service

Let's use `kubectl expose deployment` command to expose our Kubernetes Bootcamp deployment to the internet by creating a LoadBalancer service. The kubectl expose command is used to expose a Kubernetes deployment, pod, or service to the internet or other parts of the cluster. When used within Azure Kubernetes Service (AKS), a managed Kubernetes platform, this command creates a service resource that defines how to access the Kubernetes workloads.  **--type=LoadBalancer**: Specifies the type of service to create. LoadBalancer services are public, cloud-provider-specific services that automatically provision an external load balancer (in this case, an Azure Load Balancer) to direct traffic to the service. This option makes the service accessible from outside the AKS cluster.
{{< tabs >}}
{{% tab title="expose" %}}
1. expose kubernetes-bootcamp with LoadBalancer service 
```bash
kubectl expose deployment kubernetes-bootcamp --port=80 --type=LoadBalancer --target-port=8080 --name=kubernetes-bootcamp-lb-svc 
```
{{% /tab %}}
{{% tab title="Verify" %}}
2. Verify the exposed service
```bash
kubectl get svc -l app=kubernetes-bootcamp
```
{{% /tab %}}
{{% tab title="Expected Output" style="info" %}}
expected outcome
```
NAME                         TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)        AGE
kubernetes-bootcamp-lb-svc   LoadBalancer   10.96.250.234   4.157.216.24   80:32428/TCP   12m
```
You should observe the **EXTERNAL-IP** status transition from **'Pending'** to an actual public IP address, serving as the entry point for the Kubernetes Bootcamp deployment. Coupled with PORT 80, this defines how to access the Kubernetes Bootcamp application.
{{% /tab %}}
{{% tab title="Access service" %}}

Access Bootcamp  from external

Access the Kubernetes Bootcamp application using the curl command or through your web browser."

```bash
ip=$(kubectl get svc -l app=kubernetes-bootcamp -o json | jq -r .items[0].status.loadBalancer.ingress[0].ip)
curl http://$ip:80
```
{{% /tab %}}
{{% tab title="Expected Output External" style="info" %}}
Expected result
```
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-855d5cc575-b97z8 | v=1
```

{{% /tab %}}
{{< /tabs >}}

### Summary


Worker nodes host your pods. A ClusterIP service enables internal cluster access to these pods, while NodePort and LoadBalancer services provide external access.

You have sucessfully brought up a managed Kubernetes (AKS) and walked through the concept of POD, Deployment, Replicas, Namespace, Label, Node, different type of services etc, in Kubernetes. We will continue to install a self-managed Kubernetes to continue our jourey.




### clean up

{{< notice warning >}}  


Do not forget to remove your AKS cluster. We will use self-managed k8s for hands-on activities.

 {{< /notice >}} 
delete your aks cluster with below command, this will took around 5 minutes.


```bash
clustername=$(whoami)
resourcegroupname=$(az group list --query "[?tags.UserPrincipalName=='$(az account show --query user.name -o tsv)'].name" -o tsv)
echo you are going to delete aks cluster $clustername in resourcegroup $resourcegroupname
az aks delete --name ${clustername} -g $resourcegroupname  
```


### Review Questions

1. What is the role of a worker node in Kubernetes, and what are three key components that run on every Kubernetes Worker Node?
{{% expand title="Click for Answer..." %}}
```bash
A Kubernetes worker node is responsible for running containerized applications. It hosts the pods and provides the runtime environment.
Three key components that run on every Kubernetes worker node are:
Kubelet: Manages pods and their containers on the node.
Container Runtime: (e.g., Docker, containerd) Runs the containers.
Kube-proxy: Manages network rules for pod communication.
These components work together to ensure proper execution and networking of pods on the worker node.
```
{{% /expand %}}
2. What is a Kubernetes Service, and why is it important?
{{% expand title="Click for Answer..." %}}
    A Kubernetes Service exposes applications running on a set of Pods to network traffic. It abstracts away the details of which Pods are running, allowing clients to reliably access the application without knowing its internal structure.
{{% /expand %}}
3. Describe the difference between ClusterIP, NodePort, and LoadBalancer Service types in Kubernetes.
{{% expand title="Click for Answer..." %}}
```bash
ClusterIP: Internal access within the cluster.
NodePort: Exposes the service on each node's IP at a static port.
LoadBalancer: Exposes the service externally typically using a cloud provider's load balancer.
```
{{% /expand %}}
