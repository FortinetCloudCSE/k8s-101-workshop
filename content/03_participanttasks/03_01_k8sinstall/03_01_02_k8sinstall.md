---
title: "Task 1 - Install kubernetes"
menuTitle: "Task 1:Installation"
weight: 1
---

## Objective: 

Pick a right kubernetes to install also show you how easy to use kubernetes to scale your application.

## Choose your kubernetes 
Although Cloud-Managed Kubernetes becoming the popular choice for enteprise to use in production network, But Self Managed Kubernetes  give users full control over their Kubernetes environments. Choosing the right method to install Self Managed Kubernetes can vary significantly based on the intended use case, from development and testing environments to production deployments. Here's a short description of different ways to install Kubernetes, tailored to specific needs:

### For Development and Testing

- Minikube:
Best For: Individual developers and small teams experimenting with Kubernetes applications or learning the Kubernetes ecosystem.

- Kind (Kubernetes in Docker):
Best For: Kubernetes contributors, developers working on CI/CD pipelines, and testing Kubernetes configurations.

- OrbStack Kubernetes:
Best for: development and testing on **MacOS desktop with Apple Silicon or intel chipset** , it eliminates the complexity of setting up and managing full-fledged Kubernetes clusters.


### For Production Deployment

- Kubeadm:
Best For: Organizations looking for a customizable production-grade Kubernetes setup that adheres to best practices. Suitable for those with specific infrastructure requirements and those who wish to integrate Kubernetes into existing systems with specific configurations.

- Kubespray:
Best For: Users seeking to deploy Kubernetes on a variety of infrastructure types (cloud, on-premises, bare-metal) and require a tool that supports extensive customization and scalability.

- Rancher:
Best For: Organizations looking for an enterprise Kubernetes management platform that simplifies the operation of Kubernetes across any infrastructure, offering UI and API-based management.

## Use kubeadm to install kubernetes 

### use azure shell as client

before proceed, make sure you have already completed the deployment using terrafrom in azure shell. below all operation are performed on same **azure cloud shell** where you deployed your terraform script. 

assume you already deployed two VM with `terraform apply -var="username=$(whoami)" --auto-approve` 

### create some script 
```bash
echo 'ssh_worker_function() {
    cd $HOME/k8s-101-workshop/terraform/
    nodename=$(terraform output -json | jq -r .linuxvm_worker_FQDN.value)
    username=$(terraform output -json | jq -r .linuxvm_username.value)
    ssh -o "StrictHostKeyChecking=no" $username@$nodename
}
alias ssh_worker="ssh_worker_function"' >> $HOME/.bashrc

echo 'ssh_master_function() {
    cd $HOME/k8s-101-workshop/terraform/
    nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
    username=$(terraform output -json | jq -r .linuxvm_username.value)
    export fqdn=${nodename}
    ssh -o "StrictHostKeyChecking=no"  -t $username@$nodename "export fqdn=${fqdn}; exec bash"
}
alias ssh_worker="ssh_worker_function"' >> $HOME/.bashrc

alias k='kubectl' >> $HOME/.bashrc
source $HOME/.bashrc
```
### generate ssh-key for master and worker node


- clean existing kubeconfig
```bash
rm -f ~/.kube/config
```

- clean knowhost 
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
if key exist, choose either Overwrite or not. 
```bash
[ ! -f ~/.ssh/id_rsa ] && ssh-keygen -q -N "" -f ~/.ssh/id_rsa
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
sed -i "s/localhost/$nodename/g" $HOME/k8s-101-workshop/scripts/install_kubeadm_masternode.sh
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
#### prepare access kubernetes on **azure shell**

copy kubectl configuration to **azure shell** to use kubenetnes. as **azure shell** is outside for azure VM VPC, so it's required to use kubernetes master node **public ip** to access it. 


```bash
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
rm -rf $HOME/.kube/
mkdir -p ~/.kube/
scp -o 'StrictHostKeyChecking=no' $username@$nodename:~/.kube/config $HOME/.kube
sed -i "s|server: https://[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:6443|server: https://$nodename:6443|" $HOME/.kube/config

```
#### Verify the installation 
from your az shell, watch the node getting "Ready". it will take a while to get worker node become "Ready".

```bash
watch kubectl get node 
```
expected outcome
```
NAME          STATUS   ROLES           AGE   VERSION
node-worker   Ready    <none>          14m   v1.26.1
nodemaster    Ready    control-plane   18m   v1.26.1
```

### Deploy Demo Application and enable auto scalling (HPA)

The Deployed demo application include two POD but will auto scale if coming traffic reach some limit. 

```bash
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
sed -i "s/localhost/$nodename/g" $HOME/k8s-101-workshop/scripts/deploy_application_with_hpa_masternode.sh
ssh -o 'StrictHostKeyChecking=no' $username@$nodename < $HOME/k8s-101-workshop/scripts/deploy_application_with_hpa_masternode.sh

```
use `kubectl get pod` to check deployment.

```bash
kubectl get pod
```
expected outcome

```bash
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-55c7f467f8-q26f2   1/1     Running   0          9m53s
nginx-deployment-55c7f467f8-rfdck   1/1     Running   0          7m2s
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

### Stress the nginx deployment

paste below command into azure shell to create a client deployment to send http request towards nginx deployment to stress it.  this client deployment will create two POD to keep issue http request towards nginx server.

```bash
cat <<EOF | kubectl apply -f - 
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
```


### Monitor Application Scaling up on master node

After initiating the stress test with **client deployment**, you can monitor the deployment as Kubernetes automatically scales out by adding new Pods to handle the increased load. Use the watch command alongside kubectl get pods to observe the scaling process in real time:

```bash
watch kubectl get pods -l app=nginx 
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
As **client deployment** continues to send traffic to the Nginx service, you will see the number of Pods gradually increase, demonstrating Kubernetes' Horizontal Pod Autoscaler (HPA) in action. This auto-scaling feature ensures that your application can adapt to varying levels of traffic by automatically adjusting the number of Pods based on predefined metrics such as CPU usage or request rate.

### delete client deployment to stop sending client traffic

```bash
kubectl delete deployment infinite-calls
```

### Monitor Application Scaling down on master node
Once the traffic generated by client deployment starts to decrease and eventually ceases, watch as Kubernetes smartly scales down the application by terminating the extra Pods that were previously spawned. This behavior illustrates the system's efficient management of resources, scaling down to match the reduced demand.


```bash
watch kubectl get pods
```
expected outcome 

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
{{< notice warning >}} 
  
If you wish to start over and completely remove Kubernetes from all master and worker nodes, execute the following command on each node.This step is ideal if you're seeking a clean slate for experimenting further or if any part of the setup did not go as planned:
 {{< /notice >}} 
 

ssh into master worker and worker node.  
```bash
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
ssh -o 'StrictHostKeyChecking=no' $username@$nodename 
```  
or 
```bash
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_worker_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
ssh -o 'StrictHostKeyChecking=no' $username@$nodename 
``` 

then on master or worker node , run 
```bash
sudo kubeadm reset -f 
```

Note: This action will reset your Kubernetes cluster, removing all configurations, deployments, and associated data. It's a critical step, so proceed with caution.

if you are satisfied with your current Kubernetes setup and ready to move on to the next task, you can skip this step. This flexibility allows you to either delve deeper into Kubernetes functionalities or reset your environment for additional testing and learning opportunities.
### Starting Over

{{< notice warning >}}  

if you want delete VM completely, use `terraform destroy -var="username=$(whoami)" --auto-approve` , then use `terraform apply -var="username=$(whoami)" --auto-approve` to recreate.  do that on terraform directory. this will give you a fresh environement to begin with again.

 {{< /notice >}} 


Summary

This chapter aims to demonstrate the ease of dynamically scaling your applications using Kubernetes.  

