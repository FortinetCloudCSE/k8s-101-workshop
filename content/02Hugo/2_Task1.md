---
title: "Task 1 - use Kubeadm to install kubernetes"
menuTitle: "Installation"
weight: 1
---

There are many ways to install k8s. 
### Use Bash script to install kubernetes 

0. Prerequisites
* Two Linux servers (one for the master node and one for the worker node).
* Each server should have at least 2 CPUs, 4GB of RAM, and network connectivity between them.
```bash
ssh ubuntu@k8strainingmaster001.westus.cloudapp.azure.com
ssh ubuntu@k8strainingworker001.westus.cloudapp.azure.com

```
* A user with sudo privileges on both servers.

SSH into both node to install required tools

```bash
sudo apt-get update -y
sudo apt-get install socat conntrack -y
sudo apt-get install jq -y
sudo apt-get install apt-transport-https ca-certificates -y
```
## Step 1: Setting Kernel Parameters for k8s
* install dep module for cri-o runtime

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
## 
## Step 2: Install CRI-O on Both Nodes

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
sudo curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/libcontainers-archive-keyring.gpg
sudo curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg

```
3. **Install CRI-O**
  
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

## Step 3: Install crictl
install crictl which is the client tool for interactive with crio. 
```bash
DOWNLOAD_DIR="/usr/local/bin"
sudo mkdir -p "$DOWNLOAD_DIR"
CRICTL_VERSION="v1.25.0"
ARCH="amd64"
curl  --insecure --retry 3 --retry-connrefused -fL "https://github.com/kubernetes-sigs/cri-tools/releases/download/$CRICTL_VERSION/crictl-$CRICTL_VERSION-linux-$ARCH.tar.gz" | sudo tar -C $DOWNLOAD_DIR -xz
```
After this step, you can optionaly use `sudo crictl info` to check the status of crio. it shall tell you the container runtime is ready, but the network status is not ready. 


## Step 4: Install CNI 

1. **download and install Container Network Interface (CNI) plugins**

CNI plugins are essential for configuring the network connectivity of containers in Kubernetes clusters. By installing these plugins, the Kubernetes cluster can manage network namespaces and connectivity for pods, enabling communication between pods across the cluster as well as with external networks.Check CNI release notes for more information https://github.com/containernetworking/cni/releases  
the default build-in CNI is bridge CNI, which only support single node cluster.
```
CNI_PLUGINS_VERSION="v1.1.1"
ARCH="amd64"
DEST="/opt/cni/bin"
sudo mkdir -p "$DEST"
curl  --insecure --retry 3 --retry-connrefused -fL "https://github.com/containernetworking/plugins/releases/download/$CNI_PLUGINS_VERSION/cni-plugins-linux-$ARCH-$CNI_PLUGINS_VERSION.tgz" | sudo tar -C "$DEST" -xz
```
After this step, you can optionaly use `sudo crictl info` and `journalctl -f -u crio` to check crio status . you shall see crictl show both runtime and network is ready and crio found a valid CNI configuration which is bridge
## Step 5: Install  kubeadm, kubelet and kubectl
kubeadm is the binary that responsible for k8s installation, kubelet is the binary that running on worker node which actually create the container by interact with cni and cri. kubectl is the client that talk to k8s API server for daily k8s operation. 
Below script downloading specific versions of kubeadm, kubelet, and kubectl, placing them in the system path, configuring kubelet to run as a systemd service, and ensuring it starts automatically.


Download 1.26.1 version kubeadm and kubelet 
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
Download service file for start kubelet and kubeadm
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

```
Enabling and Starting kubelet
```
sudo systemctl enable --now kubelet

```
## Step 6 use kubeadm to initial Installation

Pulling Kubernetes Container Images

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

Setting Node IP and Cluster DNS for kubelet

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
sudo kubeadm init --cri-socket=unix:///var/run/crio/crio.sock --apiserver-advertise-address=$IPADDR  --apiserver-cert-extra-sans=$IPADDR,k8strainingmaster001.westus.cloudapp.azure.com  --service-cidr=$SERVICE_CIDR --pod-network-cidr=$POD_CIDR --node-name $NODENAME  --token-ttl=0 -v=5
```

Configuring kubectl for the Current User and Root

```
mkdir -p /home/ubuntu/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config
sudo mkdir -p /root/.kube
sudo cp /home/ubuntu/.kube/config /root/.kube/config
kubectl --kubeconfig /home/ubuntu/.kube/config config set-cluster kubernetes --server "https://$local_ip:6443"

```
## Step 7 create token for other worker node to join
```bash
#grep --text discovery-token-ca-cert /var/log/user-data.log -B 1 | head -n 2 | tr -d '\n' | tr -d '\\' > /home/ubuntu/workloadtojoin.sh
kubeadm token create --print-join-command > /home/ubuntu/workloadtojoin.sh
kubeadm config print join-defaults  > /home/ubuntu/kubeadm-join.default.yaml
echo '#sudo kubeadm join --config kubeadm-join.default.yaml' | sudo tee -a  /home/ubuntu/workloadtojoin.sh
chmod +x /home/ubuntu/workloadtojoin.sh
cat /home/ubuntu/workloadtojoin.sh 
```

## Step 8 Replace Bridge CNI with Calico
the bridge cni does not support multiple node, so replace default bridge with calico
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
```
use `sudo calicoctl node status` to check calico status, until it show calico process is running 

after install calico. restart coredns is required
```
kubectl rollout restart deployment coredns -n kube-system
```
replace default bridge with flannel
```bash
kubectl --kubeconfig /home/ubuntu/.kube/config apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```
after install flannel , restart coredns is required 
```
kubectl rollout restart deployment coredns -n kube-system
```

## Step 9 Install Worker
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

## Step 10 Join worker node to cluster


ssh into worker node with `ssh ubuntu@k8strainingworker001.westus.cloudapp.azure.com`, then use token and hash to join worker node to cluster
```
sudo kubeadm join <ip:6443> -- token <token> --discovery-token-ca-cert-hash <hash> 

```
## Step 11 Create a test k8s deployment 

exit worker node, and ssh into master node again. use kubectl to create a nginx deployment.

```
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort
kubectl get service nginx

```
after this step, you shall able to access nginx via node IP 

```
nodePortNumber=$(kubectl get service nginx -o json | jq .spec.ports[0].nodePort)
curl worker:$nodePortNumber
```

## Step 12 Create a troubleshooting pod
```bash
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: multitool01-deployment
  labels:
      app: multitool01
spec:
  replicas: 2
  selector:
    matchLabels:
        app: multitool01
  template:
    metadata:
      labels:
        app: multitool01
    spec:
      containers:
        - name: multitool01
          image: praqma/network-multitool
          imagePullPolicy: IfNotPresent
          args:
            - /bin/sh
            - -c
            - /usr/sbin/nginx -g "daemon off;"
          securityContext:
            privileged: true
EOF
```
## Step 13 install metallb loadbalancer 


```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
```
forice metallb controller pod to run on master node

```
kubectl label node ubuntu22 dedicated=master
```
then modify metallb-native.yaml, use nodeSelector to schedue controller pod to run on master  
```
      nodeSelector:
        kubernetes.io/os: linux
        dedicated: master
```
create ippool for metallb to use

```bash
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.0.0.4/32
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
EOF
```
create loadbalancer service for nginx pod

```
cat <<EOF | kubectl apply -f - 
apiVersion: v1
kind: Service
metadata:
  name: ngnixlb
  annotations:
    metallb.universe.tf/loadBalancerIPs: 10.0.0.4
spec:
  sessionAffinity: ClientIP
  ports:
  - port: 8000
    targetPort: 80
  selector:
    app: nginx
  type: LoadBalancer
EOF
```
## Step 14 Use Troubelshooting pod to verify k8s
shell into pod
```
kubectl exec -it po/multitool01-deployment-5c8996747c-9txnw -- bash
```
check cluster internal dns whether working 
```
dig kubernetes.default.svc.cluster.local  | grep -A 2 ANSWER
```
access kuberntes service
```
curl  I --k https://kubernetes.default.svc.cluster.local
```
ping other pod ip address
```
ubuntu@ubuntu22:~$ k get pod -o wide
NAME                                      READY   STATUS    RESTARTS   AGE     IP             NODE     NOMINATED NODE   READINESS GATES
multitool01-deployment-5c8996747c-9txnw   1/1     Running   0          6m50s   10.244.158.2   worker   <none>           <none>
multitool01-deployment-5c8996747c-wpd4k   1/1     Running   0          7m46s   10.244.158.1   worker   <none>           <none>
ubuntu@ubuntu22:~$ kubectl exec -it po/multitool01-deployment-5c8996747c-9txnw -- ping 10.244.158.1
PING 10.244.158.1 (10.244.158.1) 56(84) bytes of data.
64 bytes from 10.244.158.1: icmp_seq=1 ttl=63 time=0.104 ms
```

