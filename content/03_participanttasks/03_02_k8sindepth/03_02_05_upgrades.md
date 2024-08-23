---
title: "Task 5 - Upgrade Deployment"
linkTitle: "Task 5 - Upgrade Deployment"
weight: 5
---

#### Objective: Mastering Deployment Upgrades and Downgrades

Discover upgrade strategies and learn how to effectively upgrade or downgrade deployments


#### Upgrade the deployment

Upgrading a deployment in Kubernetes, particularly changing the version of the application your Pods are running, can be smoothly managed using Kubernetes' built-in strategies to ensure minimal downtime and maintain stability. The most popular strategies for upgrading a deployment are:

- Rolling Update (Default Strategy)

How It Works: This strategy updates the Pods in a rolling fashion, gradually replacing old Pods with new ones. Kubernetes automatically manages this process, ensuring that a specified number of Pods are running at all times during the update.
Advantages: Zero downtime, as the service remains available during the update. It allows for easy rollback in case the new version is faulty.


- Blue/Green Deployment 
This strategy involves running two versions of the application simultaneously - the current (blue) and the new (green) versions. Once the new version is ready and tested, traffic is switched from the old version to the new version, either gradually or all at once.

- Canary Deployment
A small portion of the traffic is gradually shifted to the new version of the application. Based on feedback and metrics, the traffic is slowly increased to the new version until it handles all the traffic.

- ReCreate Strategy
The "Recreate" strategy is a deployment strategy in Kubernetes that is particularly useful for managing stateful applications during updates. Unlike the default "RollingUpdate" strategy, which updates Pods in a rolling fashion to ensure no downtime, the "Recreate" strategy works by terminating all the existing Pods before creating new ones with the updated configuration or image. 

the use case for Recreate Strategy is for stateful application  where it's critical to avoid running multiple versions of the application simultaneously.


#### Performing a Rolling Update 

- Objectives
Perform a rolling update using kubectl.
Updating an application
Users expect applications to be available all the time, and developers are expected to deploy new versions of them several times a day. In Kubernetes this is done with rolling updates. A rolling update allows a Deployment update to take place with zero downtime. It does this by incrementally replacing the current Pods with new ones. The new Pods are scheduled on Nodes with available resources, and Kubernetes waits for those new Pods to start before removing the old Pods.

- In the previous module we scaled our application to run multiple instances. This is a requirement for performing updates without affecting application availability. By default, the maximum number of Pods that can be unavailable during the update and the maximum number of new Pods that can be created, is one. Both options can be configured to either numbers or percentages (of Pods). In Kubernetes, updates are versioned and any Deployment update can be reverted to a previous (stable) version.

- Rolling updates overview

![Alt text for the image](https://kubernetes.io/docs/tutorials/kubernetes-basics/public/images/module_06_rollingupdates3.svg)


- Similar to application Scaling, if a Deployment is exposed publicly, the Service will load-balance the traffic only to available Pods during the update. An available Pod is an instance that is available to the users of the application.

- Rolling updates allow the following actions:

- Promote an application from one environment to another (via container image updates)
Rollback to previous versions
Continuous Integration and Continuous Delivery of applications with zero downtime

- If a Deployment is exposed publicly, the Service will load-balance the traffic only to available Pods during the update.


- In the following interactive tutorial, we'll update our application to a new version, and also perform a rollback.

#### Perform Rolling Update

1. Create deployment with image set to kubernetes-bootcamp:v1

```bash
kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1 --replicas=4
kubectl expose deployment kubernetes-bootcamp --target-port=8080 --port=80
```

2.  Verify the deployment 
```bash
kubectl get deployment
```

Expected outcome
```
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   4/4   4           4          23s
```

3. check the service 

use curlpod from cluster-internal to check the service
```bash
kubectl run curlpod --image=appropriate/curl --restart=Never --rm -it --  curl  http://kubernetes-bootcamp.default.svc.cluster.local
```

expected outcome showing v=1
```
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5485cc6795-4m7p9 | v=1
pod "curlpod" deleted
```

4. upgrade deployment 

Upgrade the deployment with image set to kubernetes-bootcamp:v2

```bash
kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=jocatalin/kubernetes-bootcamp:v2
kubectl rollout status deployment/kubernetes-bootcamp
```

expected outcome
```
deployment.apps/kubernetes-bootcamp image updated
Waiting for deployment spec update to be observed...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 2 old replicas are pending termination...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 old replicas are pending termination...
deployment "kubernetes-bootcamp" successfully rolled out
```
you can find above that create new replicas first then delete old replicas to avoid service disruption.


5. check the service

check the service use curlpod
```bash
kubectl run curlpod --image=appropriate/curl --restart=Never --rm -it --  curl  http://kubernetes-bootcamp.default.svc.cluster.local
```

expected outcome showing v=2
```
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-7c6644499c-lsxm9 | v=2
```


6. rollback to old version

To rollback to orignal version, simple change the container image

```bash
kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=gcr.io/google-samples/kubernetes-bootcamp:v1 
kubectl rollout status deployment/kubernetes-bootcamp
```

expected outcome

```
kubectl rollout status deployment/kubernetes-bootcamp
deployment.apps/kubernetes-bootcamp image updated
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 0 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 0 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 1 old replicas are pending termination...
deployment "kubernetes-bootcamp" successfully rolled out
```

7. check the service use curlpod
```bash
kubectl run curlpod --image=appropriate/curl --restart=Never --rm -it --  curl  http://kubernetes-bootcamp.default.svc.cluster.local
```

expected outcome showing v=1
```
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5485cc6795-gvw6l | v=1
pod "curlpod" deleted
```

#### Restart the deployment

- Restarting a deployment using kubectl rollout restart deployment <deployment-name> can be necessary or beneficial for Refreshing the Application, Troubleshooting etc  in a Kubernetes environment. 

1. check existing deployment 
```bash
kubectl get pod -o wide -l app=kubernetes-bootcamp
```
expected output 
```
NAME                                   READY   STATUS    RESTARTS   AGE     IP               NODE          NOMINATED NODE   READINESS GATES
kubernetes-bootcamp-5485cc6795-brnv6   1/1     Running   0          4m54s   10.244.152.110   node-worker   <none>           <none>
kubernetes-bootcamp-5485cc6795-hqkd9   1/1     Running   0          4m54s   10.244.152.109   node-worker   <none>           <none>
kubernetes-bootcamp-5485cc6795-qb2jh   1/1     Running   0          4m55s   10.244.152.108   node-worker   <none>           <none>
kubernetes-bootcamp-5485cc6795-zgcrd   1/1     Running   0          4m55s   10.244.152.107   node-worker   <none>           <none>
```
2. restart the deployment

Restart the deployment with default rolling update. 

```bash
kubectl rollout restart deployment kubernetes-bootcamp
```

3. Verify the deployment

```bash
kubectl rollout status deployment kubernetes-bootcamp
```

expected output
```
deployment "kubernetes-bootcamp" successfully rolled out
```
4. Verify the deployment after restart 

```bash
kubectl get pod -o wide -l app=kubernetes-bootcamp
```
expected output

```
NAME                                  READY   STATUS    RESTARTS   AGE    IP               NODE          NOMINATED NODE   READINESS GATES
kubernetes-bootcamp-d9f576d69-2q27m   1/1     Running   0          110s   10.244.152.113   node-worker   <none>           <none>
kubernetes-bootcamp-d9f576d69-dwwc2   1/1     Running   0          110s   10.244.152.112   node-worker   <none>           <none>
kubernetes-bootcamp-d9f576d69-hhqqm   1/1     Running   0          108s   10.244.152.114   node-worker   <none>           <none>
kubernetes-bootcamp-d9f576d69-w5tpc   1/1     Running   0          108s   10.244.152.115   node-worker   <none>           <none>
``` 
Notice that the Pod's IP address has changed, and the deployment's **Pod template hash** has also been updated to new prefix (d9f576d69). This indicates that all resources have been recreated following the kubectl rollout restart command.




#### clean up

```bash
kubectl delete svc kubernetes-bootcamp
kubectl delete deployment kubernetes-bootcamp
```


#### Review and Questions

1. Use `kubectl run` to create a POD with juice-shop image and add a label owner=dev 

2. Use `kubectl create deployment` to create a deployment for juice-shop with replicas=2 and image=bkimminich/juice-shop:v15.0.0

3. scale out juice-shop deployment from 2 replicas to 6 replicas 

4. use rolling upgrade to upgrade your juice-shop deployment to use version v16.0.0.

5. Use `kubectl` to find the specifcation for imagePullPolicy which is need for create a deployment.  and set the juice-shop deployment container imagePullPolicy to use "IfNotPresent".
 
