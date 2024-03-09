---
title: "Appendix - More info"
menuTitle: "Appendix - More info"
weight: 7
---


#### Pod life-cycle 

The life cycle of a Kubernetes Pod involves several key stages from creation to termination. Here's a brief overview of these stages, illustrated with commands related to deploying a Pod using the `gcr.io/google-samples/kubernetes-bootcamp:v1` image:

1. **Pod Creation**

A Pod is created when you deploy it using a YAML file or directly via the kubectl command.

2. **Pending**
The Pod enters the Pending state as Kubernetes schedules the Pod on a node and the container image is being pulled from the registry.

3. **Running**
Once the image is pulled and the Pod is scheduled, it moves to the Running state. The Pod remains in this state until it is terminated or stopped for some reason.

4. **Succeeded/Failed**

A Pod reaches Succeeded if all of its containers exit without error and do not restart.
A Pod is marked as Failed if any of its containers exit with an error.

5. **CrashLoopBackOff**

This status indicates that a container in the Pod is failing to start properly and Kubernetes is repeatedly trying to restart it.

6. **Termination** 
Pods can be terminated gracefully by deleting them. Kubernetes first sends a SIGTERM signal to allow containers to shut down gracefully.

7. **Deletion**
The Pod's entry remains in the system for a period after termination, allowing you to inspect its status posthumously. Eventually, Kubernetes cleans it up automatically.

Through these stages, Kubernetes manages the application's lifecycle, ensuring that the desired state specified by the Deployment configurations is maintained. Monitoring the Pod's lifecycle helps in managing and troubleshooting applications running on Kubernetes.

we can use `kubectl get pod -l app=kubernetes-bootcamp` and `kuectl describe pod -l app=kubernetes-bootcamp` to check the detail state for a Pod.

#### Useful Command for Pod 

You can try a few useful command for operating a Pod 

- get the Pod name only

To retrieve just the name(s) of the Pod(s) with a specific label (app=kubernetes-bootcamp), use the following command: 

```bash
kubectl get pods -l app=kubernetes-bootcamp -o=jsonpath='{.items[*].metadata.name}'
```

- shell into the Pod 
To access the shell of the default container in a Pod labeled with app=kubernetes-bootcamp, first capture the Pod name in a variable, then use kubectl exec:

```bash
PODNAME=$(kubectl get pods -l app=kubernetes-bootcamp -o=jsonpath='{.items[*].metadata.name}')
kubectl exec -it po/$PODNAME -- bash
```
Note: This command assumes that your selection returns a single Pod name or you are only interested in the first Pod. Use exit to leave the container shell. some of container in Pod does not have `bash` or `sh` , then you will not able to shell into the container in that Pod.

you will be drop into Pod's default container shell, use `exit` to exit the container.

- check log for a Pod
To view the logs from the container in real-time:

```bash
PODNAME=$(kubectl get pods -l app=kubernetes-bootcamp -o=jsonpath='{.items[*].metadata.name}')
kubectl logs -f po/$PODNAME
```
You will see logs output from the container. Press Ctrl-C to exit the log stream.
```
Kubernetes Bootcamp App Started At: 2024-02-21T05:41:33.993Z | Running On:  kubernetes-bootcamp-5485cc6795-cdwz7 
```


- Delete Pod and Observe IP Address Change
First, check the current Pod's IP address:

```bash
kubectl get pod -l app=kubernetes-bootcamp -o wide
``` 
then delete Pod 
```bash
PODNAME=$(kubectl get pods -l app=kubernetes-bootcamp -o=jsonpath='{.items[*].metadata.name}')
kubectl delete po/$PODNAME
```
You will see an output similar to:
```
pod "kubernetes-bootcamp-5485cc6795-cdwz7" deleted
```
After deletion, check the Pods again. You will find a new Pod has been automatically recreated with a new IP address. This behavior is due to the Kubernetes Controller Manager ensuring the actual state matches the desired state specified by the Deployment's replicas. A new Pod is generated to maintain the desired number of replicas.

```bash
kubectl get pod -l app=kubernetes-bootcamp -o wide
```

The IP address assigned to a Pod is ephemeral and will assign next available ip for recreation. 


These commands provide a basic but powerful set of tools for interacting with Pods in a Kubernetes environment, from accessing shells and viewing logs to managing Pod lifecycles.

#### ServiceAccount 

A ServiceAccounts are primarily designed for use by processes running in Pods is like an identity for processes running in a Pod, allowing them to interact with the Kubernetes API securely. When you create a Pod, Kubernetes can automatically give it access to a ServiceAccount, so your applications can ask Kubernetes about other parts of the system without needing a separate login. It's a way for your apps to ask Kubernetes "Who am I?" and "What am I allowed to do?"


check the default service account for a POD

```bash
podName=$(kubectl get pod -l app=kubernetes-bootcamp  -o=jsonpath='{.items[*].metadata.name}')
kubectl describe pod $podName | grep 'Service Account' | uniq
```
Expected output:

```

Service Account:  default
```

Kubernetes adheres to the principle of least privilege, meaning the default ServiceAccount is assigned minimal permissions necessary for a Pod's basic operations. Should your Pod require additional permissions, you must create a new ServiceAccount with the requisite permissions and associate it with your Pod. use `kubectl create rolebinding` to bind pre-defined role or custom role to serviceAccount.

#### Kubernetes API-resources 

Kubernetes is fundamentally built around APIs that adhere to the OpenAPI specification, defining **resources** and their operations. Based on API input, Kubernetes creates **objects** and stores them in the etcd database. Let's explore using the Kubernetes API to create a Pod, utilizing the kubectl api-resources and kubectl explain commands for guidance. 

- Finding the API Resource for Pods


First, identify the API resource needed to create a Pod. You can list all API resources with `kubectl api-resources``:

This command filters the list of API resources to show only those related to Pods. The output will look similar like this:

```bash
kubectl  api-resources | head  -n 1
kubectl  api-resources | grep pods
```
expect to see output 

```bash
 kubectl  api-resources | head  -n 1
NAME 
NAME                              SHORTNAMES                                      APIVERSION                             NAMESPACED   KIND
kubectl  api-resources | grep pods
pods                              po                                              v1                                     true         Pod
pods                                                                              metrics.k8s.io/v1beta1                 true         PodMetrics
```

From the output, we see that the "KIND" for Pods is "Pod", and the API version is v1.


- Understanding Pod Specifications

Next, use `kubectl explain` to understand how to structure a YAML definition for a Pod specification. Execute the following commands to explore the Pod resource specifications:

```bash
kubectl explain Pod
```
and
```bash
kubectl explain Pod.apiVersion
```
and 
```bash
kubectl explain Pod.kind
```
and
```bash
kubectl explain Pod.metadata
```


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

use  `kubectl delete pod test-pod` to delete pod or use yaml file below 
```bash
kubectl  delete -f minimalyamlforpod.yaml 
```

