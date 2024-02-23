---
title: "Task 5 - Creating and Managing Pods"
menuTitle: "Pods"
chapter: false
weight: 5
---

In Kubernetes, a Pod is the smallest and most basic deployable unit. It represents a single instance of a running process in your cluster. Pods are the building blocks of Kubernetes applications and encapsulate one or more containers, storage resources, a unique network IP, and options that govern how the containers should run. More info about pods:

- The smallest, most basic unit in Kubernetes.
- Represents a single instance of a running process in your cluster.
- Can contain one or more containers that are tightly coupled and share resources, such as storage and networking.
- Often represents a single microservice, but can also encapsulate multiple closely related containers.
- Pods are ephemeral by nature, meaning they can be created, destroyed, and replaced dynamically based on the cluster's needs.
- Managed by Kubernetes controllers like Deployments, ReplicaSets, or StatefulSets to ensure desired state and high availability.(We will learn about these in next chapters)
- Provides a unique IP address within the cluster, allowing communication between pods.
- Can have one or more volumes attached to it for persistent storage.
- Logs and metrics of individual containers within a pod can be accessed using kubectl.

Pods in a Kubernetes cluster are used in two main ways:

**Pods that run a single container:** The "one-container-per-Pod" model is the most common Kubernetes use case; in this case, you can think of a Pod as a wrapper around a single container; Kubernetes manages Pods rather than managing the containers directly.

**Pods that run multiple containers:** that need to work together. A Pod can encapsulate an application composed of multiple co-located containers that are tightly coupled and need to share resources. These co-located containers form a single cohesive unit.

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

5. Another example of Creating a pod

```bash
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
EOF
```

**Init container:**

Init containers in Kubernetes are specialized containers that run before the main containers in a Pod, serving to prepare the environment or perform initialization tasks. They execute sequentially, ensuring that each init container completes successfully before the next one starts and before the main containers begin execution. Init containers share the same volume mounts as the main containers, facilitating the sharing of resources such as configuration files or secrets. They are transient in nature, running to completion once and then terminating, and are not restarted if they fail.

6. To create Pod with init containers:

```
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx-init-pod
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
  initContainers:
  - name: init-nginx
    image: busybox
    command: ['sh', '-c', 'echo "Hello, NGINX!" > /usr/share/nginx/html/index.html']
```

7. To check pods, run `kubectl get pods`