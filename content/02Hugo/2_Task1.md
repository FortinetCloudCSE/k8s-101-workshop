---
title: "Task 1 - Install kubernetes"
menuTitle: "Installation"
weight: 1
---

Self Managed Kubernetes  give users full control over their Kubernetes environments. Choosing the right method to install Self Managed Kubernetes can vary significantly based on the intended use case, from development and testing environments to production deployments. Here's a short description of different ways to install Kubernetes, tailored to specific needs:

## Choose your kubernetes 
### For Development and Testing
- Minikube:

Description: Minikube is the go-to solution for developers looking to run Kubernetes locally. It creates a single-node Kubernetes cluster on your local machine, allowing developers to test Kubernetes applications or experiment with Kubernetes features without the overhead of setting up a full cluster.
Best For: Individual developers and small teams experimenting with Kubernetes applications or learning the Kubernetes ecosystem.

- Kind (Kubernetes in Docker):

Description: Kind runs Kubernetes clusters in Docker containers. It's primarily designed for testing Kubernetes itself but is also an excellent tool for developers who want to test their applications, CI pipelines, or experiment with Kubernetes.
Best For: Kubernetes contributors, developers working on CI/CD pipelines, and testing Kubernetes configurations.

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

## use kubeadm to install kubernetes 



### nodes provided to user: 


* Multiple Ubuntu 22.04 version Linux VM 

1 or mutiple VM for master node
1 or multiple VM for workder node 

* A user with sudo privileges on both servers.
* Each server should have at least 2 CPUs, 4GB of RAM, and network connectivity between them. use below command to login 

```bash
ssh ubuntu@k8strainingmaster001.westus.cloudapp.azure.com
ssh ubuntu@k8strainingworker001.westus.cloudapp.azure.com

```

Here offer two options to install kubeadm, simple way and step by step approach

### simple way

with simple way, just login into master node and each worker node to run below script.

**ssh into master noder** then paste below command to install it
```
#!/bin/bash -xe

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
sudo cp kubectl /usr/local/bin 
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
sudo curl --insecure --retry 3 --retry-connrefused -fL https://github.com/projectcalico/calico/releases/latest/download/calicoctl-linux-amd64 -o /usr/local/bin/calicoctl
sudo chmod +x /usr/local/bin/calicoctl
curl --insecure --retry 3 --retry-connrefused -fLO https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml
kubectl --kubeconfig /home/ubuntu/.kube/config create -f tigera-operator.yaml
curl --insecure --retry 3 --retry-connrefused -fLO https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/custom-resources.yaml
sed -i -e "s?blockSize: 26?blockSize: 24?g" custom-resources.yaml
sed -i -e "s?VXLANCrossSubnet?VXLAN?g" custom-resources.yaml
sed -i -e "s?192.168.0.0/16?10.244.0.0/16?g" custom-resources.yaml
sed -i '/calicoNetwork:/a\    containerIPForwarding: Enabled ' custom-resources.yaml
sed -i '/calicoNetwork:/a\    bgp: Disabled ' custom-resources.yaml
kubectl --kubeconfig /home/ubuntu/.kube/config create namespace calico-system
kubectl --kubeconfig /home/ubuntu/.kube/config apply  -f custom-resources.yaml


kubectl rollout restart deployment coredns -n kube-system
kubectl rollout status deployment coredns -n kube-system 

cat /home/ubuntu/workloadtojoin.sh
[ $? -eq 0 ] && echo "installation done"  

```
meanwhile you can **ssh into worker node** to paste below script to install components on every worker node.
```
#!/bin/bash -xe

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
sudo cp kubectl /usr/local/bin
sudo chmod +x /usr/local/bin/kubectl

sudo systemctl enable --now kubelet
cd $HOME
[ $? -eq 0 ] && echo "installation done"  
```
after done the installation for master node and all worker node. 
`ssh ubuntu@k8strainingmaster001.westus.cloudapp.azure.com` then type 
`cat /home/ubuntu/workloadtojoin.sh` copy the output from this cat command. this is what you will need to paste on each worker node. 
then `ssh ubuntu@k8strainingworker001.westus.cloudapp.azure.com` to paste previously copied text to join workder node to kubernetes cluster. use sudo to execute the command, for example 

```bash 
sudo kubadm reset -f 
sudo kubeadm join 10.0.0.4:6443 --token <paste your token here> --discovery-token-ca-cert-hash <paste your hash here>
``` 
after a while. use `kubectl get node` on **master** node will see all nodes in **ready** status. which means you have installed a full functional multiple nodes cluster.

after sucessfully join worker node to cluster. paste below cli command to continue on **master** node
```bash
kubectl get node | grep worker | grep Ready && echo "Worker node exists"
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml

kubectl rollout status deployment local-path-provisioner -n local-path-storage

kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

kubectl create -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/examples/pvc/pvc.yaml
kubectl create -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/examples/pod/pod.yaml

curl  --insecure --retry 3 --retry-connrefused -fL "https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml" -o components.yaml
sed -i '/- --metric-resolution/a \ \ \ \ \ \ \ \ - --kubelet-insecure-tls' components.yaml

kubectl apply -f components.yaml
kubectl rollout status deployment metrics-server -n kube-system

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
kubectl rollout status deployment controller -n metallb-system

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
```
user expected to see two deployment with two nginx pod is up and running.
curl -k https://ubuntu22/default shall return response from nginx server

now the installation and nginx service deployment completed sucessfully.
we are ready to send benchmark traffic to nginx service and see how kubernetes can scale out more nginx pod to serve the request.

jump to section  **use hey to stress nginx** and follow instruction

### Step by Step approach



SSH into each master node to  install required tools

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
sudo curl -L --retry 3 --retry-delay 5 https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/libcontainers-archive-keyring.gpg
sudo curl -L --retry 3 --retry-delay 5 https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg

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

the bridge cni does not support cross node networking, so replace default bridge with calico. calico will use VXLAN to expand network across multiple nodes.

calico CNI provide extra network feature which has it's own API definition  as an extension to standard kubenetes API. tigera-operator.yaml and custom-resources.yaml facilitate a streamlined and customizable installation of Calico in a Kubernetes cluster. The Tigera Operator automates the management of Calico's lifecycle, while the custom-resources.yaml file allows administrators to specify the configuration of Calico to meet the cluster's specific networking and security needs. Below configuration enabled ipforwarding for **container** this is usually is not required unless container is a layer 3 router which include multiple IP interface. bgp is disabled as we are using VXLAN instead directly exchange POD ip across nodes. 

```bash
cd $HOME
sudo curl --insecure --retry 3 --retry-connrefused -fL https://github.com/projectcalico/calico/releases/latest/download/calicoctl-linux-amd64 -o /usr/local/bin/calicoctl
sudo chmod +x /usr/local/bin/calicoctl
curl --insecure --retry 3 --retry-connrefused -fLO https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml
kubectl --kubeconfig /home/ubuntu/.kube/config create -f tigera-operator.yaml
curl --insecure --retry 3 --retry-connrefused -fLO https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/custom-resources.yaml
sed -i -e "s?blockSize: 26?blockSize: 24?g" custom-resources.yaml
sed -i -e "s?VXLANCrossSubnet?VXLAN?g" custom-resources.yaml
sed -i -e "s?192.168.0.0/16?10.244.0.0/16?g" custom-resources.yaml
sed -i '/calicoNetwork:/a\    containerIPForwarding: Enabled ' custom-resources.yaml
sed -i '/calicoNetwork:/a\    bgp: Disabled ' custom-resources.yaml
kubectl --kubeconfig /home/ubuntu/.kube/config create namespace calico-system
kubectl --kubeconfig /home/ubuntu/.kube/config apply  -f custom-resources.yaml
kubectl rollout status deployment calico-kube-controllers -n calico-system
kubectl rollout status ds calico-node -n calico-system
```

use `sudo calicoctl node status` to check calico status, until it show calico process is running 

after install calico. restart coredns is required
```
kubectl rollout restart deployment coredns -n kube-system
kubectl rollout status deployment coredns -n kube-system
```






####  Install Worker Node

Worker node require install kubelet and cri-o to manager container life-cycle. also require kube-proxy to setup iptables for service to container. 

```bash
ssh ubuntu@k8strainingworker001.westus.cloudapp.azure.com
```
then run below 
```bash
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
sudo curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/libcontainers-archive-keyring.gpg
sudo curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg

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
sudo cp kubectl /usr/local/bin
sudo chmod +x /usr/local/bin/kubectl

sudo systemctl enable --now kubelet
cd $HOME
```

#### Join worker node to cluster

worker require use token to join cluster, also hash of master node CA certificate is required to authenticate right cluster to join

ssh into worker node with `ssh ubuntu@k8strainingworker001.westus.cloudapp.azure.com`, then use token and hash to join worker node to cluster. user need use `cat /home/ubuntu/workloadtojoin.sh` from master node , copy the content from `cat` command and then paste into each **worker** node. do not forget add `sudo` before the kubeadm join command.

```
sudo kubeadm join <ip:6443> -- token <token> --discovery-token-ca-cert-hash <hash> 

```

after join worker node to cluster, exit from worker node. you are no longer need to ssh into worker node. all the operation shall be done on master node. 
ssh into master node again to continue next installation. 


#### Create host-local storage class


Persistent storage in Kubernetes is crucial for managing stateful applications such as database application, which require stable and persistent data storage that outlives the lifecycle of individual pods. Unlike ephemeral storage, which is tied to the lifecycle of a pod, persistent storage ensures that data is retained across pod restarts, deployments, and even cluster outages, making it essential for applications like databases, content management systems, and any service that needs to store user data or state persistently.Kubernetes supports a variety of persistent storage types, accommodating different use cases, such as local host storage, NFS , Block Storage like AWS EBS, Object Storage like AWS S3, also kubernetes allow use CSI to using various storage backends via standardized plugin interface.  here we use host-local storage with a host-local storage class also config it as default storage class. 


```
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml

kubectl rollout status deployment local-path-provisioner -n local-path-storage

kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```
use `kubectl get sc` to check installed storageclass. 
optionly, verify with below command
```
kubectl create -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/examples/pvc/pvc.yaml
kubectl create -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/examples/pod/pod.yaml
```

use `kubectl get pvc` and `kubectl get pod` to check the pod use pvc.


#### Enable resource-API 

The Resource Metrics API in Kubernetes is crucial for providing core metrics about pods and nodes within a cluster, such as CPU and memory usage to enable feature like Horizontal Pod Autoscaler (HPA), Vertical Pod Autoscaler (VPA) and enable efficent resource scheduling.

```
curl  --insecure --retry 3 --retry-connrefused -fL "https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml" -o components.yaml
sed -i '/- --metric-resolution/a \ \ \ \ \ \ \ \ - --kubelet-insecure-tls' components.yaml

kubectl apply -f components.yaml
kubectl rollout status deployment metrics-server -n kube-system
```
 
use `kubectl top node` and `kubectl top pod` to check the pod and node resource usage


#### install metallb loadbalancer 

In a self-managed Kubernetes environment, external traffic management and service exposure are not handled automatically by the infrastructure, unlike managed Kubernetes services in cloud environments (e.g., AWS ELB with EKS, Azure Load Balancer with AKS, or Google Cloud Load Balancer with GKE). This is where solutions like MetalLB and the Kong Ingress Controller become essential

MetalLB provides a network load balancer implementation for Kubernetes clusters that do not run on cloud providers, offering a LoadBalancer type service. In cloud environments, when you create a service of type LoadBalancer, the cloud provider provisions a load balancer for your service. In contrast, on-premises or self-managed clusters do not have this luxury. MetalLB fills this gap by allocating IP addresses from a configured pool and managing access to services through these IPs, enabling external traffic to reach the cluster services.




```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
kubectl rollout status deployment controller -n metallb-system

```



**create ippool for metallb to use** 

```bash 
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
```
use `kubectl get ipaddresspool -n metallb-system` to check installed ippool


#### Install Kong ingress controller 
The Kong Ingress Controller is an Ingress controller for Kubernetes that manages external access to HTTP services within a cluster using Kong Gateway. It processes Ingress resources to configure HTTP routing, load balancing, authentication, and other functionalities, leveraging Kong's powerful API gateway features for Kubernetes services.  Kong will use the ippool that managed by metallb. 


```bash
kubectl apply -f  https://raw.githubusercontent.com/Kong/kubernetes-ingress-controller/v2.10.0/deploy/single/all-in-one-dbless.yaml
kubectl rollout status deployment proxy-kong -n kong
kubectl rollout status deployment ingress-kong -n kong

```

use `kubectl get svc kong-proxy -n kong` to check installed load balancer which is kong-proxy
use `kubectl get ingressclasses` to check kong become the ingress controller. 


after done all above, now you have completed the setup of kubernetes master node. 
it's time to setup worker node and join cluster. remember without worker node. you will not able to create application POD unless you ask speically to create POD on master node which usually is not the option for production deployment. 
 
#### Create nginx deployment  

create nginx deployment with replicas set to 2. the container also configured resource usage limition for cpu and memory.

```bash
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
```

#### create nginx clusterIP svc for nginx-deployment 

```bash
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
```
user can use `kubectl get svc nginx-deployment` to check the installed **ClusterIP** service. which essentially created an iptables entry to loadbalancer traffic from cluster-internal to nginx pod regardless the pod is on same worker node or different worker node. ClusterIP is only for cluster-internal traffic, traffic outside of cluster will not able to reach clusterIP.  to make traffic outside cluster like from internet to reach nginx container. user will require to create loadbalancer type service or ingress service.





#### Create https ingress rule for nginx-deployment 
to support https, a certificate for ingress controller is required. user can choose "cert-manager" for manage and deploy certificate. 

use below cli to deploy cert-manager which is used to issue certificate needed for service

```bash
kubectl get namespace cert-manager || kubectl create namespace cert-manager 
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.3.1/cert-manager.yaml
kubectl rollout status deployment cert-manager -n cert-manager
```
 

once deployed. we need to create a certificate for service. 

```bash
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

```
use `kubectl get secret  test-tls-test` and `kubectl get cert test-tls-test` to check deployment

create ingress rule for nginx 

```
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
```
use `kubectl get ingress nginx` and `kubectl describe ingress nginx` to check status

use `curl -k  https://ubuntu22/default` and `curl http://ubuntu22/default` to verify 




after deploy ingress rule. now you shall able to access nginx via `curl http://ubuntu22/default`, while use `curl http://ubuntu22/` will got error message  

use `kubectl get ingress nginx` and `kubectl describe ingress nginx` to check the ingress rule

####  create HPA for scale application 


create HPA for nginx deployment, allow increase replicas upon container CPU utlization over the threshold

```
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
```
after that. use `kubectl get hpa` and `kubectl describe hpa` to check the status 

#### use hey to stress nginx 

use *hey* to stress the nginx webserver , then monitor the pod creation
```bash

hey -n 10000 -c 1000 https://ubuntu22/default
```

use `kubectl get deployment nginx-deployment` to check the change of deployment. 
use `kubectl get hpa` and `kubectl describe hpa` to check the new size of replicas.

after a while, when the traffic to nginx pod decreased, check hpa and deployment again for the size of replicas.
use `kubectl top pod` and `kubectl top node` to check the resource usage status
user expected to see the number of pod increased 

 




