---
title: "Task 2 - Concepts of Kubernetes"
menuTitle: "Task 2: Concepts of Kubernetes"
chapter: false
weight: 2
---

There are two main ways to manage Kubernetes objects: 

- imperative (with kubectl commands) and declarative (by writing manifests and then using kubectl apply). Each has its own advantages and disadvantages, so it's best to choose one method based on your use case.

- Imperative commands are great for learning and interactive experiments, but they don't give you full access to the Kubernetes API. They're more commonly used to create YAML manifests and objects on the go. Declarative commands are useful for reproducible deployments and production.

In this Tasks we will run through imperative approach of kubectl. 

### Use Kubectl 

Once you have a running Kubernetes cluster, you can deploy your containerized applications on top of it. To do this,  we use the `kubectl` command to create POD , deployments or other objects in Kubernetes. 

kubectl relies on a configuration file found at ~/.kube/config for authentication and communication with the kube-api-server. Running `kubectl config view` displays details about the kube-API server, including its address, name, and the client's key and certificate.

{{% notice info %}} 
To use kubectl from your personal client machine, you need to copy the ~/.kube/config file from the server to your client machine. Additionally, ensure your client machine can connect to the kube-API server's address. It's also important for the kube-API server to recognize your client's IP address as a trusted source by adding it to a whitelist. This setup ensures secure communication between your client machine and the Kubernetes cluster's control plane.
{{% /notice info %}} 

- We have configured the master node's Ubuntu VM to also serve as a client node for accessing the Kubernetes cluster. Therefore, once you SSH into the master node VM, you can directly use kubectl for cluster management and operations.

- **basic usage of** `kubectl`

The common format of a kubectl command is: **kubectl _ACTION RESOURCE_**

This performs the specified action (like create, describe or delete) on the specified resource (like node or deployment). You can use --help after the subcommand to get additional info about possible parameters (for example: kubectl get nodes --help).

Check that kubectl is configured to talk to your cluster, by running the `kubectl version` command.

Check that kubectl is installed and you can see both the client and the server versions.

- Most used kubectl commands: 

```bash
Basic Commands (Beginner):
  create          Create a resource from a file or from stdin
  expose          Take a replication controller, service, deployment or pod and expose it as a new Kubernetes service
  run             Run a particular image on the cluster
  set             Set specific features on objects

Basic Commands (Intermediate):
  explain         Get documentation for a resource
  get             Display one or many resources
  edit            Edit a resource on the server
  delete          Delete resources by file names, stdin, resources and names, or by resources and label selector

Deploy Commands:
  rollout         Manage the rollout of a resource
  scale           Set a new size for a deployment, replica set, or replication controller
  autoscale       Auto-scale a deployment, replica set, stateful set, or replication controller
  ```
for example, you can use `kubectl get node` to check cluster node detail

```bash
kubectl get node
```
you are expected to see a cluster with both master and worker node.Later, Kubernetes will choose where to deploy our application based on Node available resources.

### POD

## What is a POD?

A Pod in Kubernetes is like a single instance of an application. It can hold closely related containers that work together. All containers in a Pod share the same IP address and ports, and they are always placed together on the same server (Node) in the cluster. This setup means they can easily communicate with each other.  Pods provide the environment in which containers run and offer a way to logically group containers together. 

1. To create a pod:

- kubectl run: Quick way to create a single pod for ad-hoc tasks or debugging.(Imperative)
- kubectl create: Creates specific Kubernetes resources with more control. Use kubectl create -f to create from file.(Declarative)
- kubectl apply: Creates or updates resources based on their configuration files. Use kubectl apply -f to create from file.(Declarative)

2. Run POD with `kubectl run`
```bash
kubectl run juiceshop --image=bkimminich/juice-shop
``` 
above will create a POD with container juiceshop runing inside it. 

use `kubectl get pod` to check the POD
```bash
kubectl get pod
```
exepcted result
```
kubectl get pod
NAME        READY   STATUS    RESTARTS   AGE
juiceshop   1/1     Running   0          7s
```

3. delete POD with `kubectl delete`. check pod again with `kubectl get pod`

```bash
kubectl delete pod juiceshop
```

4. Create POD with `kubectl create -f`

```bash
cat << EOF | kubectl create -f - 
apiVersion: v1
kind: Pod
metadata:
  name: juiceshop
spec:
  containers:
  - image: bkimminich/juice-shop
    name: juiceshop
EOF
```

### Labels

Labels in Kubernetes are key/value pairs attached to objects, such as Pods, Services, and Deployments. They serve to organize, select, and group objects in ways meaningful to users, allowing the mapping of organizational structures onto system objects in a loosely coupled fashion without necessitating clients to store these mappings.

1. Labels can be utilized to filter resources when using kubectl commands. For example, executing the command below will retrieves all Pods labeled with run=juiceshop.

```bash
kubectl get pods -l run=juiceshop
```

2. Labels can be added to an object using the `kubectl label` command. For instance, executing below will add the key:value pair "purpose=debug" to the pod named juiceshop.

```bash
kubectl label pod juiceshop purpose=debug
```

3. To display all the labels:

```bash
kubectl get pod --show-labels
``` 
4. Output 

```bash
kubectl get pod  --show-labels
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE   LABELS
juiceshop   1/1     Running   0          4m7s   purpose=debug,run=juiceshop
```

### Create a Deployment 

### What is a kubernetes Deployment 

While directly creating pods might be suitable for learning purposes or specific use cases (like one-off debugging tasks), **deployments** offer a robust and scalable way to manage containerized applications in production environments. Deployments abstract away much of the complexity associated with pod management, providing essential features such as automatic scaling, self-healing, rolling updates, and rollbacks, which are critical for running reliable and available applications in Kubernetes.

- Deployment in Kubernetes manages app instances, ensuring they run and update smoothly.
- Simplifies app management and scaling by handling instance replication and updates.
- Using kubectl, you can scale pods easily (e.g., from 1 to 10) to meet demand.
- Monitors app instances continuously for any failures.
- Implements self-healing by replacing failed instances on other nodes in the cluster.

### Deploying an Application

1. Deploy your first application on Kubernetes using the `kubectl create deployment` command. This is an imperative command.

It requires specifying the deployment name and the location of the application image (including the full repository URL for images not hosted on Docker Hub).

2. Deployment kubernetes-bootcamp application 

```bash
kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1
```

Congratulations! You've just deployed your first application by creating a deployment. 
This process automates several steps:
Identifies a suitable node where the application instance can be run (assuming there's only one available node in this scenario).
Schedules the application to run on that chosen node.
Ensures the cluster is configured to reschedule the instance to a new node if necessary.

3. To view your deployments use the kubectl get deployments command:

```bash
kubectl get deployment -l app=kubernetes-bootcamp
```
We see that there is 1 deployment running a single instance of your app. The instance is running inside a POD which include container on your node.

```
$ kubectl get deployment -l app=kubernetes-bootcamp
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   1/1     1            1           20m
```

4. In this output:

**kubernetes-bootcamp** is the name of the deployment managing your application.
**READY 1/1** indicates that there is one **pod** targeted by the deployment, and it is ready.   1/1 mean's the deployment expect 1 POD  and POD in ready status is also 1 which mean the actual deployed POD meet the expected number (replica).  

let's keep this deployment to explore what is **ReplicaSet** 

### What is ReplicaSet 

A **ReplicaSet** is a Kubernetes resource that ensures a specified number of replicas of a pod are running at any given time. It is one of the key controllers used for pod replication and management, offering both scalability and fault tolerance for applications. The primary purpose of a ReplicaSet is to maintain a stable set of replica Pods running at any given time. As such, it is often used to guarantee the availability of a specified number of identical Pods. **Deployment** is a higher-level resource in Kubernetes that actually manages ReplicaSets and provides declarative updates to applications. 

1. use below command to check the ReplicaSet (rs) that created when using Deployment to scale the application.

```bash
kubectl get rs -l app=kubernetes-bootcamp
kubectl describe rs kubernetes-bootcamp
```

2. from the output , we can find a line saying "Controlled By:  Deployment/kubernetes-bootcamp" 

```bash
ubuntu@ubuntu22:~$ kubectl get rs -l app=kubernetes-bootcamp
kubectl describe rs kubernetes-bootcamp
NAME                             DESIRED   CURRENT   READY   AGE
kubernetes-bootcamp-5485cc6795   1         1         1       18m
Name:           kubernetes-bootcamp-5485cc6795
Namespace:      default
Selector:       app=kubernetes-bootcamp,pod-template-hash=5485cc6795
Labels:         app=kubernetes-bootcamp
                pod-template-hash=5485cc6795
Annotations:    deployment.kubernetes.io/desired-replicas: 1
                deployment.kubernetes.io/max-replicas: 2
                deployment.kubernetes.io/revision: 1
Controlled By:  Deployment/kubernetes-bootcamp
Replicas:       1 current / 1 desired
Pods Status:    1 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:  app=kubernetes-bootcamp
           pod-template-hash=5485cc6795
  Containers:
   kubernetes-bootcamp:
    Image:        gcr.io/google-samples/kubernetes-bootcamp:v1
    Port:         <none>
    Host Port:    <none>
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Events:
  Type    Reason            Age   From                   Message
  ----    ------            ----  ----                   -------
  Normal  SuccessfulCreate  18m   replicaset-controller  Created pod: kubernetes-bootcamp-5485cc6795-cdwz7
  ```

### Manage your Deployment 
 
1. scale out deployment

To manually scale your deployment with more replicas 

```bash
kubectl scale deployment kubernetes-bootcamp --replicas=10
```
2. check new deployment

```bash
kubectl get deployment kubernetes-bootcamp
```
the **READY** will eventualy become 10/10. which means it expect 10 replicas, and now it reach 10. 

We can use `kubectl get pod` to list the pod, use `-l` to select which pod to list.
**app=kubernetes-bootcamp** is the label assigned to pod during creating.
the expected pod will become 10. 

```bash
kubectl get pod -l app=kubernetes-bootcamp
```

3. scale in deployment

```bash
kubectl scale deployment kubernetes-bootcamp --replicas=1
```
### Explore the POD deployed by Deployment 

```bash
kubectl get pod -l app=kubernetes-bootcamp -o wide
```
expected output 

```
$kubectl get pod -o wide -l app=kubernetes-bootcamp
NAME                                  READY   STATUS    RESTARTS   AGE   IP              NODE         
kubernetes-bootcamp-bcbb7fc75-5r649   1/1     Running   0          73s   10.244.222.16   worker001    
```

Above output is from the kubectl get pod -o wide -l app=kubernetes-bootcamp command, which requests Kubernetes to list pods with additional information (wide output) that match the label app=kubernetes-bootcamp. Here's a breakdown of the output:

**NAME**: kubernetes-bootcamp-bcbb7fc75-5r649 - This is the name of the pod. Kubernetes generates pod names automatically based on the deployment name and a unique identifier to ensure each pod within a namespace has a unique name. you might noticed the name has some appended some hash value bcbb7fc75-5r649, this is created by **deployment** automatically for each replica. the POD created with `kubectl run pod` or `kubectl create -f <pod.yaml>` does not have this hash appended in pod name.


**READY**: 1/1 - This indicates the readiness state of the pod. It means that 1 out of 1 container within the pod is ready. Readiness is determined by readiness probes, which are used to know when a container is ready to start accepting traffic.

**STATUS**: Running - This status indicates that the pod is currently running without issues.

**RESTARTS**: 0 - This shows the number of times the containers within the pod have been restarted. A restart usually occurs if the container exits with an error or is killed for some other reason. In this case, 0 restarts indicate that the pod has been stable since its creation. if POD crashed for some reason, kube-manager will resatrt it. then the Rstart will change.

**AGE**: 73s - This shows how long the pod has been running. In this case, the pod has been up for 73 seconds.

**IP**: 10.244.222.16 - This is the internal IP address assigned to the pod within the Kubernetes cluster network. This IP is used for communication between pods within the cluster.

**NODE**: worker001 - This indicates the name of the node (physical or virtual machine) within the Kubernetes cluster on which this pod is running. The scheduler decides the placement of pods based on various factors like resources, affinity/anti-affinity rules, etc. In this case, the pod is running on a node named worker001.
Below diagram show a POD can have 1 container or multiple container, with or without shared storage. 

all the containers within a single Pod in Kubernetes follow  "shared fate" principle. This means that containers in a Pod are scheduled on the same node (physical or virtual machine) and share the same lifecycle, network namespace, IP address, and storage volumes. 

![Alt text for the image](https://kubernetes.io/docs/tutorials/kubernetes-basics/public/images/module_03_pods.svg)


### Namespace

A namespace in Kubernetes is like a folder that helps you organize and separate your cluster's resources (like applications, services, and pods) into distinct groups. It's useful for managing different projects, environments (such as development, staging, and production), or teams within the same Kubernetes cluster. Namespaces help avoid conflicts between names and make it easier to apply policies, limits, and permissions on a per-group basis

1. Understand the default namespace
By default, a Kubernetes cluster will instantiate a default namespace when provisioning the cluster to hold the default set of Pods, Services, and Deployments used by the cluster.

`kubectl get deployment kubernetes-bootcamp -n default` is same as `kubectl get deployment kubernetes-bootcamp`.

2. we can use `kubectl create namespace` to create different namespace name. below we create two new deployment in two different namespace. 

3. Let's imagine a scenario where an organization is using a shared Kubernetes cluster for development and production use cases.

4. The development team would like to maintain a space in the cluster where they can get a view on the list of Pods, Services, and Deployments they use to build and run their application. In this space, Kubernetes resources come and go, and the restrictions on who can or cannot modify resources are relaxed to enable agile development.

5. The operations team would like to maintain a space in the cluster where they can enforce strict procedures on who can or cannot manipulate the set of Pods, Services, and Deployments that run the production site.

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

```bash
kubectl delete namespace production
kubectl delete namespace development
```


