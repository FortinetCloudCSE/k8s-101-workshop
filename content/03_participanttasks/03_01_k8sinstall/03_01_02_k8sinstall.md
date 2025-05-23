---
title: "Task 1 - Install Kubernetes"
linkTitle: "Task 1 - K8s Installation"
weight: 1
---


## Use kubeadm to install kubernetes 

![labafter](../../images/K8s%20workshopafter-101.png)

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
   alias ssh_master="ssh_master_function"' >> $HOME/.bashrc
   
   alias k='kubectl' >> $HOME/.bashrc
   source $HOME/.bashrc
   ```

3. Generate ssh-key for master and worker node

{{< tabs "ssh keys">}}
{{% tab title="delete kubeconfig" %}}
   
   - delete existing kubeconfig
   ```bash
   rm -f ~/.kube/config
   ```
{{% /tab %}}
{{% tab title="delete knownhost" %}}
   - delete ssh knowhost
   ```bash
   rm -f /home/$(whoami)/.ssh/known_hosts
   
   ```
{{% /tab %}}
{{% tab title="get password" %}}
   - get the password for VM **which will be needed when use ssh-copy-id to copy ssh key** into the master node. Make sure to copy the password to a notepad. You will need this to login to Master node in next steps. 

   ```bash
   cd $HOME/k8s-101-workshop/terraform/
   vmpassword=$(terraform output -json | jq -r .linuxvm_password.value)
   echo $vmpassword
   ```
{{% /tab %}}
{{% tab title="gen ssh key" %}}
   - generate ssh-key 

   ```bash
   [ ! -f ~/.ssh/id_rsa ] && ssh-keygen -q -N "" -f ~/.ssh/id_rsa
   ```
{{% /tab %}}
{{% tab title="copy to master" %}}
   - copy ssh-key to master node, enter password  when prompted.

   ```bash
   cd $HOME/k8s-101-workshop/terraform/
   nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
   username=$(terraform output -json | jq -r .linuxvm_username.value)
   ssh-copy-id -f  -o 'StrictHostKeyChecking=no' $username@$nodename
   ```

{{% /tab %}}
{{% tab title="copy to worker" %}}
   - copy ssh-key to worker node, enter password  when prompted.
   
   ```bash
   cd $HOME/k8s-101-workshop/terraform/
   nodename=$(terraform output -json | jq -r .linuxvm_worker_FQDN.value)
   username=$(terraform output -json | jq -r .linuxvm_username.value)
   ssh-copy-id -f  -o 'StrictHostKeyChecking=no' $username@$nodename
   ```
{{% /tab %}}
{{< /tabs >}}

4. Install kubernetes master node: 

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
5. Install kubernetes worker node :

   - ssh into worker node to run kubernetes worker installation script 
   *this step take around 3 minutes*
   
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

   - To use Kubernetes from Azure Shell, copy your kubectl configuration. Because Azure Shell is external to your Azure VM VPC, you must use the Kubernetes master node's public IP for access. Follow these steps:
   ```bash
   cd $HOME/k8s-101-workshop/terraform/
   nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
   username=$(terraform output -json | jq -r .linuxvm_username.value)
   rm -rf $HOME/.kube/
   mkdir -p ~/.kube/
   scp -o 'StrictHostKeyChecking=no' $username@$nodename:~/.kube/config $HOME/.kube
   sed -i "s|server: https://[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:6443|server: https://$nodename:6443|" $HOME/.kube/config
   ```



8. Verify the installation 
{{< tabs >}}
{{% tab title="Verify" %}}
   - **From your Azure shell**, watch the node getting "Ready". it will take a while to get worker node become "Ready".

   ```bash
   watch kubectl get node 
   ```
   
{{% /tab %}}
{{% tab title="Expected Output" style="info" %}}
   expected outcome
   ```
   NAME          STATUS   ROLES           AGE   VERSION
   node-worker   Ready    <none>          14m   v1.27.1
   nodemaster    Ready    control-plane   18m   v1.27.1
   ```
 
{{% /tab %}}
{{< /tabs >}}  


### Summary

This chapter focuses on installing a Kubernetes cluster using a kubeadm based installation script. we created a Kubernetes cluster with one master node and one worker node. We can continue to [deploy and scalling application](../../03_participanttasks/03_01_k8sinstall/03_01_03_hpa_demo.html).



We do not delve into the details of the script used for installing the Kubernetes master and worker nodes. If you wish to understand more about what the installation script entails, please refer to  [step by step installation guide](../../03_participanttasks/03_01_k8sinstall/03_01_04_k8smanualinstall.html). 
 

### Review Questions
1. What is the kube-API FQDN name in kubeconfig ?
{{% expand title="Click for Answer..." %}}
    https://k8sxx-master.eastus.cloudapp.azure.com:6443
{{% /expand %}}
2. What is the version of this Kubernetes server ?
{{% expand title="Click for Answer..." %}}
```bash
Client Version: v1.28.1
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
Server Version: v1.27.16
```
{{% /expand %}}
3. What is the container runtime name and version ?
{{% expand title="Click for Answer..." %}}
```bash
cri-o:/1.27.4, can found from "kubectl get node -o wide"
nodemaster    Ready    control-plane   6m58s   v1.27.1   10.0.0.4      <none>        Ubuntu 22.04.5 LTS   6.5.0-1025-azure   cri-o://1.27.4
```
{{% /expand %}}
4. Describe general step to add a new VM as worker node in this cluster 
{{% expand title="Click for Answer..." %}}
```bash
Create a new VM (e.g., using a Terraform script or cloud provider's interface).
Install required components: kubelet, container runtime (e.g., containerd), and CNI plugins.
Obtain the join command from the master node (includes the necessary token and CA cert hash).
Run the join command on the new VM to add it to the cluster as a worker node.
Verify the new node's status in the cluster using kubectl get nodes.
This process ensures the new VM is properly configured and securely joined to the existing Kubernetes cluster.
```
{{% /expand %}}


### **IN CASE YOU RUNNING INTO PROBLEM**
you can re-install kubernetes or remove VM node then create again to starting over.

#### Re-Install Kubernetes


{{< notice warning >}} 
  
If you wish to start over and completely remove Kubernetes from all master and worker nodes, execute the following command on each node.This step is ideal if you're seeking a clean slate for experimenting further or if any part of the setup did not go as planned:
 {{< /notice >}} 
 

ssh into master worker and worker node with alias `ssh_master` and `ssh_worker`

then on master or worker node , run `sudo kubeadm reset -f`.


Note: This action will reset your Kubernetes cluster, removing all configurations, deployments, and associated data. It's a critical step, so proceed with caution.

if you are satisfied with your current Kubernetes setup and ready to move on to the next task, you can skip this step. This flexibility allows you to either delve deeper into Kubernetes functionalities or reset your environment for additional testing and learning opportunities.
#### Starting Over

{{< notice warning >}}  

if you want delete VM completely and try again, use terraform script below.

 {{< /notice >}} 

 - delete VM

  `cd $HOME/k8s-101-workshop/terraform/ && terraform destroy -var="username=$(whoami)" --auto-approve` 

 - create VM again
 
  `cd $HOME/k8s-101-workshop/terraform/ && terraform apply -var="username=$(whoami)" --auto-approve` 


