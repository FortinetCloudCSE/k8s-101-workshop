---
title: "Task 4 - Auto Scaling Deployment"
linkTitle: "Task 4 - Auto Scaling Deployment"
weight: 4
---

#### Objective: Automate Deployment Scaling with HPA

Learn to configure the Horizontal Pod Autoscaler (HPA) for a deployment and simulate traffic to test scaling.


#### Using kubectl autoscale

When Kubernetes has **Resouce Metrics API** installed,  We can using the kubectl autoscale command `kubectl autoscale deployment` to automatically scale a deployment based on CPU utilization (or any other metric) requires that the Kubernetes Metrics Server (or an equivalent metrics API) is installed and operational in your cluster. The Metrics Server collects resource metrics from Kubelets and exposes them in the Kubernetes API server through the Metrics API for use by Horizontal Pod Autoscaler (HPA) and other components.


using the kubectl autoscale command to automatically scale a deployment based on CPU utilization (or any other metric) requires that the Kubernetes Metrics Server (or an equivalent metrics API) is installed and operational in your cluster. The Metrics Server collects resource metrics from Kubelets and exposes them in the Kubernetes API server through the Metrics API for use by Horizontal Pod Autoscaler (HPA) and other components.

#### Enable resource-API 

The Resource Metrics API in Kubernetes is crucial for providing core metrics about Pods and nodes within a cluster, such as CPU and memory usage to enable feature like Horizontal Pod Autoscaler (HPA), Vertical Pod Autoscaler (VPA) and enable efficent resource scheduling.

1. copy/paste below command to enable resource-api
```bash
curl  --insecure --retry 3 --retry-connrefused -fL "https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml" -o components.yaml
sed -i '/- --metric-resolution/a \ \ \ \ \ \ \ \ - --kubelet-insecure-tls' components.yaml

kubectl apply -f components.yaml
kubectl rollout status deployment metrics-server -n kube-system
```

use `kubectl top node` and `kubectl top pod` to check the Pod and node resource usage

#### Create a deployment  with resource constrain 

- In this deployment , we add some resource restriction like memory and cpu for a POD.

- when POD reach the CPU or memory limit, if HPA configured, new POD will be created according HPA policy.

2. create deployment with CPU and Memory constraints
{{< tabs >}}
{{% tab title="create resource constrained deployment" %}}


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
{{% /tab %}}
{{% tab title="check " %}}
check the deployment and service

```bash
kubectl get deployment nginx-deployment
kubectl get svc nginx-deployment
```
{{% /tab %}}
{{< /tabs >}}

#### Use autoscale  (HPA) to scale your application

3. We can use `kubectl autoscale` command or use create a hpa yaml file then follow a `kubectl apply -f` to create hpa.

{{< tabs >}}
{{% tab title="kubectl hpa create" %}}
use kubectl command to create hpa 

```bash
kubectl autoscale deployment nginx-deployment --name=nginx-deployment-hpa --min=2 --max=10 --cpu-percent=50  --save-config
```
{{% /tab %}}
{{% tab title="Expected Output kubectl" style="info" %}}
 expected Outcome
```
horizontalpodautoscaler.autoscaling/nginx-deployment-hpa autoscaled
```
{{% /tab %}}
{{% tab title="ALT Yamlfile hpa create" %}}

**or** use yaml file to create hpa

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
{{% /tab %}}
{{< /tabs >}}
- **Target CPU Utilization**: This is set to 50%. It means the HPA will aim to adjust the number of Pods so that the average CPU utilization across all Pods is around 50% of the allocated CPU resources for each Pod.
- **Scaling Out**: If the average CPU utilization across all Pods in the nginx-deployment exceeds 50%, the HPA will increase the number of Pods, making more resources available to handle the workload, until it reaches the maximum limit of 10 Pods.
- **Scaling In**: If the average CPU utilization drops below 50%, indicating that the resources are underutilized, the HPA will decrease the number of Pods to reduce resource usage, but it won't go below the minimum of 2 Pod.


4. Check Result 

{{< tabs >}}
{{% tab title="Check" %}}

use `kubectl get hpa nginx-deployment-hpa` to check deployment 
````bash
kubectl get hpa nginx-deployment-hpa
````
{{% /tab %}}
{{% tab title="Expected Output" style="info" %}}

Expected Outcome

```
NAME                   REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-deployment-hpa   Deployment/nginx-deployment   0%/50%    2         10        2          23s
```
{{% /tab %}}
{{< /tabs >}}
For a deeper understanding, consider using the following command to conduct further observations" 

use `kubectl get deployment nginx-deployment` to check the change of deployment. 
use `kubectl get hpa` and `kubectl describe hpa` to check the  size of replicas.


#### Send http traffic to application 

since the nginx-deployment service is cluster-ip type service which can only be accessed from cluster internal, so we need to create a POD which can send http traffic to nginx-deployment service.

5. create deployment for generate http traffic, in this deployment, we will use wget to similuate the real traffic towards ngnix-deployment cluster-ip service which has service name `http://nginx-deployment.default.svc.cluster.local`.

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

6. check the creation of infinite-calls deployment 

```bash
kubectl get deployment infinite-calls
```
7. check the log from infinite-calls Pods.
{.items[0]} means use first Pod 

```bash
podName=$(kubectl get pod -l app=infinite-calls -o=jsonpath='{.items[0].metadata.name}')
kubectl logs  po/$podName
```
you will see the response from nginx web server container. use ctr-c to stop.


use `kubectl top pod` and `kubectl top node` to check the resource usage status
user expected to see the number of Pod increased 

 
8. You shall see that expected Pod now increased automatically without use attention.
{{< tabs >}}
{{% tab title="check" %}}
```bash
kubectl get pod -l app=nginx
```
{{% /tab %}}
{{% tab title="Expected Output" style="info" %}}
expected outcome
```
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-55c7f467f8-f2qbp   1/1     Running   0          19m
nginx-deployment-55c7f467f8-hxs79   1/1     Running   0          2m2s
nginx-deployment-55c7f467f8-jx2k9   1/1     Running   0          19m
nginx-deployment-55c7f467f8-r7vdv   1/1     Running   0          3m2s
nginx-deployment-55c7f467f8-w6r8l   1/1     Running   0          3m17s
```

{{% /tab %}}
{{< /tabs >}}
9. Use `kubectl get hpa` shall tell you that hpa is action  which increased the replicas from 2 to other numbers. 
{{< tabs >}}
{{% tab title="get hpa" %}}
```bash
kubectl get hpa
```
{{% /tab %}}
{{% tab title="Expected Output" style="info" %}}

expected outcome 
```
NAME        REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-deployment-hpa   Deployment/nginx-deployment   50%/50%   2         10        5          11m
```
{{% /tab %}}
{{< /tabs >}}
10. check hpa detail
{{< tabs >}}
{{% tab title="hpa detail" %}}
```bash
kubectl describe hpa
```
{{% /tab %}}
{{% tab title="Expected Output" style="info" %}}
expected outcome

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
{{% /tab %}}
{{< /tabs >}}

11. delete infinite-calls to stop generate the traffic
{{< tabs >}}
{{% tab title="delete" %}}
```bash
kubectl delete deployment infinite-calls
```
{{% /tab %}}
{{% tab title="verify" %}}

after few minutes later, due to no more traffic is hitting the nginx server. hpa will scale in the number of Pod to save resource. 

```bash
kubectl get hpa
```
{{% /tab %}}
{{% tab title="Expected Output" style="info" %}}

expected output
```
NAME        REFERENCE                     TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-deployment-hpa   Deployment/nginx-deployment   0%/50%   2         10        5          12m

```
{{% /tab %}}
{{< /tabs >}}
12. use `kubectl describe hpa` will tell you the reason why hpa scale in the number of Pod.

{{< tabs >}}
{{% tab title="describe hpa" %}}

```bash
kubectl describe hpa
```
{{% /tab %}}
{{% tab title="Expected Output" style="info" %}}
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
{{% /tab %}}
{{< /tabs >}}
#### clean up

```bash
kubectl delete hpa nginx-deployment-hpa
kubectl delete deployment nginx-deployment
kubectl delete svc nginx-deployment
```

#### Summary 

Choosing the right scaling method depends on your specific needs, such as whether you need to quickly adjust resources, maintain performance under varying loads, or integrate scaling into a CI/CD pipeline. Manual methods like kubectl scale or editing the deployment are straightforward for immediate needs, while kubectl autoscale and HPA provide more dynamic, automated scaling based on actual usage, making them better suited for production environments with fluctuating workloads.
