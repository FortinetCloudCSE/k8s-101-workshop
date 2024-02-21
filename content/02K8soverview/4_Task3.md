---
title: "Task 3 - Deployments, Scaling , Upgrade Applications"
menuTitle: "Deployments, Scaling, Upgrade Applications"
chapter: false
weight: 3
---

Objective: Master the Creation and Management of Deployments

Description: This module zeroes in on Deployments as the primary mechanism for deploying applications on Kubernetes. You will delve into the creation of Deployments, learn how to scale them effectively, and update applications with zero downtime. Through hands-on lab exercises, you will experience deploying a multi-replica application and conducting rolling updates to ensure seamless application transitions.

### Deploying an Application with a Deployment

We've previously seen how to use kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1 to create a deployment directly from the command line. However, Kubernetes also supports deploying applications using YAML or JSON manifests. This approach provides greater flexibility than using the kubectl CLI alone and facilitates version control of your deployment configurations.

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
- replicas: 1: Specifies that only one replica of the pod should be running.
- selector: Defines how the Deployment finds which Pods to manage using matchLabels.
- template: Describes the Pod template used by the Deployment to create new Pods.
- metadata.labels: Sets the label app: kubernetes-bootcamp on the Pod, matching the selector in the Deployment spec.
- spec.containers: Lists the containers to run in the Pod.
- image: gcr.io/google-samples/kubernetes-bootcamp:v1: Specifies the container image to use.

## Scale your deployment 

After deploying the Kubernetes Bootcamp application, you might find the need to scale your deployment to accommodate an increased load or enhance availability. Kubernetes allows you to scale a deployment, increasing the number of replicas from 1 to 10, for instance. This ensures your application can handle a higher load. There are several methods to scale a deployment, each offering unique benefits.

### Using kubectl scale
Benefits:

Immediate: This command directly changes the number of replicas in the deployment, making it a quick way to scale.
Simple: Easy to remember and use for ad-hoc scaling operations.


```bash
kubectl scale deployment kubernetes-bootcamp --replicas=10

```
You can monitor the scaling process and the deployment's progress using `kubectl rollout status deployment kubernetes-bootcamp`:

To view the updated deployment and the status of the pods, use:

```bash
kubectl get deployment kubernetes-bootcamp
kubectl get pod -l app=kubernetes-bootcamp
```
Expected Outcome
After scaling, you should observe that the number of pods has increased to meet the deployment's requirements:

Before scaling:



```bash
ubuntu@ubuntu22:~$ kubectl get deployment
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   1/1     1            1           63m
```
Scaling the deployment: 
```bash
ubuntu@ubuntu22:~$ kubectl scale deployment kubernetes-bootcamp --replicas=10
deployment.apps/kubernetes-bootcamp scaled
```
Checking the rollout status:
```bash
ubuntu@ubuntu22:~$ kubectl rollout status deployment kubernetes-bootcamp
deployment "kubernetes-bootcamp" successfully rolled out
```
Verifying the deployment after scaling:
```bash
ubuntu@ubuntu22:~$ kubectl get deployment kubernetes-bootcamp
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   10/10   10           10          64m
```
Listing the pods:
```bash
ubuntu@ubuntu22:~$ kubectl get pod -l app=kubernetes-bootcamp
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

### kubectl edit followed by kubectl apply


This approach involves manually editing the resource definition in a text editor (invoked by kubectl edit), where you can change any part of the resource. After saving and closing the editor, Kubernetes applies the changes. This method requires no separate kubectl apply, as kubectl edit directly applies the changes once the file is saved and closed.

Command:
First, edit the deployment YAML file then manually  change the replicas value, then apply the changes:
```bash
kubectl edit deployment kubernetes-bootcamp

```

Use Case: Ideal for ad-hoc modifications where you might need to see the full context of the resource or make multiple edits.  

### Kubectl patch

kubectl patch directly updates specific parts of a resource without requiring you to manually edit a file or see the entire resource definition. It's particularly useful for making quick changes, like updating an environment variable in a pod or changing the number of replicas in a deployment.

Automation Friendly: It's ideal for scripts and automation because you can specify the exact change in a single command line.

reset replicas =1 
```bash
kubectl scale deployment kubernetes-bootcamp --replicas=1
```
then use `kubectl patch` to change replicas 

```bash
kubectl patch deployment kubernetes-bootcamp --type='json' -p='[{"op": "replace", "path": "/spec/replicas", "value":10}]'

```

### Directly update yaml file with  kubectl apply

if the intended resource to update is in yaml file, we can directly edit the yaml file with any editor, then  use `kubectl apply` to update.

The kubectl apply -f command is more flexible and is recommended for managing applications in production. It updates resources with the changes defined in the YAML file but retains any modifications that are not specified in the file.It's particularly suited for scenarios where you might want to maintain manual adjustments or unspecified settings. 

edit replicas=1 in yaml file first, then 
```bash
# Update the replicas in the YAML file, then:
kubectl apply -f kubernetes-bootcamp.yaml

```

Benefits:

Version Controlled: Can be version-controlled if using a local YAML file, allowing for tracking of changes and rollbacks.
Reviewable: Changes can be reviewed by team members before applying if part of a GitOps workflow.

### Directly update yaml file with  kubectl replace 

The kubectl replace -f command replaces a resource with the new state defined in the YAML file. If the resource doesn't exist, the command fails. This command requires that the resource be defined completely in the file being applied because it replaces the existing configuration with the new one provided.

Deletion and Recreation: Under the hood, replace effectively deletes and then recreates the resource, which can lead to downtime for stateful applications or services. This method does not preserve unspecified fields or previous modifications made outside the YAML file.

Usage: Use kubectl replace -f when you want to overwrite the resource entirely, and you are certain that the YAML file represents the complete and desired state of the resource.

edit replicas=1 in yaml file first, then 
```bash
# Update the replicas in the YAML file, then:
kubectl replace -f kubernetes-bootcamp.yaml
```

Risk of Downtime: For some resources, using kubectl replace can cause downtime since it may delete and recreate the resource, depending on the type and changes made. It's important to use this command with caution, especially for critical resources in production environments.




Summary 

- kubectl scale: Quickly scales the number of replicas for a deployment, ideal for immediate, ad-hoc adjustments.

- kubectl edit: Offers an interactive way to scale by manually editing the deployment's YAML definition in a text editor, providing a chance to review and adjust other configurations simultaneously.

- kubectl patch: Efficiently updates the replicas count with a single command, suitable for scripts and automation without altering the rest of the deployment's configuration.

- kubectl replace -f: Replaces the entire deployment with a new configuration from a YAML file, used when you have a prepared configuration that includes the desired replicas count.

- kubectl apply -f: Applies changes from a YAML file to the deployment, allowing for version-controlled and incremental updates, including scaling operations.

Let's explore how to automatically scale your deployment based on resource usage.


### Using kubectl autoscale

When kubernetes has **Resouce Metrics API** installed,  We can using the kubectl autoscale command `kubectl autoscale deployment` to automatically scale a deployment based on CPU utilization (or any other metric) requires that the Kubernetes Metrics Server (or an equivalent metrics API) is installed and operational in your cluster. The Metrics Server collects resource metrics from Kubelets and exposes them in the Kubernetes API server through the Metrics API for use by Horizontal Pod Autoscaler (HPA) and other components.


using the kubectl autoscale command to automatically scale a deployment based on CPU utilization (or any other metric) requires that the Kubernetes Metrics Server (or an equivalent metrics API) is installed and operational in your cluster. The Metrics Server collects resource metrics from Kubelets and exposes them in the Kubernetes API server through the Metrics API for use by Horizontal Pod Autoscaler (HPA) and other components.


#### Enable resource-API 

The Resource Metrics API in Kubernetes is crucial for providing core metrics about pods and nodes within a cluster, such as CPU and memory usage to enable feature like Horizontal Pod Autoscaler (HPA), Vertical Pod Autoscaler (VPA) and enable efficent resource scheduling.

```
curl  --insecure --retry 3 --retry-connrefused -fL "https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml" -o components.yaml
sed -i '/- --metric-resolution/a \ \ \ \ \ \ \ \ - --kubelet-insecure-tls' components.yaml

kubectl apply -f components.yaml
kubectl rollout status deployment metrics-server -n kube-system
```
 
use `kubectl top node` and `kubectl top pod` to check the pod and node resource usage

Benefits:

Automatic Scaling: Automatically adjusts the number of replicas based on CPU usage, without manual intervention.
Flexible: Can set minimum and maximum limits to control scaling behavior.

Use Cases:

Ideal for applications with variable loads, where manual scaling is not practical.
Great for maintaining performance during unexpected surges in traffic.

#### Create a deployment  with more constrain 

In this deployment , we add some resource restriction like memory and cpu for a POD.
when POD reach the CPU or memory limit, if HPA configured, new POD will be created according HPA policy.
- create deployment with CPU and Memory contrain

```bash
cat <<EOF | kubectl apply -f -
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

kubectl rollout status deployment nginx-deployment

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

#### Use autoscale  (HPA) to scale your application

- use kubectl command to create hpa 

Benefits:

Resource Efficiency: Dynamically allocates resources based on real-time metrics, improving resource utilization.
Resilience: Helps applications maintain performance levels during load variations.
Use Cases:

Best suited for production environments where application demand is unpredictable.
Useful for cost optimization by scaling down during low-traffic periods.

Command:

```bash
kubectl autoscale deployment nginx-deployment --name=nginx-deployment-hpa --min=1 --max=10 --cpu-percent=50



```

After run above command, use `kubectl get hpa nginx-deployment` to check deployment 
````bash
kubectl get hpa nginx-deployment
````

Expect to see

```bash
ubuntu@ubuntu22:~$ k get hpa nginx-deployment
NAME                  REFERENCE                        TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
nginx-deployment   Deployment/nginx-deployment   <unknown>/50%   1         10        1          2m1s
```




- use yaml file create hpa


```
cat << EOF | kubectl apply -f -
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-deployment
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
EOF
```
after that. use `kubectl get hpa` and `kubectl describe hpa` to check the status 


For a deeper understanding, consider using the following command to conduct further observations" 

use `kubectl get deployment nginx-deployment` to check the change of deployment. 
use `kubectl get hpa` and `kubectl describe hpa` to check the new size of replicas.

 


#### send http traffic to application 

since the nginx-deployment service is cluster-ip type service which can only be accessed from cluster internal, so we need to create a POD which can send http traffic to nginx-deployment service.

- create deployment for generate http traffic, in this deployment, we will use wget to similuate the real traffic towards ngnix-deployment cluster-ip service which has service name `http://nginx-deployment.default.svc.cluster.local`.

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: infinite-calls
  labels:
    app: infinite-calls
spec:
  replicas: 1
  selector:
    matchLabels:
      app: infinite-calls
  template:
    metadata:
      name: infinite-calls
      labels:
        app: infinite-calls
    spec:
      containers:
      - name: infinite-calls
        image: busybox
        command:
        - /bin/sh
        - -c
        - "while true; do wget -q -O- http://nginx-deployment.default.svc.cluster.local; sleep 1; done"
```

- check the creation of busybox deployment 

```bash
kubectl get deployment infinite-calls
```
check the log from infinite-calls pods.
```bash
kubectl logs -f po/infinite-calls-9d45c57b7-h5qjd
```
you will see the response from nginx web server container.

use `ctr-c` to exist `kubectl logs -f` command.


after a while, when the traffic to nginx pod decreased, check hpa and deployment again for the size of replicas.
use `kubectl top pod` and `kubectl top node` to check the resource usage status
user expected to see the number of pod increased 

 
you shall see that expected pod now increased automatically without use attention.
```bash
ubuntu@ubuntu22:~$ kubectl get pod
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-55c7f467f8-8j2wg   1/1     Running   0          65s
nginx-deployment-55c7f467f8-gl8tf   1/1     Running   0          9m54s
nginx-deployment-55c7f467f8-jqzmt   1/1     Running   0          50s
nginx-deployment-55c7f467f8-kcrs8   1/1     Running   0          65s
nginx-deployment-55c7f467f8-l446l   1/1     Running   0          9m54s
nginx-deployment-55c7f467f8-n4crk   1/1     Running   0          35s
nginx-deployment-55c7f467f8-qtbd4   1/1     Running   0          50s
nginx-deployment-55c7f467f8-qv2wq   1/1     Running   0          50s
nginx-deployment-55c7f467f8-tg7ts   1/1     Running   0          50s
volume-test                         1/1     Running   0          11m
```
use `kubectl get hpa` shall tell you that hpa is action  which increased the replicas from 2 to 9. 
```bash
ubuntu@ubuntu22:~$ kubectl get hpa
NAME        REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   Deployment/nginx-deployment   0%/50%    2         10        9          10m
```

after few minutes later, due to no more traffic is hitting the nginx server. hpa will scale in the number of pod to save resource. 

```bash
ubuntu@ubuntu22:~$ kubectl get hpa
NAME        REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   Deployment/nginx-deployment   0%/50%    2         10        2          14m

```

use `kubectl describe hpa` will tell you the reason why hpa scale in the number of pod.

```bash
buntu@ubuntu22:~$ kubectl describe hpa
Name:                     nginx-hpa
Namespace:                default
Labels:                   <none>
Annotations:              autoscaling.alpha.kubernetes.io/conditions:
                            [{"type":"AbleToScale","status":"True","lastTransitionTime":"2024-02-19T01:12:36Z","reason":"ReadyForNewScale","message":"recommended size...
                          autoscaling.alpha.kubernetes.io/current-metrics:
                            [{"type":"Resource","resource":{"name":"cpu","currentAverageUtilization":0,"currentAverageValue":"0"}}]
CreationTimestamp:        Mon, 19 Feb 2024 01:12:21 +0000
Reference:                Deployment/nginx-deployment
Target CPU utilization:   50%
Current CPU utilization:  0%
Min replicas:             2
Max replicas:             10
Deployment pods:          2 current / 2 desired
Events:
  Type     Reason                        Age    From                       Message
  ----     ------                        ----   ----                       -------
  Warning  FailedGetResourceMetric       15m    horizontal-pod-autoscaler  failed to get cpu utilization: did not receive metrics for any ready pods
  Warning  FailedComputeMetricsReplicas  15m    horizontal-pod-autoscaler  invalid metrics (1 invalid out of 1), first error is: failed to get cpu resource metric value: failed to get cpu utilization: did not receive metrics for any ready pods
  Normal   SuccessfulRescale             7m1s   horizontal-pod-autoscaler  New size: 4; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             6m46s  horizontal-pod-autoscaler  New size: 8; reason:
  Normal   SuccessfulRescale             6m31s  horizontal-pod-autoscaler  New size: 9; reason:
  Normal   SuccessfulRescale             2m     horizontal-pod-autoscaler  New size: 8; reason: All metrics below target
  Normal   SuccessfulRescale             90s    horizontal-pod-autoscaler  New size: 7; reason: All metrics below target
  Normal   SuccessfulRescale             60s    horizontal-pod-autoscaler  New size: 2; reason: All metrics below target
  ```
 

Summary 

Choosing the right scaling method depends on your specific needs, such as whether you need to quickly adjust resources, maintain performance under varying loads, or integrate scaling into a CI/CD pipeline. Manual methods like kubectl scale or editing the deployment are straightforward for immediate needs, while kubectl autoscale and HPA provide more dynamic, automated scaling based on actual usage, making them better suited for production environments with fluctuating workloads.


### Upgrade the deployment

Upgrading a deployment in Kubernetes, particularly changing the version of the application your pods are running, can be smoothly managed using Kubernetes' built-in strategies to ensure minimal downtime and maintain stability. The most popular strategies for upgrading a deployment are:

1. Rolling Update (Default Strategy)

How It Works: This strategy updates the pods in a rolling fashion, gradually replacing old pods with new ones. Kubernetes automatically manages this process, ensuring that a specified number of pods are running at all times during the update.
Advantages: Zero downtime, as the service remains available during the update. It allows for easy rollback in case the new version is faulty.


2. Blue/Green Deployment 
This strategy involves running two versions of the application simultaneously - the current (blue) and the new (green) versions. Once the new version is ready and tested, traffic is switched from the old version to the new version, either gradually or all at once.

3. Canary Deployment
A small portion of the traffic is gradually shifted to the new version of the application. Based on feedback and metrics, the traffic is slowly increased to the new version until it handles all the traffic.

4. ReCreate Strategy
The "Recreate" strategy is a deployment strategy in Kubernetes that is particularly useful for managing stateful applications during updates. Unlike the default "RollingUpdate" strategy, which updates pods in a rolling fashion to ensure no downtime, the "Recreate" strategy works by terminating all the existing pods before creating new ones with the updated configuration or image. 

the use case for Recreate Strategy is for stateful application  where it's critical to avoid running multiple versions of the application simultaneously.


### Performing a Rolling Update 
Objectives
Perform a rolling update using kubectl.
Updating an application
Users expect applications to be available all the time, and developers are expected to deploy new versions of them several times a day. In Kubernetes this is done with rolling updates. A rolling update allows a Deployment update to take place with zero downtime. It does this by incrementally replacing the current Pods with new ones. The new Pods are scheduled on Nodes with available resources, and Kubernetes waits for those new Pods to start before removing the old Pods.

In the previous module we scaled our application to run multiple instances. This is a requirement for performing updates without affecting application availability. By default, the maximum number of Pods that can be unavailable during the update and the maximum number of new Pods that can be created, is one. Both options can be configured to either numbers or percentages (of Pods). In Kubernetes, updates are versioned and any Deployment update can be reverted to a previous (stable) version.

Rolling updates overview

![Alt text for the image](https://kubernetes.io/docs/tutorials/kubernetes-basics/public/images/module_06_rollingupdates3.svg)


Similar to application Scaling, if a Deployment is exposed publicly, the Service will load-balance the traffic only to available Pods during the update. An available Pod is an instance that is available to the users of the application.

Rolling updates allow the following actions:

Promote an application from one environment to another (via container image updates)
Rollback to previous versions
Continuous Integration and Continuous Delivery of applications with zero downtime
If a Deployment is exposed publicly, the Service will load-balance the traffic only to available Pods during the update.


In the following interactive tutorial, we'll update our application to a new version, and also perform a rollback.

How to Perform:
```bash

kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=jocatalin/kubernetes-bootcamp:v2
kubectl rollout status deployment/kubernetes-bootcamp
```
you will see

```bash
ubuntu@ubuntu22:~$ kubectl rollout status deployment/kubernetes-bootcamp
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 5 out of 10 new replicas have been updated...
deployment "kubernetes-bootcamp" successfully rolled out

```
to rollback to old version just 
```bash
kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=gcr.io/google-samples/kubernetes-bootcamp:v1 
kubectl rollout status deployment/kubernetes-bootcamp
```
