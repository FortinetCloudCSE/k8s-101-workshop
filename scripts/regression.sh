#!/bin/bash -x
cd $HOME/k8s-101-workshop/terraform
terraform destroy -var="username=$(whoami)" --auto-approve

cd $HOME/k8s-101-workshop/terraform
terraform apply -var="username=$(whoami)" --auto-approve

rm -f /home/$(whoami)/.ssh/known_hosts

cd $HOME/k8s-101-workshop/terraform/
terraform output -json | jq -r .linuxvm_password.value
echo $vmpassword

ssh-keygen -q -N "" -f ~/.ssh/id_rsa -y

#copy key to master 
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
ssh-copy-id -f  -o 'StrictHostKeyChecking=no' $username@$nodename
#copy key to worker 
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_worker_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
ssh-copy-id -f  -o 'StrictHostKeyChecking=no' $username@$nodename


#start install k8s master
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
#ssh -o 'StrictHostKeyChecking=no' $username@$nodename sudo kubeadm reset -f
ssh -o 'StrictHostKeyChecking=no' $username@$nodename < $HOME/k8s-101-workshop/scripts/install_kubeadm_masternode.sh
#start install k8s worker 
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_worker_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
ssh -o 'StrictHostKeyChecking=no' $username@$nodename sudo kubeadm reset -f
ssh -o 'StrictHostKeyChecking=no' $username@$nodename < $HOME/k8s-101-workshop/scripts/install_kubeadm_workernode.sh

#join worker node to cluster 

cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
scp -o 'StrictHostKeyChecking=no' $username@$nodename:workloadtojoin.sh .
#sed -i 's/^kubeadm join/sudo kubeadm join/g' workloadtojoin.sh
nodename=$(terraform output -json | jq -r .linuxvm_worker_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
ssh -o 'StrictHostKeyChecking=no' $username@$nodename < ./workloadtojoin.sh

#deploy demo 
sleep 30
echo wait 30 seconds for worker node ready

cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
ssh -o 'StrictHostKeyChecking=no' $username@$nodename < $HOME/k8s-101-workshop/scripts/deploy_application_with_hpa_masternode.sh
ssh -o 'StrictHostKeyChecking=no' $username@$nodename
#curl -k https://$(hostname)/default

#ssh -o 'StrictHostKeyChecking=no' $username@$nodename 'command -v kubeadm && sudo kubeadm reset -f'
