#!/bin/bash -xe

username=$(whoami)
nodename=$(hostname)

error_handler() {
    echo -e "\e[31mAn error occurred. Exiting...\e[0m" >&2
    tput bel || true
    tput bel || true
}
trap error_handler ERR

# Kubernetes 101 default versions. Override before running if needed:
#   export K8S_MINOR=v1.35
#   export CALICO_VERSION=v3.31.6
K8S_MINOR="${K8S_MINOR:-v1.36}"
CALICO_VERSION="${CALICO_VERSION:-v3.32.1}"
POD_CIDR="${POD_CIDR:-10.244.0.0/16}"
SERVICE_CIDR="${SERVICE_CIDR:-10.96.0.0/12}"
CLUSTERDNSIP="10.96.0.10"
ARCH="amd64"

sudo swapoff -a || true
sudo sed -i.bak '/ swap / s/^/#/' /etc/fstab || true

sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gpg jq socat conntrack iproute2 hey

cat <<'MODULES' | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
MODULES
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<'SYSCTL' | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
SYSCTL
sudo sysctl --system

# Install and configure containerd as the Kubernetes CRI runtime.
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

# Install kubeadm/kubelet/kubectl from the current Kubernetes community repository.
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/Release.key" | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
cat <<EOF_REPO | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/ /
EOF_REPO
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Configure crictl so kubeadm/kubelet use containerd consistently.
cat <<'CRICTL' | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
CRICTL

local_ip=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
cat <<EOF_KUBELET | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS=--node-ip=${local_ip} --cluster-dns=${CLUSTERDNSIP}
EOF_KUBELET
sudo systemctl enable --now kubelet

IPADDR=$local_ip
NODENAME=$(hostname | tr -d '-')
FQDN="${fqdn:-localhost}"
grep -q " ${NODENAME}$" /etc/hosts || echo "$IPADDR $NODENAME" | sudo tee -a /etc/hosts

sudo kubeadm reset -f || true
sudo rm -rf /etc/cni/net.d/*
sudo kubeadm config images pull --cri-socket unix:///run/containerd/containerd.sock --v=5
sudo kubeadm init \
  --cri-socket=unix:///run/containerd/containerd.sock \
  --apiserver-advertise-address="$IPADDR" \
  --apiserver-cert-extra-sans="$IPADDR,$FQDN" \
  --service-cidr="$SERVICE_CIDR" \
  --pod-network-cidr="$POD_CIDR" \
  --node-name "$NODENAME" \
  --token-ttl=0 \
  -v=5

mkdir -p "/home/${username}/.kube"
sudo cp -f /etc/kubernetes/admin.conf "/home/${username}/.kube/config"
sudo chown "${username}:${username}" "/home/${username}/.kube/config"
sudo mkdir -p /root/.kube
sudo cp -f "/home/${username}/.kube/config" /root/.kube/config
kubectl --kubeconfig "/home/${username}/.kube/config" config set-cluster kubernetes --server "https://${local_ip}:6443"

kubeadm token create --print-join-command > "/home/${username}/workloadtojoin.sh"
sed -i 's/^kubeadm join/sudo kubeadm join --cri-socket unix:\/\/\/run\/containerd\/containerd.sock/g' "/home/${username}/workloadtojoin.sh"
chmod +x "/home/${username}/workloadtojoin.sh"
cat "/home/${username}/workloadtojoin.sh"

# Install Calico CNI using the Tigera operator.
cd "$HOME"
sudo curl --retry 3 --retry-connrefused -fL "https://github.com/projectcalico/calico/releases/download/${CALICO_VERSION}/calicoctl-linux-${ARCH}" -o /usr/local/bin/calicoctl
sudo chmod +x /usr/local/bin/calicoctl
curl --retry 3 --retry-connrefused -fLO "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml"
kubectl --kubeconfig "/home/${username}/.kube/config" apply -f tigera-operator.yaml
kubectl --kubeconfig "/home/${username}/.kube/config" rollout status deployment tigera-operator -n tigera-operator --timeout=180s

curl --retry 3 --retry-connrefused -fLO "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/custom-resources.yaml"
sed -i -e "s?192.168.0.0/16?${POD_CIDR}?g" custom-resources.yaml
sed -i -e "s?VXLANCrossSubnet?VXLAN?g" custom-resources.yaml
# Keep this lab simple and avoid BGP requirements between Azure VMs.
sed -i '/calicoNetwork:/a\    bgp: Disabled' custom-resources.yaml
kubectl --kubeconfig "/home/${username}/.kube/config" apply -f custom-resources.yaml

kubectl --kubeconfig "/home/${username}/.kube/config" rollout status deployment calico-kube-controllers -n calico-system --timeout=300s
kubectl --kubeconfig "/home/${username}/.kube/config" rollout status ds calico-node -n calico-system --timeout=300s
kubectl --kubeconfig "/home/${username}/.kube/config" rollout status deployment coredns -n kube-system --timeout=180s
kubectl --kubeconfig "/home/${username}/.kube/config" get nodes -o wide
kubectl --kubeconfig "/home/${username}/.kube/config" get pods -A
cat "/home/${username}/workloadtojoin.sh"

echo "installation done on master node"
trap - ERR
