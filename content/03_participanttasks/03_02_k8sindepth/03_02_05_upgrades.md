---
title: "Task 5 - Upgrade"
menuTitle: "Task 5 - Upgrade"
weight: 5
---

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

1. Objectives
Perform a rolling update using kubectl.
Updating an application
Users expect applications to be available all the time, and developers are expected to deploy new versions of them several times a day. In Kubernetes this is done with rolling updates. A rolling update allows a Deployment update to take place with zero downtime. It does this by incrementally replacing the current Pods with new ones. The new Pods are scheduled on Nodes with available resources, and Kubernetes waits for those new Pods to start before removing the old Pods.

2. In the previous module we scaled our application to run multiple instances. This is a requirement for performing updates without affecting application availability. By default, the maximum number of Pods that can be unavailable during the update and the maximum number of new Pods that can be created, is one. Both options can be configured to either numbers or percentages (of Pods). In Kubernetes, updates are versioned and any Deployment update can be reverted to a previous (stable) version.

3. Rolling updates overview

![Alt text for the image](https://kubernetes.io/docs/tutorials/kubernetes-basics/public/images/module_06_rollingupdates3.svg)


4. Similar to application Scaling, if a Deployment is exposed publicly, the Service will load-balance the traffic only to available Pods during the update. An available Pod is an instance that is available to the users of the application.

5. Rolling updates allow the following actions:

6. Promote an application from one environment to another (via container image updates)
Rollback to previous versions
Continuous Integration and Continuous Delivery of applications with zero downtime

7. If a Deployment is exposed publicly, the Service will load-balance the traffic only to available Pods during the update.


8. In the following interactive tutorial, we'll update our application to a new version, and also perform a rollback.


9. **How to Perform:**

10. create deployment with image set to kubernetes-bootcamp:v1

```bash
kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1 --replicas=4
kubectl expose deployment kubernetes-bootcamp --target-port=8080 --port=80

```

11. check status 
```bash
kubectl get deployment
```

12. Expected outcome
```
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
kubernetes-bootcamp   4/4   4           4          23s
```

13. check the service use curlpod from cluster-internal
```bash
kubectl run curlpod --image=appropriate/curl --restart=Never --rm -it --  curl  http://kubernetes-bootcamp.default.svc.cluster.local
```

14. expected outcome showing v=1
```
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5485cc6795-4m7p9 | v=1
pod "curlpod" deleted
```

15. upgrade deployment with image set to kubernetes-bootcamp:v2

```bash
kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=jocatalin/kubernetes-bootcamp:v2
kubectl rollout status deployment/kubernetes-bootcamp
```

16. expected outcome
```
$ kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=jocatalin/kubernetes-bootcamp:v2
kubectl rollout status deployment/kubernetes-bootcamp
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

17. you can find above that create new replicas first then delete old replicas so avoid service disruption.

check the service use curlpod
```bash
kubectl run curlpod --image=appropriate/curl --restart=Never --rm -it --  curl  http://kubernetes-bootcamp.default.svc.cluster.local
```

18. expected outcome showing v=2
```
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-7c6644499c-lsxm9 | v=2
```


19. rollback to old version: to rollback to orignal version, use 

```bash
kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=gcr.io/google-samples/kubernetes-bootcamp:v1 
kubectl rollout status deployment/kubernetes-bootcamp
```

20. expected outcome

```
$ kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=gcr.io/google-samples/kubernetes-bootcamp:v1 
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

21. check the service use curlpod
```bash
kubectl run curlpod --image=appropriate/curl --restart=Never --rm -it --  curl  http://kubernetes-bootcamp.default.svc.cluster.local
```

22. expected outcome showing v=1
```
Hello Kubernetes bootcamp! | Running on: kubernetes-bootcamp-5485cc6795-gvw6l | v=1
pod "curlpod" deleted
```

### Restart the deployment

1. Restarting a deployment using kubectl rollout restart deployment <deployment-name> can be necessary or beneficial for Refreshing the Application, Troubleshooting etc  in a Kubernetes environment. 

2. before restart 
```bash
kubectl get pod -o wide -l app=kubernetes-bootcamp
```
3. expected output 
```
NAME                                   READY   STATUS    RESTARTS   AGE     IP               NODE          NOMINATED NODE   READINESS GATES
kubernetes-bootcamp-5485cc6795-brnv6   1/1     Running   0          4m54s   10.244.152.110   node-worker   <none>           <none>
kubernetes-bootcamp-5485cc6795-hqkd9   1/1     Running   0          4m54s   10.244.152.109   node-worker   <none>           <none>
kubernetes-bootcamp-5485cc6795-qb2jh   1/1     Running   0          4m55s   10.244.152.108   node-worker   <none>           <none>
kubernetes-bootcamp-5485cc6795-zgcrd   1/1     Running   0          4m55s   10.244.152.107   node-worker   <none>           <none>
```
4. then restart the deployment with rolling update. 

```bash
kubectl rollout restart deployment kubernetes-bootcamp
```

5. use `kubectl rollout status deployment kubernetes-bootcamp`  to check the restart status

expected output
```
deployment "kubernetes-bootcamp" successfully rolled out
```
then check the deployment again
```bash
kubectl get pod -o wide -l app=kubernetes-bootcamp
```
6. expected output

```
NAME                                  READY   STATUS    RESTARTS   AGE    IP               NODE          NOMINATED NODE   READINESS GATES
kubernetes-bootcamp-d9f576d69-2q27m   1/1     Running   0          110s   10.244.152.113   node-worker   <none>           <none>
kubernetes-bootcamp-d9f576d69-dwwc2   1/1     Running   0          110s   10.244.152.112   node-worker   <none>           <none>
kubernetes-bootcamp-d9f576d69-hhqqm   1/1     Running   0          108s   10.244.152.114   node-worker   <none>           <none>
kubernetes-bootcamp-d9f576d69-w5tpc   1/1     Running   0          108s   10.244.152.115   node-worker   <none>           <none>
``` 
you might noticed that POD ip address has changed. POD has been refreshed.


### clean up

```bash
kubectl delete svc kubernetes-bootcamp
kubectl delete deployment kubernetes-bootcamp
```


### Review and Questions

1.  Use `kubectl run` to create a POD with juice-shop image and add a label owner=dev 
Use `kubectl create deployment` to create a deployment for juice-shop

**Answer:**

- Create a yaml file for juice-shop deployment with 2 replicas and use `kubectl create -f` to create the deployment  with juice-shop image bkimminich/juice-shop:v15.0.0

- scale out juice-shop deployment from 2 replicas to 6 replicas 

2. use rolling upgrade to upgrade your juice-shop deployment to use version v16.0.0.

**Answer:**

```bash
kubectl set image deployment juice-shop juice-shop=bkimminich/juice-shop:v16.0.0
```

3. Use `kubectl` to find the specifcation for imagePullPolicy which is need for create a deployment.  and set the juice-shop deployment container imagePullPolicy to use "IfNotPresent".

**Answer:**

```bash
kubectl explain deployment.spec.template.spec.containers.imagePullPolicy
```

```bash
Always, Never, IfNotPresent
```
