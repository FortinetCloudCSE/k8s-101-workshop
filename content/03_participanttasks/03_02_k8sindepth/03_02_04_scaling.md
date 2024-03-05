---
title: "Task 4 - Scaling"
menuTitle: "Task 4 - Scaling"
weight: 4
---

#### Using kubectl autoscale

When kubernetes has **Resouce Metrics API** installed,  We can using the kubectl autoscale command `kubectl autoscale deployment` to automatically scale a deployment based on CPU utilization (or any other metric) requires that the Kubernetes Metrics Server (or an equivalent metrics API) is installed and operational in your cluster. The Metrics Server collects resource metrics from Kubelets and exposes them in the Kubernetes API server through the Metrics API for use by Horizontal Pod Autoscaler (HPA) and other components.


using the kubectl autoscale command to automatically scale a deployment based on CPU utilization (or any other metric) requires that the Kubernetes Metrics Server (or an equivalent metrics API) is installed and operational in your cluster. The Metrics Server collects resource metrics from Kubelets and exposes them in the Kubernetes API server through the Metrics API for use by Horizontal Pod Autoscaler (HPA) and other components.

#### Enable resource-API 

The Resource Metrics API in Kubernetes is crucial for providing core metrics about pods and nodes within a cluster, such as CPU and memory usage to enable feature like Horizontal Pod Autoscaler (HPA), Vertical Pod Autoscaler (VPA) and enable efficent resource scheduling.

```bash
curl  --insecure --retry 3 --retry-connrefused -fL "https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml" -o components.yaml
sed -i '/- --metric-resolution/a \ \ \ \ \ \ \ \ - --kubelet-insecure-tls' components.yaml

kubectl apply -f components.yaml
kubectl rollout status deployment metrics-server -n kube-system
```

use `kubectl top node` and `kubectl top pod` to check the pod and node resource usage

#### Create a deployment  with resource constrain 

1. In this deployment , we add some resource restriction like memory and cpu for a POD.

2. when POD reach the CPU or memory limit, if HPA configured, new POD will be created according HPA policy.

3. create deployment with CPU and Memory contrain

```bash
cat <<EOF | tee nginx-deployment_resource.yaml
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
kubectl apply -f nginx-deployment_resource.yaml
kubectl rollout status deployment nginx-deployment

cat << EOF | tee nginx-deployment_clusterIP.yaml
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
kubectl apply -f nginx-deployment_clusterIP.yaml
```
check the deployment and service
```bash
kubectl get deployment nginx-deployment
kubectl get svc nginx-deployment
```

#### Use autoscale  (HPA) to scale your application

1. We can use `kubectl autoscale` command or use create a hpa yaml file then follow a `kubectl apply -f` to create hpa.

2. use kubectl command to create hpa 

3. Command:

```bash
kubectl autoscale deployment nginx-deployment --name=nginx-deployment-hpa --min=2 --max=10 --cpu-percent=50  --save-config
```

4. expected Outcome
```
horizontalpodautoscaler.autoscaling/nginx-deployment-hpa autoscaled
```

5. **or** use yaml file to create hpa

```bash
cat << EOF | tee > nginx-deployment-hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-deployment-hpa
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
kubectl apply -f nginx-deployment-hpa.yaml
```

- **Target CPU Utilization**: This is set to 50%. It means the HPA will aim to adjust the number of pods so that the average CPU utilization across all pods is around 50% of the allocated CPU resources for each pod.
- **Scaling Out**: If the average CPU utilization across all pods in the nginx-deployment exceeds 50%, the HPA will increase the number of pods, making more resources available to handle the workload, until it reaches the maximum limit of 10 pods.
- **Scaling In**: If the average CPU utilization drops below 50%, indicating that the resources are underutilized, the HPA will decrease the number of pods to reduce resource usage, but it won't go below the minimum of 2 pod.


6. Check Result 

use `kubectl get hpa nginx-deployment` to check deployment 
````bash
kubectl get hpa nginx-deployment-hpa
````

7. Expected Outcome

```
NAME                   REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-deployment-hpa   Deployment/nginx-deployment   0%/50%    2         10        2          23s
```

8. For a deeper understanding, consider using the following command to conduct further observations" 

use `kubectl get deployment nginx-deployment` to check the change of deployment. 
use `kubectl get hpa` and `kubectl describe hpa` to check the  size of replicas.


#### Send http traffic to application 

since the nginx-deployment service is cluster-ip type service which can only be accessed from cluster internal, so we need to create a POD which can send http traffic to nginx-deployment service.

1. create deployment for generate http traffic, in this deployment, we will use wget to similuate the real traffic towards ngnix-deployment cluster-ip service which has service name `http://nginx-deployment.default.svc.cluster.local`.

```bash
cat <<EOF | tee infinite-calls-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: infinite-calls
  labels:
    app: infinite-calls
spec:
  replicas: 2
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
        - "while true; do wget -q -O- http://nginx-deployment.default.svc.cluster.local; done"
EOF
kubectl apply -f infinite-calls-deployment.yaml
```

2. check the creation of busybox deployment 

```bash
kubectl get deployment infinite-calls
```
3. check the log from infinite-calls pods.
{.items[0]} means use first pod 

```bash
podName=$(kubectl get pod -l app=infinite-calls -o=jsonpath='{.items[0].metadata.name}')
kubectl logs  po/$podName
```
4. you will see the response from nginx web server container. use ctr-c to stop.


5. use `kubectl top pod` and `kubectl top node` to check the resource usage status
user expected to see the number of pod increased 

 
6. you shall see that expected pod now increased automatically without use attention.
```bash
kubectl get pod -l app=nginx
```

7. expected outcome
```
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-55c7f467f8-f2qbp   1/1     Running   0          19m
nginx-deployment-55c7f467f8-hxs79   1/1     Running   0          2m2s
nginx-deployment-55c7f467f8-jx2k9   1/1     Running   0          19m
nginx-deployment-55c7f467f8-r7vdv   1/1     Running   0          3m2s
nginx-deployment-55c7f467f8-w6r8l   1/1     Running   0          3m17s
```
8. use `kubectl get hpa` shall tell you that hpa is action  which increased the replicas from 2 to other numbers. 
```bash
kubectl get hpa
```

9. expected outcome 
```
NAME        REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-deployment-hpa   Deployment/nginx-deployment   50%/50%   2         10        5          11m
```

10. check hpa detail

```bash
kubectl describe hpa
```

11. expected outcome

```
Name:                     nginx-deployment-hpa
Namespace:                default
Labels:                   <none>
Annotations:              autoscaling.alpha.kubernetes.io/conditions:
                            [{"type":"AbleToScale","status":"True","lastTransitionTime":"2024-02-22T07:57:16Z","reason":"ReadyForNewScale","message":"recommended size...
                          autoscaling.alpha.kubernetes.io/current-metrics:
                            [{"type":"Resource","resource":{"name":"cpu","currentAverageUtilization":48,"currentAverageValue":"4m"}}]
CreationTimestamp:        Thu, 22 Feb 2024 07:57:01 +0000
Reference:                Deployment/nginx-deployment
Target CPU utilization:   50%
Current CPU utilization:  48%
Min replicas:             2
Max replicas:             10
Deployment pods:          5 current / 5 desired
Events:
  Type    Reason             Age    From                       Message
  ----    ------             ----   ----                       -------
  Normal  SuccessfulRescale  4m28s  horizontal-pod-autoscaler  New size: 3; reason: cpu resource utilization (percentage of request) above target
  Normal  SuccessfulRescale  4m13s  horizontal-pod-autoscaler  New size: 4; reason: cpu resource utilization (percentage of request) above target
  Normal  SuccessfulRescale  3m13s  horizontal-pod-autoscaler  New size: 5; reason: cpu resource utilization (percentage of request) above target
```


12. delete infinite-calls to stop generate the traffic

```bash
kubectl delete deployment infinite-calls
```

13. after few minutes later, due to no more traffic is hitting the nginx server. hpa will scale in the number of pod to save resource. 

```bash
kubectl get hpa
```

14. expected output
```
NAME        REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-deployment-hpa   Deployment/nginx-deployment   0%/50%   2         10        5          12m

```

15. use `kubectl describe hpa` will tell you the reason why hpa scale in the number of pod.

```bash
kubectl describe hpa
```

expected outcome
```
Name:                     nginx-deployment-hpa
Namespace:                default
Labels:                   <none>
Annotations:              autoscaling.alpha.kubernetes.io/conditions:
                            [{"type":"AbleToScale","status":"True","lastTransitionTime":"2024-02-22T07:57:16Z","reason":"ReadyForNewScale","message":"recommended size...
                          autoscaling.alpha.kubernetes.io/current-metrics:
                            [{"type":"Resource","resource":{"name":"cpu","currentAverageUtilization":0,"currentAverageValue":"0"}}]
CreationTimestamp:        Thu, 22 Feb 2024 07:57:01 +0000
Reference:                Deployment/nginx-deployment
Target CPU utilization:   50%
Current CPU utilization:  0%
Min replicas:             2
Max replicas:             10
Deployment pods:          2 current / 2 desired
Events:
  Type    Reason             Age    From                       Message
  ----    ------             ----   ----                       -------
  Normal  SuccessfulRescale  13m    horizontal-pod-autoscaler  New size: 3; reason: cpu resource utilization (percentage of request) above target
  Normal  SuccessfulRescale  13m    horizontal-pod-autoscaler  New size: 4; reason: cpu resource utilization (percentage of request) above target
  Normal  SuccessfulRescale  12m    horizontal-pod-autoscaler  New size: 5; reason: cpu resource utilization (percentage of request) above target
  Normal  SuccessfulRescale  7m55s  horizontal-pod-autoscaler  New size: 8; reason: cpu resource utilization (percentage of request) above target
  Normal  SuccessfulRescale  54s    horizontal-pod-autoscaler  New size: 5; reason: All metrics below target
  Normal  SuccessfulRescale  39s    horizontal-pod-autoscaler  New size: 2; reason: All metrics below target
```
### clean up

```bash
kubectl delete hpa nginx-deployment-hpa
kubectl delete deployment nginx-deployment
kubectl delete svc nginx-deployment
```

### Summary 

Choosing the right scaling method depends on your specific needs, such as whether you need to quickly adjust resources, maintain performance under varying loads, or integrate scaling into a CI/CD pipeline. Manual methods like kubectl scale or editing the deployment are straightforward for immediate needs, while kubectl autoscale and HPA provide more dynamic, automated scaling based on actual usage, making them better suited for production environments with fluctuating workloads.
