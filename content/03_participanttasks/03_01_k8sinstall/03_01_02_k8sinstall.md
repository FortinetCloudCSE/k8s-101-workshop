---
title: "Task 1 - Install kubernetes"
menuTitle: "Task 1:Installation"
weight: 1
---

## Objective: 

Use kubeadm to install a self-managed kubernetes cluster with 1 master node and 1 worker node on Azure ubuntu VM.


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

### use azure shell as kubenetes client

To use Azure Cloud Shell as a Kubernetes client, ensure you have completed your provision using Terraform in Azure Cloud Shell. Azure Cloud Shell comes with kubectl pre-installed, facilitating Kubernetes operations. 


Navigate to your project directory where your Kubernetes workshop materials are located:
```bash
cd $HOME/k8s-101-workshop
```

### create some script for later use

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
alias ssh_master="ssh_master_function"' >> $HOME/.bashrc

alias k='kubectl' >> $HOME/.bashrc
source $HOME/.bashrc
```
### generate ssh-key for master and worker node


- delete existing kubeconfig
```bash
rm -f ~/.kube/config
```

- delete ssh knowhost
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

*this step take around 4 minutes* 

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

*it took around 3 minutes* 

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
nodename=$(terraform output -json | jq -r .linuxvm_worker_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
ssh -o 'StrictHostKeyChecking=no' $username@$nodename < ./workloadtojoin.sh
```


#### prepare access kubernetes from **azure shell**

To use Kubernetes from Azure Shell, copy your kubectl configuration. Because Azure Shell is external to your Azure VM VNET, you must use the Kubernetes master node's public IP for access. Follow these steps:


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


### Re-Install Kubernetes
{{< notice warning >}} 
  
If you wish to start over and completely remove Kubernetes from all master and worker nodes, execute the following command on each node.This step is ideal if you're seeking a clean slate for experimenting further or if any part of the setup did not go as planned:
 {{< /notice >}} 
 

ssh into master worker and worker node with alias `ssh_master` and `ssh_worker`


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


### Summary

This chapter aims to install a kubernetes cluster with kube-adm based script

### Review Questions

- What is the kube-API FQDN name ?
- What is the version of this kubernetes server ?
- What is the container runtime name and version ?
- Describe general step to add a new VM as worker node in this cluster 

