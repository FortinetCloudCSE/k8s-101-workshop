---
title: "Task 1 - Install Kubernetes"
linkTitle: "Task 1 - K8s Installation"
weight: 1
---


## Use kubeadm to install kubernetes

![labafter](../../images/K8s%20workshopafter-101.png)

This task builds a simple Kubernetes cluster with one control-plane node and one worker node.

The scripts in this workshop now use the current Kubernetes package repository at `pkgs.k8s.io`, `containerd` as the container runtime, `kubeadm` for cluster bootstrap, and Calico as the CNI.

Default versions used by the scripts:

```bash
K8S_MINOR=v1.36
CALICO_VERSION=v3.32.1
POD_CIDR=10.244.0.0/16
SERVICE_CIDR=10.96.0.0/12
```

If you need to pin a different supported Kubernetes minor version, export it before running the scripts, for example:

```bash
export K8S_MINOR=v1.35
```

### Use Azure Cloud Shell as kubernetes client

To use Azure Cloud Shell as a Kubernetes client, ensure you have completed your [Terraform deployment in Azure Cloud Shell](../../02_quickstart_overview_faq/02_01_quickstart/02_01_03_terraform.html). Azure Cloud Shell comes with kubectl pre-installed, facilitating Kubernetes operations.

1. Navigate to your project directory where your Kubernetes workshop materials are located:

```bash
cd $HOME/k8s-101-workshop
```

2. Create helper aliases for SSH access to the master and worker nodes.

```bash
cat <<'EOF_ALIAS' >> $HOME/.bashrc
ssh_worker_function() {
    cd $HOME/k8s-101-workshop/terraform/
    nodename=$(terraform output -json | jq -r .linuxvm_worker_FQDN.value)
    username=$(terraform output -json | jq -r .linuxvm_username.value)
    ssh -o "StrictHostKeyChecking=no" $username@$nodename
}
alias ssh_worker="ssh_worker_function"

ssh_master_function() {
    cd $HOME/k8s-101-workshop/terraform/
    nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
    username=$(terraform output -json | jq -r .linuxvm_username.value)
    export fqdn=${nodename}
    ssh -o "StrictHostKeyChecking=no" -t $username@$nodename "export fqdn=${fqdn}; exec bash"
}
alias ssh_master="ssh_master_function"

alias k='kubectl'
EOF_ALIAS
source $HOME/.bashrc
```

3. Generate SSH key and copy it to both nodes.

{{< tabs "ssh keys">}}
{{% tab title="delete kubeconfig" %}}

```bash
rm -f ~/.kube/config
```
{{% /tab %}}
{{% tab title="delete knownhost" %}}

```bash
rm -f /home/$(whoami)/.ssh/known_hosts
```
{{% /tab %}}
{{% tab title="get password" %}}

```bash
cd $HOME/k8s-101-workshop/terraform/
vmpassword=$(terraform output -json | jq -r .linuxvm_password.value)
echo $vmpassword
```
{{% /tab %}}
{{% tab title="gen ssh key" %}}

```bash
[ ! -f ~/.ssh/id_rsa ] && ssh-keygen -q -N "" -f ~/.ssh/id_rsa
```
{{% /tab %}}
{{% tab title="copy to master" %}}

```bash
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
ssh-copy-id -f -o 'StrictHostKeyChecking=no' $username@$nodename
```
{{% /tab %}}
{{% tab title="copy to worker" %}}

```bash
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_worker_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
ssh-copy-id -f -o 'StrictHostKeyChecking=no' $username@$nodename
```
{{% /tab %}}
{{< /tabs >}}

4. Install Kubernetes on the master node.

```bash
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)

ssh -o 'StrictHostKeyChecking=no' $username@$nodename sudo kubeadm reset -f || true
scp -o 'StrictHostKeyChecking=no' $HOME/k8s-101-workshop/scripts/install_kubeadm_masternode.sh $username@$nodename:~/install_kubeadm_masternode.sh
ssh -o 'StrictHostKeyChecking=no' -t $username@$nodename "export fqdn=${nodename}; bash ~/install_kubeadm_masternode.sh"
```

5. Install Kubernetes packages and container runtime on the worker node.

```bash
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_worker_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)

ssh -o 'StrictHostKeyChecking=no' $username@$nodename sudo kubeadm reset -f || true
scp -o 'StrictHostKeyChecking=no' $HOME/k8s-101-workshop/scripts/install_kubeadm_workernode.sh $username@$nodename:~/install_kubeadm_workernode.sh
ssh -o 'StrictHostKeyChecking=no' -t $username@$nodename "bash ~/install_kubeadm_workernode.sh"
```

6. Join worker node to cluster.

```bash
cd $HOME/k8s-101-workshop/terraform/
master=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
worker=$(terraform output -json | jq -r .linuxvm_worker_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)

scp -o 'StrictHostKeyChecking=no' $username@$master:~/workloadtojoin.sh ./workloadtojoin.sh
scp -o 'StrictHostKeyChecking=no' ./workloadtojoin.sh $username@$worker:~/workloadtojoin.sh
ssh -o 'StrictHostKeyChecking=no' -t $username@$worker "bash ~/workloadtojoin.sh"
```

7. Prepare access Kubernetes from **Azure Cloud Shell**.

```bash
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)

rm -rf $HOME/.kube/
mkdir -p ~/.kube/
scp -o 'StrictHostKeyChecking=no' $username@$nodename:~/.kube/config $HOME/.kube/config
sed -i "s|server: https://[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:6443|server: https://$nodename:6443|" $HOME/.kube/config
```

8. Verify the installation.

{{< tabs >}}
{{% tab title="Verify" %}}

```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl cluster-info
```

You can also watch the worker become Ready:

```bash
watch kubectl get nodes
```
{{% /tab %}}
{{% tab title="Expected Output" style="info" %}}

```bash
NAME          STATUS   ROLES           AGE   VERSION
node-worker   Ready    <none>          10m   v1.36.x
nodemaster    Ready    control-plane   15m   v1.36.x
```

Container runtime should show `containerd`, for example:

```bash
kubectl get nodes -o wide
# CONTAINER-RUNTIME: containerd://...
```
{{% /tab %}}
{{< /tabs >}}

### Summary

This chapter installs Kubernetes using kubeadm. The workshop creates one control-plane node and one worker node. The current script uses containerd instead of CRI-O and installs Kubernetes through `pkgs.k8s.io`.

Continue to [deploy and scaling application](../../03_participanttasks/03_01_k8sinstall/03_01_03_hpa_demo.html).

### Review Questions

1. What is the kube-API FQDN name in kubeconfig?
{{% expand title="Click for Answer..." %}}

```bash
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'
```

Example:

```bash
https://k8sxx-master.eastus.cloudapp.azure.com:6443
```
{{% /expand %}}

2. What is the version of this Kubernetes server?
{{% expand title="Click for Answer..." %}}

```bash
kubectl version
kubectl get nodes
```

Expected server version is the latest package available in the configured `K8S_MINOR` repository, for example `v1.36.x`.
{{% /expand %}}

3. What is the container runtime name and version?
{{% expand title="Click for Answer..." %}}

```bash
kubectl get nodes -o wide
```

Expected runtime is `containerd://...`.
{{% /expand %}}

4. Describe the general steps to add a new VM as worker node in this cluster.
{{% expand title="Click for Answer..." %}}

```text
Create a new VM.
Run scripts/install_kubeadm_workernode.sh on the new VM.
Get a fresh join command from the master node using kubeadm token create --print-join-command.
Run the join command on the new worker node.
Verify with kubectl get nodes.
```
{{% /expand %}}

### **IN CASE YOU RUNNING INTO PROBLEM**

You can reinstall Kubernetes or delete and recreate the VMs.

#### Re-Install Kubernetes

{{< notice warning >}}
If you want a clean reset, run the following commands on both master and worker nodes. This removes Kubernetes state from the node.
{{< /notice >}}

```bash
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d/* ~/.kube /etc/kubernetes /var/lib/etcd
sudo systemctl restart containerd kubelet
```

Then rerun this task from the master installation step.

#### Starting Over

{{< notice warning >}}
If you want to delete the VMs completely and try again, use Terraform.
{{< /notice >}}

Delete VMs:

```bash
cd $HOME/k8s-101-workshop/terraform/ && terraform destroy -var="username=$(whoami)" --auto-approve
```

Create VMs again:

```bash
cd $HOME/k8s-101-workshop/terraform/ && terraform apply -var="username=$(whoami)" --auto-approve
```
