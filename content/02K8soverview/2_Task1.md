---
title: "Task 1 - Install kubernetes"
menuTitle: "Installation"
weight: 1
---

## Objective: 

Pick a right kubernetes to install also show you how easy to use kubernetes to scale your application.



## Choose your kubernetes 

Although Cloud-Managed Kubernetes becoming the popular choice for enteprise to use in production network, But Self Managed Kubernetes  give users full control over their Kubernetes environments. Choosing the right method to install Self Managed Kubernetes can vary significantly based on the intended use case, from development and testing environments to production deployments. Here's a short description of different ways to install Kubernetes, tailored to specific needs:

### For Development and Testing
- Minikube:

Description: Minikube is the go-to solution for developers looking to run Kubernetes locally. It creates a single-node Kubernetes cluster on your local machine, allowing developers to test Kubernetes applications or experiment with Kubernetes features without the overhead of setting up a full cluster.
Best For: Individual developers and small teams experimenting with Kubernetes applications or learning the Kubernetes ecosystem.

- Kind (Kubernetes in Docker):

Description: Kind runs Kubernetes clusters in Docker containers. It's primarily designed for testing Kubernetes itself but is also an excellent tool for developers who want to test their applications, CI pipelines, or experiment with Kubernetes.
Best For: Kubernetes contributors, developers working on CI/CD pipelines, and testing Kubernetes configurations.

- OrbStack Kubernetes:

Description : OrbStack is a Lightweight single-node cluster: Is has Built-in container engine without need to install Docker desktop, also no need to push images to a separate registry. Images built within OrbStack are readily available to Kubernetes. It has Developer-friendly features like Automatic HTTPS for services, advanced logging, and integration with popular tools like kubectl and Helm. 

Best For : Perfect for development and testing on **MacOS desktop with Apple Silicon or intel chipset** , it eliminates the complexity of setting up and managing full-fledged Kubernetes clusters.


### For Lightweight or Edge Environments
- K3s:

Description: K3s is a lightweight, easy-to-install Kubernetes distribution, designed for edge computing, IoT, CI/CD environments, and any situation where a full Kubernetes cluster may be overkill.
Best For: Scenarios requiring a lightweight footprint, including edge computing, IoT devices, and small-scale cloud deployments.

- MicroK8s:

Description: MicroK8s provides a low-maintenance, easily installable Kubernetes for workstations and edge/IoT devices. It offers a simple, fast, and secure way to run Kubernetes, with a focus on quick installation and operation.
Best For: Developers, edge computing scenarios, and IoT applications requiring quick setup and minimal Kubernetes operation knowledge.



### For Production Deployment

- Kubeadm:

Description: Kubeadm is a tool built by the Kubernetes community to provide a standard way to bootstrap Kubernetes clusters. It handles both the initial cluster setup and ongoing cluster lifecycle tasks, such as upgrades. Kubeadm gives users a great deal of flexibility and control over their Kubernetes clusters.
Best For: Organizations looking for a customizable production-grade Kubernetes setup that adheres to best practices. Suitable for those with specific infrastructure requirements and those who wish to integrate Kubernetes into existing systems with specific configurations.

- Kubespray:

Description: Kubespray is an Ansible-based tool for deploying highly available Kubernetes clusters. It supports multiple cloud and bare-metal environments and provides users with the flexibility to customize their Kubernetes installations.
Best For: Users seeking to deploy Kubernetes on a variety of infrastructure types (cloud, on-premises, bare-metal) and require a tool that supports extensive customization and scalability.

- Rancher:

Description: Rancher is an open-source platform that provides a complete software stack for teams adopting containers. It simplifies Kubernetes cluster management and is capable of running Kubernetes on any infrastructure.
Best For: Organizations looking for an enterprise Kubernetes management platform that simplifies the operation of Kubernetes across any infrastructure, offering UI and API-based management.




### Summary

The choice of Kubernetes installation method depends on the specific needs of the development lifecycle, infrastructure, and operational preferences. Minikube and Kind are excellent for development and testing, K3s and MicroK8s are ideal for lightweight or edge environments, and tools like Kubeadm, Kubespray, and platforms like Rancher offer the flexibility and control needed for production deployments. Each tool provides unique advantages, whether you're a developer testing a new application, an IoT engineer working at the edge, or an IT professional deploying a scalable, production-ready Kubernetes environment.

## Use kubeadm to install kubernetes 



### nodes provided to user: 


In this lab, we provide multiple Ubuntu 22.04 Linux VMs can be configured either as master nodes or worker nodes. Each user is granted sudo privileges on both types of servers. To ensure smooth operation of Kubernetes, each server is equipped with at least 2 CPUs, 4GB of RAM, and network connectivity between them. All VMs are deployed on Azure cloud within the same VNET, facilitating seamless communication. 

Accessing the VMs:
To access the master or worker nodes, utilize the following SSH commands:

For the master node:
```bash
ssh ubuntu@k8strainingmaster001.westus.cloudapp.azure.com
```
For the worker node:
```bash
ssh ubuntu@k8strainingworker001.westus.cloudapp.azure.com
```

This chapter aims to demonstrate the ease of dynamically scaling your applications using Kubernetes. We offer two approaches to install Kubernetes on the master node using kubeadm: a simple method for quick setup and a step-by-step approach for those who prefer to understand each phase of the setup process.


### Simple Way to Install Master Node:

For a straightforward setup, log into each master node and execute the following script in your bash terminal. This method is designed for users who prefer a quick and easy installation without delving into the details of each step.


**ssh into all master noder** then paste below command to install it

This approach provides a hassle-free method to get your Kubernetes cluster up and running swiftly. For users interested in a deeper understanding of the installation process, the step-by-step approach is recommended, allowing you to familiarize yourself with the purpose and function of each installation step.

```
#!/bin/bash -xe

error_handler() {
    echo -e "\e[31mAn error occurred. Exiting...\e[0m" >&2
    tput bel
    tput bel
}

trap error_handler ERR

sudo apt-get update -y
sudo apt-get install socat conntrack -y
sudo apt-get install jq -y
sudo apt-get install apt-transport-https ca-certificates -y
sudo apt-get install hey -y

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

OS="xUbuntu_22.04"
VERSION="1.25"
echo "deb [signed-by=/usr/share/keyrings/libcontainers-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" | sudo tee  /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb [signed-by=/usr/share/keyrings/libcontainers-crio-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list


mkdir -p /usr/share/keyrings
sudo curl -L --retry 3 --retry-delay 5 https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/libcontainers-archive-keyring.gpg.tmp
sudo mv -f /usr/share/keyrings/libcontainers-archive-keyring.gpg.tmp /usr/share/keyrings/libcontainers-archive-keyring.gpg

sudo curl -L --retry 3 --retry-delay 5 https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg.tmp
sudo mv -f /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg.tmp /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg

sudo apt-get update
sudo apt-get install cri-o cri-o-runc -y

sudo systemctl daemon-reload
sudo systemctl enable crio
sudo systemctl start crio

DOWNLOAD_DIR="/usr/local/bin"
sudo mkdir -p "$DOWNLOAD_DIR"
CRICTL_VERSION="v1.25.0"
ARCH="amd64"
curl  --insecure --retry 3 --retry-connrefused -fL "https://github.com/kubernetes-sigs/cri-tools/releases/download/$CRICTL_VERSION/crictl-$CRICTL_VERSION-linux-$ARCH.tar.gz" | sudo tar -C $DOWNLOAD_DIR -xz

CNI_PLUGINS_VERSION="v1.1.1"
ARCH="amd64"
DEST="/opt/cni/bin"
sudo mkdir -p "$DEST"
curl  --insecure --retry 3 --retry-connrefused -fL "https://github.com/containernetworking/plugins/releases/download/$CNI_PLUGINS_VERSION/cni-plugins-linux-$ARCH-$CNI_PLUGINS_VERSION.tgz" | sudo tar -C "$DEST" -xz

#RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
RELEASE="v1.26.1"
ARCH="amd64"
DOWNLOAD_DIR="/usr/local/bin"
sudo mkdir -p "$DOWNLOAD_DIR"
cd $DOWNLOAD_DIR
sudo curl --insecure --retry 3 --retry-connrefused -fL --remote-name-all https://dl.k8s.io/release/$RELEASE/bin/linux/$ARCH/{kubeadm,kubelet}
sudo chmod +x {kubeadm,kubelet}

RELEASE_VERSION="v0.4.0"
curl --insecure --retry 3 --retry-connrefused -fL "https://raw.githubusercontent.com/kubernetes/release/$RELEASE_VERSION/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:$DOWNLOAD_DIR:g" | sudo tee /etc/systemd/system/kubelet.service

sudo mkdir -p /etc/systemd/system/kubelet.service.d

sudo curl --insecure --retry 3 --retry-connrefused -fL "https://raw.githubusercontent.com/kubernetes/release/$RELEASE_VERSION/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:$DOWNLOAD_DIR:g" | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

sudo curl --insecure --retry 3 --retry-connrefused -fLO https://dl.k8s.io/release/v1.26.0/bin/linux/amd64/kubectl

sudo chmod +x /usr/local/bin/kubectl
alias k='kubectl'

sudo systemctl enable --now kubelet

sudo kubeadm config images pull --cri-socket unix:///var/run/crio/crio.sock --kubernetes-version=v1.26.1 --v=5

local_ip=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
CLUSTERDNSIP="10.96.0.10"
cat <<EOF | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS=--node-ip=$local_ip,--cluster-dns=$CLUSTERDNSIP
EOF

IPADDR=$local_ip
NODENAME=`hostname | tr -d '-'`
POD_CIDR="10.244.0.0/16"
SERVICE_CIDR="10.96.0.0/12"
echo $IPADDR $NODENAME  | sudo tee -a  /etc/hosts

sudo kubeadm reset -f
sudo kubeadm init --cri-socket=unix:///var/run/crio/crio.sock --apiserver-advertise-address=$IPADDR  --apiserver-cert-extra-sans=$IPADDR,k8strainingmaster001.westus.cloudapp.azure.com  --service-cidr=$SERVICE_CIDR --pod-network-cidr=$POD_CIDR --node-name $NODENAME  --token-ttl=0 -v=5

mkdir -p /home/ubuntu/.kube
sudo cp -f /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config
sudo mkdir -p /root/.kube
sudo cp -f /home/ubuntu/.kube/config /root/.kube/config 
kubectl --kubeconfig /home/ubuntu/.kube/config config set-cluster kubernetes --server "https://$local_ip:6443"

kubeadm token create --print-join-command > /home/ubuntu/workloadtojoin.sh
kubeadm config print join-defaults  > /home/ubuntu/kubeadm-join.default.yaml
echo '#sudo kubeadm join --config kubeadm-join.default.yaml' | sudo tee -a  /home/ubuntu/workloadtojoin.sh
chmod +x /home/ubuntu/workloadtojoin.sh
cat /home/ubuntu/workloadtojoin.sh

cd $HOME
#sudo curl --insecure --retry 3 --retry-connrefused -fL https://github.com/projectcalico/calico/releases/latest/download/calicoctl-linux-amd64 -o /usr/local/bin/calicoctl
sudo curl --insecure --retry 3 --retry-connrefused -fL https://github.com/projectcalico/calico/releases/download/v3.25.0/calicoctl-linux-amd64 -o /usr/local/bin/calicoctl

sudo chmod +x /usr/local/bin/calicoctl
curl --insecure --retry 3 --retry-connrefused -fLO https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml
kubectl --kubeconfig /home/ubuntu/.kube/config create -f tigera-operator.yaml
kubectl get namespace tigera-operator
kubectl rollout status deployment tigera-operator -n tigera-operator
curl --insecure --retry 3 --retry-connrefused -fLO https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/custom-resources.yaml
sed -i -e "s?blockSize: 26?blockSize: 24?g" custom-resources.yaml
sed -i -e "s?VXLANCrossSubnet?VXLAN?g" custom-resources.yaml
sed -i -e "s?192.168.0.0/16?10.244.0.0/16?g" custom-resources.yaml
sed -i '/calicoNetwork:/a\    containerIPForwarding: Enabled ' custom-resources.yaml
sed -i '/calicoNetwork:/a\    bgp: Disabled ' custom-resources.yaml
kubectl --kubeconfig /home/ubuntu/.kube/config create namespace calico-system
sleep 1
kubectl  get namespace calico-system
kubectl --kubeconfig /home/ubuntu/.kube/config apply  -f custom-resources.yaml
sleep 5 

kubectl rollout status deployment calico-kube-controllers -n calico-system
kubectl rollout status ds calico-node -n calico-system

kubectl get tigerastatus

kubectl rollout restart deployment coredns -n kube-system
kubectl rollout status deployment coredns -n kube-system 

cat /home/ubuntu/workloadtojoin.sh
[ $? -eq 0 ] && echo "installation done,you may want ssh into worker node to join cluster with above command in sudo mode"  
trap - ERR
```

###  (Optional) Step by Step approach for install master node

this is only for experienced user who interested to explore the detail of use kubeadm to install master node.


SSH into master node.

```bash
ssh ubuntu@k8strainingmaster001.westus.cloudapp.azure.com
```

#### Install required tool  

```bash
sudo apt-get update -y
sudo apt-get install socat conntrack -y
sudo apt-get install jq -y
sudo apt-get install apt-transport-https ca-certificates -y
sudo apt-get install hey -y
```
#### Setting Kernel Parameters for k8s

* install kernel dep module for cri-o runtime

**overlay**: Docker and CRI-O can use it to efficiently manage container images and layers
**br_netfilter**: This module is required for network packet filtering, bridging, and IP masquerading, which are essential for Kubernetes networking. It allows the Linux kernel's netfilter to process bridged (Layer 2) traffic. 

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
```

* enable iptables support for bridge and enable ip_forwarding

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system
```

#### Install CRI-O 

1. **Configure the CRI-O repository**:

   First, add the CRI-O repository. Ensure you replace `<VERSION>` with the version of Kubernetes you intend to use, for example, `1.25`:

```bash
OS="xUbuntu_22.04"
VERSION="1.25"
echo "deb [signed-by=/usr/share/keyrings/libcontainers-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" | sudo tee  /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb [signed-by=/usr/share/keyrings/libcontainers-crio-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list

```

2. **Add the GPG key**

```
mkdir -p /usr/share/keyrings
sudo curl -L --retry 3 --retry-delay 5 https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/libcontainers-archive-keyring.gpg.tmp
sudo mv -f /usr/share/keyrings/libcontainers-archive-keyring.gpg.tmp /usr/share/keyrings/libcontainers-archive-keyring.gpg

sudo curl -L --retry 3 --retry-delay 5 https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg.tmp
sudo mv -f /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg.tmp /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg
```

3. **Install CRI-O**

CRI-O is an open-source container runtime specifically designed for Kubernetes. It implements the Kubernetes Container Runtime Interface (CRI), allowing Kubernetes to use any OCI (Open Container Initiative)-compliant runtime as the container runtime for running pods. all Docker image are OCI-compliant. 
CRI-O-Runc is a CLI tool for spawning and running containers according to the OCI specification. 

```
sudo apt-get update
sudo apt-get install cri-o cri-o-runc -y
```
4. **Start and enable CRI-O**

```
sudo systemctl daemon-reload
sudo systemctl enable crio
sudo systemctl start crio

```
After this step, you can optionaly use 
`journalctl -f -u crio` to check the running status of crio, you shall see error message related with CNI which is normal, because we have not installed any CNI yet

####  Install crictl
install crictl which is the client tool for interactive with crio. 
```bash
DOWNLOAD_DIR="/usr/local/bin"
sudo mkdir -p "$DOWNLOAD_DIR"
CRICTL_VERSION="v1.25.0"
ARCH="amd64"
curl  --insecure --retry 3 --retry-connrefused -fL "https://github.com/kubernetes-sigs/cri-tools/releases/download/$CRICTL_VERSION/crictl-$CRICTL_VERSION-linux-$ARCH.tar.gz" | sudo tar -C $DOWNLOAD_DIR -xz
```
After this step, you can optionaly use `sudo crictl info` to check the status of crio. it shall tell you the container runtime is ready, but the network status is not ready. 

#### Install CNI 

**download and install Container Network Interface (CNI) plugins**

CNI plugins are essential for configuring the network connectivity of containers in Kubernetes clusters. By installing these plugins, the Kubernetes cluster can manage network namespaces and connectivity for pods, enabling communication between pods across the cluster as well as with external networks.Check CNI release notes for more information https://github.com/containernetworking/cni/releases  
the default build-in CNI is bridge CNI, which only support single node cluster. which mean this bridge CNI does not support networking multiple node.
```
CNI_PLUGINS_VERSION="v1.1.1"
ARCH="amd64"
DEST="/opt/cni/bin"
sudo mkdir -p "$DEST"
curl  --insecure --retry 3 --retry-connrefused -fL "https://github.com/containernetworking/plugins/releases/download/$CNI_PLUGINS_VERSION/cni-plugins-linux-$ARCH-$CNI_PLUGINS_VERSION.tgz" | sudo tar -C "$DEST" -xz
```
After this step, you can optionaly use `sudo crictl info` and `journalctl -f -u crio` to check crio status . you shall see crictl show both runtime and network is ready and crio found a valid CNI configuration which is bridge

####  Install  kubeadm, kubelet and kubectl

kubeadm is the binary that responsible for k8s installation, kubelet is the agent(binary) on each worker node to take the instruction from kube-apiserver and then talk to CRI-O with CRI standard to manage life-cycle of container. kubectl is the client that talk to k8s API server for daily k8s operation. 
Below script downloading specific versions of kubeadm, kubelet, and kubectl, placing them in the system path, configuring kubelet to run as a systemd service, and ensuring it starts automatically.

**Download 1.26.1 version kubeadm and kubelet** 

```
#RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
RELEASE="v1.26.1"
ARCH="amd64"
DOWNLOAD_DIR="/usr/local/bin"
sudo mkdir -p "$DOWNLOAD_DIR"
cd $DOWNLOAD_DIR
sudo curl --insecure --retry 3 --retry-connrefused -fL --remote-name-all https://dl.k8s.io/release/$RELEASE/bin/linux/$ARCH/{kubeadm,kubelet}
sudo chmod +x {kubeadm,kubelet}
```
Download service file for start kubelet and kubeadm, kubeadm use system service to manage kubelet. 
```
RELEASE_VERSION="v0.4.0"
curl --insecure --retry 3 --retry-connrefused -fL "https://raw.githubusercontent.com/kubernetes/release/$RELEASE_VERSION/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:$DOWNLOAD_DIR:g" | sudo tee /etc/systemd/system/kubelet.service

sudo mkdir -p /etc/systemd/system/kubelet.service.d

sudo curl --insecure --retry 3 --retry-connrefused -fL "https://raw.githubusercontent.com/kubernetes/release/$RELEASE_VERSION/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:$DOWNLOAD_DIR:g" | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
```
Download kubectl.
```
sudo curl --insecure --retry 3 --retry-connrefused -fLO https://dl.k8s.io/release/v1.26.0/bin/linux/amd64/kubectl
sudo cp kubectl /usr/local/bin
sudo chmod +x /usr/local/bin/kubectl
alias k='kubectl'
```
Enabling and Starting kubelet
```
sudo systemctl enable --now kubelet

```
####  Use kubeadm to initial Installation

**Pulling Kubernetes Container Images**

kubeadm will pull the core component of k8s, which are
-kube-apiserver
-kube-controller-manager
-kube-scehduler
-kube-proxy
-pause
-etcd
-coredns

```
sudo kubeadm config images pull --cri-socket unix:///var/run/crio/crio.sock --kubernetes-version=v1.26.1 --v=5
```

**Config kubeadm init parameters** 

Kubeadm require some parameter to initionize the installation which include NODEIP, cluster-dns, POD_CIDR, SERVICE_CIDR, also certificate parameter like sans etc., kubeadm will also create a token for worker node to join.

```
local_ip=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
CLUSTERDNSIP="10.96.0.10"
cat <<EOF | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS=--node-ip=$local_ip,--cluster-dns=$CLUSTERDNSIP
EOF

IPADDR=$local_ip
NODENAME=`hostname | tr -d '-'`
POD_CIDR="10.244.0.0/16"
SERVICE_CIDR="10.96.0.0/12"
echo $IPADDR $NODENAME  | sudo tee -a  /etc/hosts
```
Initializing the Kubernetes Cluster
```
sudo kubeadm reset -f 
sudo kubeadm init --cri-socket=unix:///var/run/crio/crio.sock --apiserver-advertise-address=$IPADDR  --apiserver-cert-extra-sans=$IPADDR,k8strainingmaster001.westus.cloudapp.azure.com  --service-cidr=$SERVICE_CIDR --pod-network-cidr=$POD_CIDR --node-name $NODENAME  --token-ttl=0 -v=5
```

**Configuring kubectl for the Current User and Root**

after done the kubeadm installation, a kubeconfig file will be created which include the certificate for kubectl client to use to talk to kube-api server. 

```
mkdir -p /home/ubuntu/.kube
sudo cp -f /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config
sudo mkdir -p /root/.kube
sudo cp -f /home/ubuntu/.kube/config /root/.kube/config
kubectl --kubeconfig /home/ubuntu/.kube/config config set-cluster kubernetes --server "https://$local_ip:6443"

```
#### create token for other worker node to join

**create a new token for worker node to join**

```bash
kubeadm token create --print-join-command > /home/ubuntu/workloadtojoin.sh
kubeadm config print join-defaults  > /home/ubuntu/kubeadm-join.default.yaml
echo '#sudo kubeadm join --config kubeadm-join.default.yaml' | sudo tee -a  /home/ubuntu/workloadtojoin.sh
chmod +x /home/ubuntu/workloadtojoin.sh
cat /home/ubuntu/workloadtojoin.sh 
```

#### Install Calico CNI 

The default bridge CNI in Kubernetes does not support cross-node networking. To enable this capability, we recommend replacing the default bridge with Calico. Calico uses VXLAN technology to facilitate network expansion across multiple nodes, providing enhanced networking features.

Calico CNI extends standard Kubernetes API with its own API definitions, allowing for advanced network configurations. The installation and management of Calico are streamlined through the use of tigera-operator.yaml and custom-resources.yaml. The Tigera Operator automates Calico's lifecycle management, while custom-resources.yaml enables administrators to tailor Calico's configuration to the specific needs of their Kubernetes cluster.

The configuration below includes enabling IP forwarding for containers. Typically, this setting is not necessary unless the container acts as a Layer 3 router, involving multiple IP interfaces. In this setup, BGP is disabled because we utilize VXLAN for networking, which does not require direct exchange of POD IPs across nodes.

This approach ensures that Calico provides robust and flexible networking capabilities for Kubernetes clusters, supporting a wide range of deployment scenarios, including those requiring cross-node networking and advanced network routing features.

```bash
cd $HOME
#sudo curl --insecure --retry 3 --retry-connrefused -fL https://github.com/projectcalico/calico/releases/latest/download/calicoctl-linux-amd64 -o /usr/local/bin/calicoctl
sudo curl --insecure --retry 3 --retry-connrefused -fL https://github.com/projectcalico/calico/releases/download/v3.25.0/calicoctl-linux-amd64 -o /usr/local/bin/calicoctl
sudo chmod +x /usr/local/bin/calicoctl
curl --insecure --retry 3 --retry-connrefused -fLO https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml
kubectl --kubeconfig /home/ubuntu/.kube/config create -f tigera-operator.yaml
kubectl rollout status deployment tigera-operator -n tigera-operator
curl --insecure --retry 3 --retry-connrefused -fLO https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/custom-resources.yaml
sed -i -e "s?blockSize: 26?blockSize: 24?g" custom-resources.yaml
sed -i -e "s?VXLANCrossSubnet?VXLAN?g" custom-resources.yaml
sed -i -e "s?192.168.0.0/16?10.244.0.0/16?g" custom-resources.yaml
sed -i '/calicoNetwork:/a\    containerIPForwarding: Enabled ' custom-resources.yaml
sed -i '/calicoNetwork:/a\    bgp: Disabled ' custom-resources.yaml
kubectl --kubeconfig /home/ubuntu/.kube/config create namespace calico-system
sleep 1
kubectl  get namespace calico-system
kubectl --kubeconfig /home/ubuntu/.kube/config apply  -f custom-resources.yaml
sleep 5
kubectl rollout status deployment calico-kube-controllers -n calico-system
kubectl rollout status ds calico-node -n calico-system

```

use `sudo calicoctl node status` to check calico node status, until it show calico process is running 
use `kubectl get tigerastatus` to check calico status via calico extended api

after install calico. restart coredns is required
```
kubectl rollout restart deployment coredns -n kube-system
kubectl rollout status deployment coredns -n kube-system
```


### install worker node

To configure the worker nodes in your Kubernetes cluster, you need to install specific components that manage the container lifecycle and networking. Each worker node requires the installation of kubelet and cri-o for container management, as well as kube-proxy to set up iptables rules for service-to-container communication.

Since the commands for installing these components on the worker nodes overlap with those covered in the "Install Master Node" section, this guide will focus on providing a streamlined, "simple way" to set up each worker node. This method allows for a quick and efficient installation by copying and pasting the script below directly into the terminal of each worker node.

Access Your Worker Node:
```bash
ssh ubuntu@k8strainingworker001.westus.cloudapp.azure.com
```
and Execute the Installation Script by Copy and paste the following script into the terminal of the worker node to start the installation process:

```
#!/bin/bash -xe

error_handler() {
    echo -e "\e[31mAn error occurred. Exiting...\e[0m" >&2
    tput bel
    
}

trap error_handler ERR

cd $HOME
sudo apt-get update -y
sudo apt-get install socat conntrack -y
sudo apt-get install jq -y
sudo apt-get install apt-transport-https ca-certificates -y

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

OS="xUbuntu_22.04"
VERSION="1.25"

echo "deb [signed-by=/usr/share/keyrings/libcontainers-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" | sudo tee  /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb [signed-by=/usr/share/keyrings/libcontainers-crio-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list

mkdir -p /usr/share/keyrings
sudo curl -L --retry 3 --retry-delay 5 https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/libcontainers-archive-keyring.gpg.tmp
sudo mv -f /usr/share/keyrings/libcontainers-archive-keyring.gpg.tmp /usr/share/keyrings/libcontainers-archive-keyring.gpg
sudo curl -L --retry 3 --retry-delay 5 https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg.tmp
sudo mv -f /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg.tmp /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg

sudo apt-get update
sudo apt-get install cri-o cri-o-runc -y

sudo systemctl daemon-reload
sudo systemctl enable crio
sudo systemctl start crio

DOWNLOAD_DIR="/usr/local/bin"
sudo mkdir -p "$DOWNLOAD_DIR"
CRICTL_VERSION="v1.25.0"
ARCH="amd64"
curl  --insecure --retry 3 --retry-connrefused -fL "https://github.com/kubernetes-sigs/cri-tools/releases/download/$CRICTL_VERSION/crictl-$CRICTL_VERSION-linux-$ARCH.tar.gz" | sudo tar -C $DOWNLOAD_DIR -xz

CNI_PLUGINS_VERSION="v1.1.1"
ARCH="amd64"
DEST="/opt/cni/bin"
sudo mkdir -p "$DEST"
curl  --insecure --retry 3 --retry-connrefused -fL "https://github.com/containernetworking/plugins/releases/download/$CNI_PLUGINS_VERSION/cni-plugins-linux-$ARCH-$CNI_PLUGINS_VERSION.tgz" | sudo tar -C "$DEST" -xz


#RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
RELEASE="v1.26.1"
ARCH="amd64"
DOWNLOAD_DIR="/usr/local/bin"
sudo mkdir -p "$DOWNLOAD_DIR"
cd $DOWNLOAD_DIR
sudo curl --insecure --retry 3 --retry-connrefused -fL --remote-name-all https://dl.k8s.io/release/$RELEASE/bin/linux/$ARCH/{kubeadm,kubelet}
sudo chmod +x {kubeadm,kubelet}

RELEASE_VERSION="v0.4.0"
curl --insecure --retry 3 --retry-connrefused -fL "https://raw.githubusercontent.com/kubernetes/release/$RELEASE_VERSION/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:$DOWNLOAD_DIR:g" | sudo tee /etc/systemd/system/kubelet.service

sudo mkdir -p /etc/systemd/system/kubelet.service.d

sudo curl --insecure --retry 3 --retry-connrefused -fL "https://raw.githubusercontent.com/kubernetes/release/$RELEASE_VERSION/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:$DOWNLOAD_DIR:g" | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
sudo mkdir -p /etc/kubernetes/manifests

sudo curl --insecure --retry 3 --retry-connrefused -fLO https://dl.k8s.io/release/v1.26.0/bin/linux/amd64/kubectl

sudo chmod +x /usr/local/bin/kubectl

sudo systemctl enable --now kubelet
cd $HOME
[ $? -eq 0 ] && echo "installation done"  
trap - ERR
```

### Joining a Worker Node to the Cluster

Now that we have everything set up, it's time to join the worker node to the cluster. This process involves using a token for joining, as well as the hash of the master node's CA certificate for authentication purposes. This ensures the worker node is joining the intended Kubernetes cluster.

Access the Master Node
Start by SSH-ing into the master node with the following command:
```bash
ssh ubuntu@k8strainingmaster001.westus.cloudapp.azure.com
```

Retrieve the Join Command
Once logged into the master node, use the following command to display the join token and CA certificate hash. This information is stored in the workloadtojoin.sh file:
```bash
cat /home/ubuntu/workloadtojoin.sh
```

Copy the content displayed by the cat command.

Exit the Master Node
After copying the necessary join command, exit the master node session.

SSH into the Worker Node
Next, access your worker node via SSH:

```bash
ssh ubuntu@k8strainingworker001.westus.cloudapp.azure.com
```

Join the Cluster
On the worker node, paste the previously copied join command to connect the worker node to the Kubernetes cluster. Replace <your master node ip>, Replace <paste your token here> and <paste your hash here> with the actual token and hash values you copied earlier. This command requires sudo to ensure it has the necessary permissions:
```bash
sudo kubeadm join <master node ip>:6443 --token <paste your token here> --discovery-token-ca-cert-hash <paste your hash here>
```

Note: If there's a need to reset the Kubernetes setup on the worker node before joining, you can use `sudo kubeadm reset -f`. This step is generally only necessary if you're reconfiguring or troubleshooting the node.

Following these steps will successfully join your worker node to the Kubernetes cluster. You can repeat the process for multiple worker nodes to expand the cluster's capacity for running workloads.

use below to check cluster node
 ```bash
kubectl get node -o wide
```
you are expected to see both master node (ubuntu 22) and worker node (worker001) shall in Ready status. 

```bash
kubectl get node -o wide
NAME        STATUS   ROLES           AGE    VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
ubuntu22    Ready    control-plane   5m9s   v1.26.1   10.0.0.4      <none>        Ubuntu 22.04.3 LTS   6.2.0-1019-azure   cri-o://1.25.4
worker001   Ready    <none>          112s   v1.26.1   10.0.0.5      <none>        Ubuntu 22.04.3 LTS   6.2.0-1019-azure   cri-o://1.25.4
```

After Successfully Joining Worker Nodes to the Cluster
Once you have successfully joined the worker nodes to the cluster, return to the master node to continue the setup or deployment process. Use the SSH command provided earlier to access the master node and proceed with your Kubernetes configuration or application deployment.


### Deploy Demo Application And Enable Auto Scalling (HPA)

 After successfully joining the worker nodes to the cluster, the next step is to deploy a demo application and enable auto-scaling using Horizontal Pod Autoscaler (HPA). This process involves executing a script on the master node that sets up the demo application and configures HPA to automatically scale the number of pods based on certain metrics, such as CPU usage.

Continue on the Master Node
To proceed, return to the master node by pasting and executing the following CLI command:
```bash
ssh ubuntu@k8strainingmaster001.westus.cloudapp.azure.com
```
Once logged in, run the deployment script by copying and pasting below script into the terminal for deploying your demo application and setting up HPA:


```bash

error_handler() {
    echo -e "\e[31mAn error occurred. Exiting...\e[0m" >&2
    tput bel
    
}

trap error_handler ERR

kubectl get node | grep worker | grep Ready && echo "Worker node exists"
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml

kubectl rollout status deployment local-path-provisioner -n local-path-storage

kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

kubectl create -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/examples/pvc/pvc.yaml
kubectl create -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/examples/pod/pod.yaml

kubectl delete pod volume-test
kubectl delete pvc local-path-pvc

curl  --insecure --retry 3 --retry-connrefused -fL "https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml" -o components.yaml
sed -i '/- --metric-resolution/a \ \ \ \ \ \ \ \ - --kubelet-insecure-tls' components.yaml

kubectl apply -f components.yaml
kubectl rollout status deployment metrics-server -n kube-system

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
kubectl rollout status deployment controller -n metallb-system
kubectl rollout status ds speaker -n metallb-system
kubectl get svc webhook-service -n metallb-system
kubectl get all -n metallb-system

cd $HOME
local_ip=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}') 
cat <<EOF | sudo tee metallbippool.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - $local_ip/32
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
EOF
kubectl apply -f metallbippool.yaml

kubectl apply -f  https://raw.githubusercontent.com/Kong/kubernetes-ingress-controller/v2.10.0/deploy/single/all-in-one-dbless.yaml
kubectl rollout status deployment proxy-kong -n kong
kubectl rollout status deployment ingress-kong -n kong

cat <<EOF | kubectl apply -f -
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
kubectl rollout status deployment nginx-deployment

cat << EOF | kubectl apply -f -
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

kubectl get namespace cert-manager || kubectl create namespace cert-manager 
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.3.1/cert-manager.yaml
kubectl rollout status deployment cert-manager -n cert-manager
kubectl rollout status deployment cert-manager-cainjector -n cert-manager
kubectl rollout status deployment cert-manager-webhook  -n cert-manager
cat << EOF | kubectl apply -f -
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer-test
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: test-tls-test
spec:
  secretName: test-tls-test
  duration: 2160h # 90d
  renewBefore: 360h # 15d
  issuerRef:
    name: selfsigned-issuer-test
    kind: ClusterIssuer
  commonName: kong.example
  dnsNames:
  - ubuntu22
EOF


cat <<EOF  | kubectl apply -f - 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx
  annotations:
    konghq.com/strip-path: 'true'
    cert-manager.io/cluster-issuer: selfsigned-issuer-test
spec:
  tls:
  - hosts:
    - ubuntu22 
  ingressClassName: kong
  rules:
  - host: ubuntu22
    http:
      paths:
      - path: /default
        pathType: ImplementationSpecific
        backend:
          service:
            name: nginx-deployment
            port:
              number: 80
EOF


cat << EOF | kubectl apply -f -
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
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
kubectl rollout status deployment nginx-deployment
kubectl get deployment nginx-deployment
kubectl get pod 
trap - ERR

```

Please note that executing the script may take a few minutes. Once completed, you can expect to see two deployments with two Nginx pods up and running, demonstrating the application deployment and ready for test the auto-scaling capabilities of your Kubernetes cluster.



### Verify the deployment is sucessful 

To confirm that the deployment of your Nginx service has been successfully completed, you can test the response from the Nginx server using the curl command:

```bash
curl -k https://ubuntu22/default
```
This command should return a response from the Nginx server, indicating that the service is active and capable of handling requests.

Upon successful installation and deployment of the Nginx service, you should observe that the application deployment is operational with 2 pods running the Nginx container. You can verify this by retrieving the list of running pods using kubectl:


```bash
kubectl get pod
```
shall see two pod is running. 
```bash
kubectl get pod
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-55c7f467f8-dxmqt   1/1     Running   0          1m
nginx-deployment-55c7f467f8-kkr8r   1/1     Running   0          1m
```

With the Nginx service deployed and verified, we are now prepared to initiate benchmark traffic towards the Nginx service. This step will demonstrate Kubernetes' ability to dynamically scale out additional Nginx pods to accommodate the incoming request load.

### Stress Test the Nginx Server with Hey

To evaluate the scalability and responsiveness of the Nginx web server under heavy load, we'll utilize the hey tool. This utility is designed to generate a high volume of requests to stress test the server, allowing us to observe how Kubernetes dynamically scales the application to meet demand.

```bash

hey -n 10000 -c 1000 https://ubuntu22/default
```
This command instructs hey to send a total of 10,000 requests (-n 10000) with a concurrency level of 1,000 (-c 1000) to the Nginx server.


### Monitor Application Scaling

After initiating the stress test with **hey**, you can monitor the deployment as Kubernetes automatically scales out by adding new Pods to handle the increased load. Use the watch command alongside kubectl get pods to observe the scaling process in real time:

```bash
watch kubectl get pods
```
expect to see pod increasing as a response to the increased load.
```bash
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-55c7f467f8-d7bx9   1/1     Running   0          20s
nginx-deployment-55c7f467f8-dx7ql   1/1     Running   0          20s
nginx-deployment-55c7f467f8-dxmqt   1/1     Running   0          5m39s
nginx-deployment-55c7f467f8-g4754   1/1     Running   0          20s
nginx-deployment-55c7f467f8-hdbcc   1/1     Running   0          20s
nginx-deployment-55c7f467f8-kbkw6   1/1     Running   0          35s
nginx-deployment-55c7f467f8-kkr8r   1/1     Running   0          5m39s
nginx-deployment-55c7f467f8-r6ndt   1/1     Running   0          35s
nginx-deployment-55c7f467f8-xr2l7   1/1     Running   0          5s
```
As hey continues to send traffic to the Nginx service, you will see the number of Pods gradually increase, demonstrating Kubernetes' Horizontal Pod Autoscaler (HPA) in action. This auto-scaling feature ensures that your application can adapt to varying levels of traffic by automatically adjusting the number of Pods based on predefined metrics such as CPU usage or request rate.

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