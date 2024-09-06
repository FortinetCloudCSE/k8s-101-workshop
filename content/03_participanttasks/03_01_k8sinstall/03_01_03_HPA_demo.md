---
title: "Task 2 - Deploy and Scalling Application"
linkTitle: "Task 2 - Scaling Application"
weight: 2 
---

## Objective


A quick demo using a few commands to demonstrate how Kubernetes can scale to handle increased web traffic.
These include 
- Creating a client deployment to simulate HTTP traffic.
- Setting up a web application with auto-scaling using Horizontal Pod Autoscaler (HPA).

1. Deploy Demo Application and enable auto scalling (HPA)
{{< tabs >}}
{{% tab title="deploy" %}}
The Deployed demo application include two Pods but able to auto scale if coming traffic reach certain limit.
    
```bash
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
sed -i "s/localhost/$nodename/g" $HOME/k8s-101-workshop/scripts/deploy_application_with_hpa_masternode.sh
ssh -o 'StrictHostKeyChecking=no' $username@$nodename < $HOME/k8s-101-workshop/scripts/deploy_application_with_hpa_masternode.sh
 
```
{{% /tab %}}
{{% tab title="Check" %}}

use `kubectl get pod` to check deployment.
    
```bash
kubectl get pod
```
{{% /tab %}}
{{% tab title="Expected Output" style="info" %}}
expected outcome
    
```
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-55c7f467f8-q26f2   1/1     Running   0          9m53s
nginx-deployment-55c7f467f8-rfdck   1/1     Running   0          7m2s
```
{{% /tab %}}
{{< /tabs >}}

2. Verify the deployment is successful 
    - To confirm that the deployment of your Nginx service has been successfully completed, you can test the response from the Nginx server using the curl command:
    
    ```bash
    cd $HOME/k8s-101-workshop/terraform/
    nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
    curl -k https://$nodename/default
    ```
    
    - This command should return a response from the Nginx server, indicating that the service is active and capable of handling requests.
    - With the Nginx service deployed and verified, we are now prepared to initiate benchmark traffic towards the Nginx service. This step will demonstrate Kubernetes' ability to dynamically scale out additional Nginx pods to accommodate the incoming request load.

3. Stress the nginx deployment

- Paste below command to create a client deployment to send http request towards nginx deployment to stress it.  this client deployment will create two Pod to keep issue http request towards nginx server.

{{< tabs >}}
{{% tab title="stress" %}}    
 ```bash
 cat <<EOF | tee  infinite-calls_client.yaml
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
 kubectl create -f infinite-calls_client.yaml
 ```
{{% /tab %}}
{{% tab title="" %}}
- verify the deployment
```bash
kubectl get pod
```
{{% /tab %}}
{{% tab title="Expected Output" style="info" %}}
- expected outcome
```
NAME                                READY   STATUS    RESTARTS   AGE
infinite-calls-6865bf6c8b-8g4pg     1/1     Running   0          4s
infinite-calls-6865bf6c8b-md9k7     1/1     Running   0          4s
nginx-deployment-55c7f467f8-mn2kc   1/1     Running   0          3m21s
nginx-deployment-55c7f467f8-skbtv   1/1     Running   0          3m21s
```
{{% /tab %}}
{{< /tabs >}}

The client pod continuously sends HTTP requests (using wget) towards the ClusterIP service of the nginx deployment.


4. Monitor Application Scaling up on master node

- After initiating the stress test with **client deployment**, you can monitor the deployment as Kubernetes automatically scales out by adding new Pods to handle the increased load. Use the watch command alongside kubectl get pods to observe the scaling process in real time:
{{< tabs >}}
{{% tab title="monitor" %}}
   
 ```bash
 watch kubectl get pods -l app=nginx 
 ```
{{% /tab %}}
{{% tab title="Expected Output" style="info" %}}


 - expect to see pod increasing as a response to the increased load.
 ```
 NAME                                READY   STATUS    RESTARTS   AGE
 nginx-deployment-55c7f467f8-d7bx9   1/1     Running   0          20s
 nginx-deployment-55c7f467f8-dx7ql   1/1     Running   0          20s
 nginx-deployment-55c7f467f8-b5h7z   1/1     Running   0          5m39s
 nginx-deployment-55c7f467f8-g4754   1/1     Running   0          20s
 nginx-deployment-55c7f467f8-hdbcc   1/1     Running   0          20s
 nginx-deployment-55c7f467f8-kbkw6   1/1     Running   0          35s
 nginx-deployment-55c7f467f8-bmzvg   1/1     Running   0          5m39s
 nginx-deployment-55c7f467f8-r6ndt   1/1     Running   0          35s
 nginx-deployment-55c7f467f8-xr2l7   1/1     Running   0          5s
 ```
{{% /tab %}}
{{< /tabs >}}
 - As **client deployment** continues to send traffic to the Nginx service, you will see the number of Pods gradually increase until reach configured limit - 10 Pods, demonstrating Kubernetes' Horizontal Pod Autoscaler (HPA) in action. This auto-scaling feature ensures that your application can adapt to varying levels of traffic by automatically adjusting the number of Pods based on predefined metrics such as CPU usage or request rate.

5. Delete client deployment to stop sending client traffic

    ```bash
    kubectl delete deployment infinite-calls
    ```
    
6. Monitor Application Scaling down on master node
    - Once the traffic generated by client deployment starts to decrease and eventually ceases, watch as Kubernetes smartly scales down the application by terminating the extra Pods that were previously spawned. This behavior illustrates the system's efficient management of resources, scaling down to match the reduced demand. you need wait 5 minutes (default but configurable ) to see nginx start to decrease.
        
{{< tabs >}}
{{% tab title="watch" %}}
 ```bash
 watch kubectl get pods
 ```
 {{% /tab %}}
{{% tab title="Expected Output" style="info" %}}
- expected outcome 
 
 ```
 NAME                                READY   STATUS    RESTARTS   AGE
 nginx-deployment-55c7f467f8-dxmqt   1/1     Running   0          10m
 nginx-deployment-55c7f467f8-hdbcc   1/1     Running   0          5m40s
 nginx-deployment-55c7f467f8-kkr8r   1/1     Running   0          10m
 ```
{{% /tab %}}
{{< /tabs >}}

 - By executing this stress test and monitoring the application scaling, you gain insight into the powerful capabilities of Kubernetes in managing application workloads dynamically, ensuring optimal resource utilization and responsive application performance.

7. Wrap up


- By now, you should have observed how Kubernetes can dynamically scale your services without any manual intervention, showcasing the platform's powerful capabilities for managing application demand and resources.
{{< tabs >}}
{{% tab title="delete resources" %}}
- Let's proceed by cleaning up and deleting the resources we've created, preparing our environment for further exploration into the intricacies of how Kubernetes operates.
 
```bash
kubectl delete ingress nginx
kubectl delete svc nginx-deployment
kubectl delete deployment nginx-deployment
kubectl delete hpa nginx-hpa
 
```
{{% /tab %}}
{{% tab title="delete LB and ingress controller" %}}
- Also delete loadbalancer and ingress controller
    
```bash
kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
kubectl delete -f https://raw.githubusercontent.com/Kong/kubernetes-ingress-controller/v2.10.0/deploy/single/all-in-one-dbless.yaml
kubectl delete -f https://github.com/jetstack/cert-manager/releases/download/v1.3.1/cert-manager.yaml
kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```
{{% /tab %}}
{{< /tabs >}}
### Summary
This chapter provides a quick demonstration of deploying an application with Horizontal Pod Autoscaler (HPA). For a detailed understanding of how it works, please continue to the next section [Kubernetes in depth](../../03_participanttasks/03_02_k8sindepth.html)
 

### Review Questions 
1. Describe how to make client application - infinite-calls to generate more traffic ?
{{% expand title="Click for Answer..." %}}
    The Answer IS...
{{% /expand %}}
2. How many minutes need to wait before you can see nginx pod start increasing.
{{% expand title="Click for Answer..." %}}
    The Answer IS...
{{% /expand %}}
3. How to stop sending traffic to nginx deployment
{{% expand title="Click for Answer..." %}}
    The Answer IS...
{{% /expand %}}

