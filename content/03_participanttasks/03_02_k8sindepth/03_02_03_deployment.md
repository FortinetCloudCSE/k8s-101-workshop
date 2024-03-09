---
title: "Task 3 - Deployments"
menuTitle: "Task 3 - Deployments"
weight: 3
---

#### Objective: Master the Creation and Management of Deployments

Description: This module zeroes in on Deployments as the primary mechanism for deploying applications on Kubernetes. You will delve into the creation of Deployments, learn how to scale them effectively, and update applications with zero downtime. Through hands-on lab exercises, you will experience deploying a multi-replica application and conducting rolling updates to ensure seamless application transitions.

#### Deploying an Application with a Deployment

We've previously seen how to use kubectl create deployment Kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1 to create a deployment directly from the command line. However, Kubernetes also supports deploying applications using YAML or JSON manifests. This approach provides greater flexibility than using the kubectl CLI alone and facilitates version control of your deployment configurations.

By defining deployments in YAML or JSON files, you can specify detailed configurations, manage them through source control systems, and apply changes systematically. This method enhances the maintainability and reproducibility of your deployments within a Kubernetes environment.


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
```
- replicas: 1: Specifies that only one replica of the Pod should be running.
- selector: Defines how the Deployment finds which Pods to manage using matchLabels.
- template: Describes the Pod template used by the Deployment to create new Pods.
- metadata.labels: Sets the label app: kubernetes-bootcamp on the Pod, matching the selector in the Deployment spec.
- spec.containers: Lists the containers to run in the Pod.
- image: gcr.io/google-samples/kubernetes-bootcamp:v1: Specifies the container image to use.

#### Scale your deployment 

After deploying the Kubernetes Bootcamp application, you might find the need to scale your deployment to accommodate an increased load or enhance availability. Kubernetes allows you to scale a deployment, increasing the number of replicas from 1 to 10, for instance. This ensures your application can handle a higher load. There are several methods to scale a deployment, each offering unique benefits.

## 1. Using kubectl scale

**Benefits:**
1. Immediate: This command directly changes the number of replicas in the deployment, making it a quick way to scale.
Simple: Easy to remember and use for ad-hoc scaling operations.

2. Before scaling:

```bash
kubectl get deployment
```
expected output
```
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   1/1     1            1           63m
```

3. Scaling the deployment: 

```bash
kubectl scale deployment kubernetes-bootcamp --replicas=10
```
**expected output**

```
deployment.apps/kubernetes-bootcamp scaled
```

4. You can monitor the scaling process and the deployment's progress using `kubectl rollout status deployment kubernetes-bootcamp`

5. To view the updated deployment, use:

```bash
kubectl get deployment kubernetes-bootcamp
```

6. Expected Outcome: After scaling, you should observe that the number of Pods has increased to meet the deployment's requirements. 

**expected output**

```
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   10/10   10           10          64m
```

7. Listing the Pods:
```bash
kubectl get pod -l app=kubernetes-bootcamp
```
expected output
```
NAME                                  READY   STATUS    RESTARTS   AGE
kubernetes-bootcamp-bcbb7fc75-5fjhc   1/1     Running   0          44s
kubernetes-bootcamp-bcbb7fc75-5kjd7   1/1     Running   0          44s
kubernetes-bootcamp-bcbb7fc75-5r649   1/1     Running   0          30m
kubernetes-bootcamp-bcbb7fc75-bmzbv   1/1     Running   0          44s
kubernetes-bootcamp-bcbb7fc75-fn29h   1/1     Running   0          44s
kubernetes-bootcamp-bcbb7fc75-fp2d9   1/1     Running   0          44s
kubernetes-bootcamp-bcbb7fc75-jfdvf   1/1     Running   0          44s
kubernetes-bootcamp-bcbb7fc75-nh9sn   1/1     Running   0          44s
kubernetes-bootcamp-bcbb7fc75-q7sqc   1/1     Running   0          44s
kubernetes-bootcamp-bcbb7fc75-t4tkm   1/1     Running   0          44s
```

This output confirms the deployment now runs 10 replicas of the Kubernetes Bootcamp application, demonstrating successful scaling.

8. delete the deployment 
```bash
kubectl delete deployment kubernetes-bootcamp 
```

## 2. use kubectl apply 

1. if the intended resource to update is in yaml file, we can directly edit the yaml file with any editor, then  use `kubectl apply` to update.

2. The kubectl apply -f command is more flexible and is recommended for managing applications in production. It updates resources with the changes defined in the YAML file but retains any modifications that are not specified in the file.It's particularly suited for scenarios where you might want to maintain manual adjustments or unspecified settings. 


3. First let's create Kubernetes-bootcamp deployment yaml file with below 
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
kubectl apply -f kubernetes-bootcamp.yaml 
```
**expected Outcome**

```
kubectl get deployment
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   1/1     1            1           3s
```

4. Now, use editor like vim to change the replicas=1 in the yaml file to replicas=10.

5. you can also use `sed` to change it 

```bash
sed -i 's/replicas: 1/replicas: 10/' kubernetes-bootcamp.yaml

```
6. then apply the changes with

 ```bash
 kubectl apply -f kubernetes-bootcamp.yaml
 ```
check again
```bash
kubectl get deployment kubernetes-bootcamp
```

**expected outcome**

```
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   10/10   10           10          99s
```

7. clean up
```bash
kubectl delete -f kubernetes-bootcamp.yaml
```

**Benefits:**

- Version Controlled: Can be version-controlled if using a local YAML file, allowing for tracking of changes and rollbacks.
- Reviewable: Changes can be reviewed by team members before applying if part of a GitOps workflow.

## 3. use kubectl edit 

1. This approach involves manually editing the resource definition in a text editor (invoked by kubectl edit), where you can change any part of the resource. After saving and closing the editor, Kubernetes applies the changes. This method requires no separate kubectl apply, as kubectl edit directly applies the changes once the file is saved and closed.

```bash
kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1 --replicas=1
kubectl edit deployment kubernetes-bootcamp
```

2. after run `kubectl edit`, it will show you a VI EDITOR with opened yaml file, locate the text 
```
spec:
  progressDeadlineSeconds: 600
  replicas: 1
``` 

3. then change replicas from 1 to 10, then save and  exit the EDITOR. and check the new deployment with updated replicas. 


4. Use Case: Ideal for ad-hoc modifications where you might need to see the full context of the resource or make multiple edits.  

5. delete deployment after done the observation.

```bash
kubectl delete deployment kubernetes-bootcamp
```

## 4. Kubectl patch 

1. kubectl patch directly updates specific parts of a resource without requiring you to manually edit a file or see the entire resource definition. It's particularly useful for making quick changes, like updating an environment variable in a Pod or changing the number of replicas in a deployment.

2. Automation Friendly: It's ideal for scripts and automation because you can specify the exact change in a single command line.

```bash
kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1 --replicas=1
```
use `kubectl get deployment  kubernetes-bootcamp` to check

3. expected result 

```
kubectl get deployment kubernetes-bootcamp
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   1/1     1            1           33s
```

4. then use `kubectl patch` to change replicas 

```bash
kubectl patch deployment kubernetes-bootcamp --type='json' -p='[{"op": "replace", "path": "/spec/replicas", "value":10}]'

```

#### Directly update yaml file with  kubectl replace 

1. The kubectl replace -f command replaces a resource with the new state defined in the YAML file. If the resource doesn't exist, the command fails. This command requires that the resource be defined completely in the file being applied because it replaces the existing configuration with the new one provided.

2. Deletion and Recreation: Under the hood, replace effectively deletes and then recreates the resource, which can lead to downtime for stateful applications or services. This method does not preserve unspecified fields or previous modifications made outside the YAML file.

3. Usage: Use kubectl replace -f when you want to overwrite the resource entirely, and you are certain that the YAML file represents the complete and desired state of the resource.

4. create deployment with replicas=1

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
kubectl replace -f kubernetes-bootcamp.yaml
```
5. then modify **replicas: 1** to **replicas: 10** in kubernetes-bootcamp.yaml
```bash
sed -i 's/replicas: 1/replicas: 10/' kubernetes-bootcamp.yaml
```
```bash
# Update the replicas in the YAML file, then:
kubectl replace -f kubernetes-bootcamp.yaml
```
6. check new deployment 

```bash
kubectl get deployment
```
Expected output 
```
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   10/10   10           10          4m34s
```

7. Risk of Downtime: For some resources, using kubectl replace can cause downtime since it may delete and recreate the resource, depending on the type and changes made. It's important to use this command with caution, especially for critical resources in production environments.


Summary 

- kubectl scale: Quickly scales the number of replicas for a deployment, ideal for immediate, ad-hoc adjustments.

- kubectl edit: Offers an interactive way to scale by manually editing the deployment's YAML definition in a text editor, providing a chance to review and adjust other configurations simultaneously.

- kubectl patch: Efficiently updates the replicas count with a single command, suitable for scripts and automation without altering the rest of the deployment's configuration.

- kubectl replace -f: Replaces the entire deployment with a new configuration from a YAML file, used when you have a prepared configuration that includes the desired replicas count.

- kubectl apply -f: Applies changes from a YAML file to the deployment, allowing for version-controlled and incremental updates, including scaling operations.

Let's explore how to automatically scale your deployment based on resource usage.

### clean up
```bash
kubectl delete deployment kubernetes-bootcamp
```
