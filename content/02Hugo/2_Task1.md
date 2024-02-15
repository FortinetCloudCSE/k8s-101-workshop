---
title: "Task 1 - Install kubernetes"
menuTitle: "Installation"
weight: 1
---

Choosing the right method to install Self Managed Kubernetes can vary significantly based on the intended use case, from development and testing environments to production deployments. Here's a short description of different ways to install Kubernetes, tailored to specific needs:

## For Development and Testing
#### **Minikube**:

Description: Minikube is the go-to solution for developers looking to run Kubernetes locally. It creates a single-node Kubernetes cluster on your local machine, allowing developers to test Kubernetes applications or experiment with Kubernetes features without the overhead of setting up a full cluster.
Best For: Individual developers and small teams experimenting with Kubernetes applications or learning the Kubernetes ecosystem.

####  **Kind (Kubernetes in Docker)**:

Description: Kind runs Kubernetes clusters in Docker containers. It's primarily designed for testing Kubernetes itself but is also an excellent tool for developers who want to test their applications, CI pipelines, or experiment with Kubernetes.
Best For: Kubernetes contributors, developers working on CI/CD pipelines, and testing Kubernetes configurations.
## For Lightweight or Edge Environments
#### **K3s**:

Description: K3s is a lightweight, easy-to-install Kubernetes distribution, designed for edge computing, IoT, CI/CD environments, and any situation where a full Kubernetes cluster may be overkill.
Best For: Scenarios requiring a lightweight footprint, including edge computing, IoT devices, and small-scale cloud deployments.
#### **MicroK8s**:

Description: MicroK8s provides a low-maintenance, easily installable Kubernetes for workstations and edge/IoT devices. It offers a simple, fast, and secure way to run Kubernetes, with a focus on quick installation and operation.
Best For: Developers, edge computing scenarios, and IoT applications requiring quick setup and minimal Kubernetes operation knowledge.
## For Production Deployment
#### **Kubeadm**:

Description: Kubeadm is a tool built by the Kubernetes community to provide a standard way to bootstrap Kubernetes clusters. It handles both the initial cluster setup and ongoing cluster lifecycle tasks, such as upgrades. Kubeadm gives users a great deal of flexibility and control over their Kubernetes clusters.
Best For: Organizations looking for a customizable production-grade Kubernetes setup that adheres to best practices. Suitable for those with specific infrastructure requirements and those who wish to integrate Kubernetes into existing systems with specific configurations.
#### **Kubespray**:

Description: Kubespray is an Ansible-based tool for deploying highly available Kubernetes clusters. It supports multiple cloud and bare-metal environments and provides users with the flexibility to customize their Kubernetes installations.
Best For: Users seeking to deploy Kubernetes on a variety of infrastructure types (cloud, on-premises, bare-metal) and require a tool that supports extensive customization and scalability.
#### **Rancher**:

Description: Rancher is an open-source platform that provides a complete software stack for teams adopting containers. It simplifies Kubernetes cluster management and is capable of running Kubernetes on any infrastructure.
Best For: Organizations looking for an enterprise Kubernetes management platform that simplifies the operation of Kubernetes across any infrastructure, offering UI and API-based management.
#### Summary
The choice of Kubernetes installation method depends on the specific needs of the development lifecycle, infrastructure, and operational preferences. Minikube and Kind are excellent for development and testing, K3s and MicroK8s are ideal for lightweight or edge environments, and tools like Kubeadm, Kubespray, and platforms like Rancher offer the flexibility and control needed for production deployments. Each tool provides unique advantages, whether you're a developer testing a new application, an IoT engineer working at the edge, or an IT professional deploying a scalable, production-ready Kubernetes environment.

### Step by Step procedure for use kubeadm to install kubernetes

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
sudo apt-get install hey -y
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
sudo kubeadm reset -f 
sudo kubeadm init --cri-socket=unix:///var/run/crio/crio.sock --apiserver-advertise-address=$IPADDR  --apiserver-cert-extra-sans=$IPADDR,k8strainingmaster001.westus.cloudapp.azure.com  --service-cidr=$SERVICE_CIDR --pod-network-cidr=$POD_CIDR --node-name $NODENAME  --token-ttl=0 -v=5
```

Configuring kubectl for the Current User and Root

```
mkdir -p /home/ubuntu/.kube
sudo cp -f /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config
sudo mkdir -p /root/.kube
sudo cp -f /home/ubuntu/.kube/config /root/.kube/config
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
use `kubectl rollout status deployment controller -n metallb-system` to check status` 
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
## Step 15 Create host-local storage class
```
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml

kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```
verify
```
kubectl create -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/examples/pvc/pvc.yaml
kubectl create -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/examples/pod/pod.yaml
```
## Step 16 Enable resource-API 
```
curl  --insecure --retry 3 --retry-connrefused -fL "https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml" -o components.yaml
sed -i '/- --metric-resolution/a \ \ \ \ \ \ \ \ - --kubelet-insecure-tls' components.yaml

kubectl apply -f components.yaml
```
use `kubectl rollout status deployment metrics-server -n kube-system` to check the deployment
use `kubectl top node` and `kubectl top pod` to check the pod and node resource usage

## Step 17 HPA
create nginx deployment with replicas set to 1.
```bash
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 1
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

```
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
  minReplicas: 1
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

use *hey* to stress the nginx webserver , then monitor the pod creation
```bash
hey -n 10000 -c 100 http://10.0.0.4:8000
```

use `kubectl get deployment nginx-deployment` to check the change of deployment. 
use `kubectl get hpa` and `kubectl describe hpa` to check the new size of replicas.

after a while, when the traffic to nginx pod decreased, check hpa and deployment again for the size of replicas.
use `kubectl top pod` and `kubectl top node` to check the resource usage status


## Step 15 create ingress rule
install ingress controller, kong is a popular ingress controller. let's install kong ingress controller. 

```bash
kubectl apply -f  https://raw.githubusercontent.com/Kong/kubernetes-ingress-controller/v2.10.0/deploy/single/all-in-one-dbless.yaml
```
use `kubectl rollout status deployment proxy-kong -n kong` and `kubectl rollout status deployment ingress-kong -n kong` to check deployment status 

use `kubectl get svc kong-proxy -n kong` to check now the load balancer is kong-proxy
use `kubectl get ingress-class` to check kong become the ingress controller. 
create nginx clusterIP svc for ingress rule to use as backend.

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


create ingress rule 
```bash
cat << EOF | kubectl apply -f - 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx
  annotations:
    konghq.com/strip-path: 'true'
spec:
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
after deploy ingress rule. now you shall able to access nginx via `curl http://ubuntu22/default`, while use `curl http://ubuntu22/` will got error message  

use `kubectl get ingress nginx` and `kubectl describe ingress nginx` to check the ingress rule

## Step 16 create https ingress rule

deploy cert-manager which is used to issue certificate needed for service
```bash
kubectl get namespace cert-manager || kubectl create namespace cert-manager 
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.3.1/cert-manager.yaml
```
use `k rollout status deployment cert-manager -n cert-manager` to check the deployment status

once deployed. we need to create a certificate for service. 
```bash
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
```
use `k get secret  test-tls-test` and `k get cert test-tls-test` to check deployment

then use `k delete ingress nginx` to delete previous http ingress rule, then use below to create new one 
```
cat EOF >> | kubectl apply -f - 
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
use `k get ingress nginx` and `k describe ingress nginx` to check status

use `curl -k  https://ubuntu22/default` and `curl http://ubuntu22/default` to verify 

## Step 18 rollupdate deployment

The default update strategy for Kubernetes Deployments, specifically the RollingUpdate strategy, is designed to update pods in a deployment with zero downtime by gradually replacing old pods with new ones. This strategy ensures that your application remains available during the update process. The rollingUpdate field specifies how the rolling update will proceed.
```bash
kubectl set image deployment/nginx-deployment nginx=nginx:stable
kubectl rollout status deployment/nginx-deployment
```



