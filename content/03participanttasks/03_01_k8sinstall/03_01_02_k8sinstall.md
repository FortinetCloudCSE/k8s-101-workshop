---
title: "Task 1 - Install kubernetes"
menuTitle: "Task 1:Installation"
weight: 1
---

## Use kubeadm to install kubernetes 

### use azure shell as client

- Before proceeding, be sure to complete the [terraform deployment in Azure shell](../../02_quickstart_overview_faq/02_01_quickstart/02_01_03_terraform.html). 
- All commands are performed on same **Azure cloud shell** where you deploy your terraform script. 


### generate ssh-key for master and worker node
```bash
rm -f /home/$(whoami)/.ssh/known_hosts

```

- get the password for VM 
the password will be needed when use ssh-copy-id to copy ssh key into the master node.

```bash
cd $HOME/k8s-101-workshop/terraform/
terraform output -json | jq -r .linuxvm_password.value
echo $vmpassword
```
- generate ssh-key 

```bash
ssh-keygen -q -N "" -f ~/.ssh/id_rsa 
```

- copy ssh-key to master node, enter password  when prompted.

```bash
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
ssh-copy-id -f  -o 'StrictHostKeyChecking=no' $username@$nodename
```


- copy ssh-key to worker node, enter password  when prompted.
```bash
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_worker_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
ssh-copy-id -f  -o 'StrictHostKeyChecking=no' $username@$nodename
```

#### install kubernetes master node: 

- ssh into master node to run kubernetes master installation script 

```bash
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
ssh -o 'StrictHostKeyChecking=no' $username@$nodename sudo kubeadm reset -f
ssh -o 'StrictHostKeyChecking=no' $username@$nodename < $HOME/k8s-101-workshop/scripts/install_kubeadm_masternode.sh
```

#### Install kubernetes worker node :


- ssh into worker node to run kubernetes worker installation script 

```bash
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_worker_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
ssh -o 'StrictHostKeyChecking=no' $username@$nodename sudo kubeadm reset -f
ssh -o 'StrictHostKeyChecking=no' $username@$nodename < $HOME/k8s-101-workshop/scripts/install_kubeadm_workernode.sh
```

#### Join worker node to cluster
```bash
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
scp -o 'StrictHostKeyChecking=no' $username@$nodename:workloadtojoin.sh .
#sed -i 's/^kubeadm join/sudo kubeadm join/g' workloadtojoin.sh
nodename=$(terraform output -json | jq -r .linuxvm_worker_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
ssh -o 'StrictHostKeyChecking=no' $username@$nodename < ./workloadtojoin.sh

```

### Deploy Demo Application And Enable Auto Scalling (HPA)

```bash
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
sed -i "s/localhost/$nodename/g" $HOME/k8s-101-workshop/scripts/deploy_application_with_hpa_masternode.sh
ssh -o 'StrictHostKeyChecking=no' $username@$nodename < $HOME/k8s-101-workshop/scripts/deploy_application_with_hpa_masternode.sh

```


### Verify the deployment is sucessful 

To confirm that the deployment of your Nginx service has been successfully completed, you can test the response from the Nginx server using the curl command:

```bash
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
curl -k https://$nodename/default
```
This command should return a response from the Nginx server, indicating that the service is active and capable of handling requests.


With the Nginx service deployed and verified, we are now prepared to initiate benchmark traffic towards the Nginx service. This step will demonstrate Kubernetes' ability to dynamically scale out additional Nginx pods to accommodate the incoming request load.



### SSH into master node  
```bash
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
ssh -o 'StrictHostKeyChecking=no' $username@$nodename 
``` 

### Check application deployment status
```bash
kubectl get pod
```
expected outcome 
``` 
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-55c7f467f8-b5h7z   1/1     Running   0          8m31s
nginx-deployment-55c7f467f8-bmzvg   1/1     Running   0          8m31s 
```
From above, we know that two nginx POD is Running. 

### Stress Test the Nginx Server with Hey on master node

To evaluate the scalability and responsiveness of the Nginx web server under heavy load, we'll utilize the hey tool. This utility is designed to generate a high volume of requests to stress test the server, allowing us to observe how Kubernetes dynamically scales the application to meet demand.

```bash

hey -n 10000 -c 1000 https://$(hostname)/default
```
This command instructs hey to send a total of 10,000 requests (-n 10000) with a concurrency level of 1,000 (-c 1000) to the Nginx server.


### Monitor Application Scaling on master node

After initiating the stress test with **hey**, you can monitor the deployment as Kubernetes automatically scales out by adding new Pods to handle the increased load. Use the watch command alongside kubectl get pods to observe the scaling process in real time:

```bash
watch kubectl get pods
```
expect to see pod increasing as a response to the increased load.
```bash
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
As **hey** continues to send traffic to the Nginx service, you will see the number of Pods gradually increase, demonstrating Kubernetes' Horizontal Pod Autoscaler (HPA) in action. This auto-scaling feature ensures that your application can adapt to varying levels of traffic by automatically adjusting the number of Pods based on predefined metrics such as CPU usage or request rate.

Once the traffic generated by hey starts to decrease and eventually ceases, watch as Kubernetes smartly scales down the application by terminating the extra Pods that were previously spawned. This behavior illustrates the system's efficient management of resources, scaling down to match the reduced demand.



```
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-55c7f467f8-dxmqt   1/1     Running   0          10m
nginx-deployment-55c7f467f8-hdbcc   1/1     Running   0          5m40s
nginx-deployment-55c7f467f8-kkr8r   1/1     Running   0          10m
```
By executing this stress test and monitoring the application scaling, you gain insight into the powerful capabilities of Kubernetes in managing application workloads dynamically, ensuring optimal resource utilization and responsive application performance.

### Wrap up

By now, you should have observed how Kubernetes can dynamically scale your services without any manual intervention, showcasing the platform's powerful capabilities for managing application demand and resources.

Let's proceed by cleaning up and deleting the resources we've created, preparing our environment for further exploration into the intricacies of how Kubernetes operates.

```bash
kubectl delete ingress nginx
kubectl delete svc nginx-deployment
kubectl delete deployment nginx-deployment

```

### Starting Over
If you wish to start over and completely remove Kubernetes from all master and worker nodes, execute the following command on each node. This step is ideal if you're seeking a clean slate for experimenting further or if any part of the setup did not go as planned:

```bash
sudo kubeadm reset -f 
```

Note: This action will reset your Kubernetes cluster, removing all configurations, deployments, and associated data. It's a critical step, so proceed with caution.

On the other hand, if you are satisfied with your current Kubernetes setup and ready to move on to the next task, you can skip this step. This flexibility allows you to either delve deeper into Kubernetes functionalities or reset your environment for additional testing and learning opportunities.


Summary

This chapter aims to demonstrate the ease of dynamically scaling your applications using Kubernetes.  


