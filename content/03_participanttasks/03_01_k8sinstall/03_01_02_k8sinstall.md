---
title: "Task 1 - Install kubernetes"
menuTitle: "Task 1 - K8S Installation"
weight: 1
---


## Use kubeadm to install kubernetes 

### use azure shell as kubenetes client

To use Azure Cloud Shell as a Kubernetes client, ensure you have completed your [Terraform deployment in Azure Cloud Shell](../../02_quickstart_overview_faq/02_01_quickstart/02_01_03_terraform.html). Azure Cloud Shell comes with kubectl pre-installed, facilitating Kubernetes operations. 

1. Navigate to your project directory where your Kubernetes workshop materials are located:
    ```bash
    cd $HOME/k8s-101-workshop
    ```

2. Create a script for later use

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

3. Generate ssh-key for master and worker node

   - delete existing kubeconfig
   ```bash
   rm -f ~/.kube/config
   ```

   - delete ssh knowhost
   ```bash
   rm -f /home/$(whoami)/.ssh/known_hosts
   
   ```

   - get the password for VM **which will be needed when use ssh-copy-id to copy ssh key** into the master node.

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

4. Install kubernetes master node: 

<<<<<<< HEAD

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
=======
   - ssh into master node to run kubernetes master installation script 

   ```bash
   cd $HOME/k8s-101-workshop/terraform/
   nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
   username=$(terraform output -json | jq -r .linuxvm_username.value)
   sed -i "s/localhost/$nodename/g" $HOME/k8s-101-workshop/scripts/install_kubeadm_masternode.sh
   ssh -o 'StrictHostKeyChecking=no' $username@$nodename sudo kubeadm reset -f
   ssh -o 'StrictHostKeyChecking=no' $username@$nodename < $HOME/k8s-101-workshop/scripts/install_kubeadm_masternode.sh
   ```
>>>>>>> f098090 (add numbering and indentation to K8s install tasks)

5. Install kubernetes worker node :

   - ssh into worker node to run kubernetes worker installation script 

   ```bash
   cd $HOME/k8s-101-workshop/terraform/
   nodename=$(terraform output -json | jq -r .linuxvm_worker_FQDN.value)
   username=$(terraform output -json | jq -r .linuxvm_username.value)
   ssh -o 'StrictHostKeyChecking=no' $username@$nodename sudo kubeadm reset -f
   ssh -o 'StrictHostKeyChecking=no' $username@$nodename < $HOME/k8s-101-workshop/scripts/install_kubeadm_workernode.sh
   ```

6. Join worker node to cluster

   ```bash
   cd $HOME/k8s-101-workshop/terraform/
   nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
   username=$(terraform output -json | jq -r .linuxvm_username.value)
   scp -o 'StrictHostKeyChecking=no' $username@$nodename:workloadtojoin.sh .
   nodename=$(terraform output -json | jq -r .linuxvm_worker_FQDN.value)
   username=$(terraform output -json | jq -r .linuxvm_username.value)
   ssh -o 'StrictHostKeyChecking=no' $username@$nodename < ./workloadtojoin.sh
   ```


7. Prepare access kubernetes from **azure shell**

<<<<<<< HEAD
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
=======
   - To use Kubernetes from Azure Shell, copy your kubectl configuration. Because Azure Shell is external to your Azure VM VPC, you must use the Kubernetes master node's public IP for access. Follow these steps:
>>>>>>> f098090 (add numbering and indentation to K8s install tasks)


   ```bash
   cd $HOME/k8s-101-workshop/terraform/
   nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
   username=$(terraform output -json | jq -r .linuxvm_username.value)
   rm -rf $HOME/.kube/
   mkdir -p ~/.kube/
   scp -o 'StrictHostKeyChecking=no' $username@$nodename:~/.kube/config $HOME/.kube
   sed -i "s|server: https://[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:6443|server: https://$nodename:6443|" $HOME/.kube/config
   ```

<<<<<<< HEAD
To use Kubernetes from Azure Shell, copy your kubectl configuration. Because Azure Shell is external to your Azure VM VNET, you must use the Kubernetes master node's public IP for access. Follow these steps:
=======
8. Verify the installation 
   - **From your Azure shell**, watch the node getting "Ready". it will take a while to get worker node become "Ready".
>>>>>>> f098090 (add numbering and indentation to K8s install tasks)

   ```bash
   watch kubectl get node 
   ```
   expected outcome
   ```
   NAME          STATUS   ROLES           AGE   VERSION
   node-worker   Ready    <none>          14m   v1.26.1
   nodemaster    Ready    control-plane   18m   v1.26.1
   ```
   

### **OPTIONAL** Re-Install Kubernetes
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

