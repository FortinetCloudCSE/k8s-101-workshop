---
title: "Task 3 - Deployments, Scaling , Upgrade Applications"
menuTitle: "Deployments, Scaling, Upgrade Applications"
chapter: false
weight: 3
---

Objective: Understand how to create and manage Deployments.
Description: Focus on Deployments as a method for deploying applications. Learn about creating Deployments, scaling them, and updating applications with zero downtime. Lab exercises include deploying a multi-replica application and performing rolling updates.


### Deploy a application with deployment 
Let's use yaml  version for `kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1`. kubernets support use yaml or json to do the deployment, which give more flexiblity than use `kubectl` cli. and also for version control.



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

After deploying the kubernetes-bootcamp application, scaling the deployment to increase the number of replicas from 1 to 10 can ensure that your application can handle increased load or provide higher availability. Kubernetes offers several methods to scale a deployment, each with its own benefits and use cases.

### Using kubectl scale
Benefits:

Immediate: This command directly changes the number of replicas in the deployment, making it a quick way to scale.
Simple: Easy to remember and use for ad-hoc scaling operations.


```bash
kubectl scale deployment kubernetes-bootcamp --replicas=10
kubectl rollout status deployment kubernetes-bootcamp
kubectl get deployment kubernetes-bootcamp
kubectl get pod -l app=kubernetes-bootcamp
```
we shall see 10 POD will be created to meet the requirment from Deployment.

```bash
ubuntu@ubuntu22:~$ kubectl get deployment
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   1/1     1            1           63m
ubuntu@ubuntu22:~$ kubectl scale deployment kubernetes-bootcamp --replicas=10
deployment.apps/kubernetes-bootcamp scaled
ubuntu@ubuntu22:~$ kubectl rollout status deployment kubernetes-bootcamp
deployment "kubernetes-bootcamp" successfully rolled out
ubuntu@ubuntu22:~$ kubectl get deployment kubernetes-bootcamp
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   10/10   10           10          64m
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
Editing the Deployment YAML File

Command:
First, edit the deployment YAML file to change the replicas value, then apply the changes:
```bash
kubectl edit deployment kubernetes-bootcamp

```

Or, if you have a local YAML file:
```bash
# Update the replicas in the YAML file, then:
kubectl apply -f kubernetes-bootcamp.yaml

```

Benefits:

Version Controlled: Can be version-controlled if using a local YAML file, allowing for tracking of changes and rollbacks.
Reviewable: Changes can be reviewed by team members before applying if part of a GitOps workflow.


Using kubectl autoscale
Command:
```bash
kubectl autoscale deployment kubernetes-bootcamp --min=1 --max=10 --cpu-percent=80
```

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


Using Horizontal Pod Autoscaler (HPA)

Command:
First, create an HPA resource targeting your deployment:

```bash
kubectl create hpa kubernetes-bootcamp-hpa --target=deployment/kubernetes-bootcamp --min-replicas=1 --max-replicas=10 --cpu-percent=80

```
Benefits:

Resource Efficiency: Dynamically allocates resources based on real-time metrics, improving resource utilization.
Resilience: Helps applications maintain performance levels during load variations.
Use Cases:

Best suited for production environments where application demand is unpredictable.
Useful for cost optimization by scaling down during low-traffic periods.

Conclusion
Choosing the right scaling method depends on your specific needs, such as whether you need to quickly adjust resources, maintain performance under varying loads, or integrate scaling into a CI/CD pipeline. Manual methods like kubectl scale or editing the deployment are straightforward for immediate needs, while kubectl autoscale and HPA provide more dynamic, automated scaling based on actual usage, making them better suited for production environments with fluctuating workloads.





####  create HPA for scale application  with Yaml


create HPA for nginx deployment, allow increase replicas upon container CPU utlization over the threshold

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
