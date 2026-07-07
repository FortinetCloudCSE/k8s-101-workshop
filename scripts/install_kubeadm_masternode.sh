#!/usr/bin/env bash
set -euo pipefail
set -x

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

username="$(id -un)"

error_handler() {
    echo -e "\e[31mAn error occurred. Exiting...\e[0m" >&2
    tput bel || true
    tput bel || true
}
trap error_handler ERR

# FortiAIGate 8.0.1 requires Kubernetes 1.25.0 or later.
# Pin to a stable Kubernetes minor for repeatable workshop labs.
# Override only if required: export K8S_MINOR=v1.31
K8S_MINOR="${K8S_MINOR:-v1.30}"
CALICO_VERSION="${CALICO_VERSION:-v3.28.2}"
POD_CIDR="${POD_CIDR:-10.244.0.0/16}"
SERVICE_CIDR="${SERVICE_CIDR:-10.96.0.0/12}"
CLUSTERDNSIP="10.96.0.10"
NODENAME="${NODENAME:-node-master}"
ARCH="amd64"

# FQDN must be the Azure public DNS name for this student's master VM.
# Support lowercase fqdn for backward compatibility, but prefer uppercase FQDN.
FQDN="${FQDN:-${fqdn:-}}"
: "${FQDN:?ERROR: FQDN is required. Example: export FQDN=<student>-master.<region>.cloudapp.azure.com}"

IPADDR="$(ip route get 8.8.8.8 | awk -F'src ' 'NR==1{split($2,a," ");print a[1]}')"

echo "Using Kubernetes repo: ${K8S_MINOR}"
echo "Using Calico version: ${CALICO_VERSION}"
echo "Master node name: ${NODENAME}"
echo "Master private IP: ${IPADDR}"
echo "Master FQDN: ${FQDN}"

sudo hostnamectl set-hostname "${NODENAME}"
grep -q " ${NODENAME}$" /etc/hosts || echo "${IPADDR} ${NODENAME}" | sudo tee -a /etc/hosts

sudo swapoff -a || true
sudo sed -i.bak '/ swap / s/^/#/' /etc/fstab || true

sudo apt-get update -y
sudo apt-get install -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  apt-transport-https ca-certificates curl gpg jq socat conntrack iproute2 hey

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
sudo apt-get install -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl daemon-reload
sudo systemctl enable --now containerd
sudo systemctl restart containerd

# Install kubeadm/kubelet/kubectl from the Kubernetes community repository.
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/Release.key" \
  | sudo gpg --dearmor --batch --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
cat <<EOF_REPO | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/ /
EOF_REPO
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -y
sudo apt-get install -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Configure crictl so kubeadm/kubelet use containerd consistently.
cat <<'CRICTL' | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
CRICTL

cat <<EOF_KUBELET | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS=--node-ip=${IPADDR} --cluster-dns=${CLUSTERDNSIP}
EOF_KUBELET
sudo systemctl enable --now kubelet

sudo kubeadm reset -f || true
sudo rm -rf /etc/cni/net.d/* /etc/kubernetes /var/lib/etcd
rm -rf "$HOME/.kube"

sudo kubeadm config images pull --cri-socket unix:///run/containerd/containerd.sock --v=5
sudo kubeadm init \
  --cri-socket=unix:///run/containerd/containerd.sock \
  --apiserver-advertise-address="${IPADDR}" \
  --apiserver-cert-extra-sans="${IPADDR},${FQDN},localhost,${NODENAME}" \
  --service-cidr="${SERVICE_CIDR}" \
  --pod-network-cidr="${POD_CIDR}" \
  --node-name="${NODENAME}" \
  --token-ttl=0 \
  -v=5

mkdir -p "/home/${username}/.kube"
sudo cp -f /etc/kubernetes/admin.conf "/home/${username}/.kube/config"
sudo chown "${username}:${username}" "/home/${username}/.kube/config"
sudo mkdir -p /root/.kube
sudo cp -f "/home/${username}/.kube/config" /root/.kube/config

# Use the master FQDN in kubeconfig so the same config works from Azure Cloud Shell.
kubectl --kubeconfig "/home/${username}/.kube/config" config set-cluster kubernetes --server "https://${FQDN}:6443"

# Generate worker join script with sudo and explicit containerd CRI socket.
kubeadm token create --print-join-command > "/home/${username}/workloadtojoin.sh"
sed -i 's/^kubeadm join/sudo kubeadm join --cri-socket unix:\/\/\/run\/containerd\/containerd.sock/g' "/home/${username}/workloadtojoin.sh"
chmod +x "/home/${username}/workloadtojoin.sh"
cat "/home/${username}/workloadtojoin.sh"

# Install Calico CNI using the Tigera operator.
cd "$HOME"
sudo curl --retry 3 --retry-connrefused -fL "https://github.com/projectcalico/calico/releases/download/${CALICO_VERSION}/calicoctl-linux-${ARCH}" -o /usr/local/bin/calicoctl
sudo chmod +x /usr/local/bin/calicoctl
curl --retry 3 --retry-connrefused -fLO "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml"
kubectl --kubeconfig "/home/${username}/.kube/config" apply --server-side -f tigera-operator.yaml
kubectl --kubeconfig "/home/${username}/.kube/config" rollout status deployment tigera-operator -n tigera-operator --timeout=180s

curl --retry 3 --retry-connrefused -fLO "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/custom-resources.yaml"
sed -i -e "s?192.168.0.0/16?${POD_CIDR}?g" custom-resources.yaml
sed -i -e "s?VXLANCrossSubnet?VXLAN?g" custom-resources.yaml
# Keep this lab simple and avoid BGP requirements between Azure VMs.
sed -i '/calicoNetwork:/a\    bgp: Disabled' custom-resources.yaml
kubectl --kubeconfig "/home/${username}/.kube/config" apply --server-side -f custom-resources.yaml

kubectl --kubeconfig "/home/${username}/.kube/config" rollout status deployment calico-kube-controllers -n calico-system --timeout=300s
kubectl --kubeconfig "/home/${username}/.kube/config" rollout status ds calico-node -n calico-system --timeout=300s
kubectl --kubeconfig "/home/${username}/.kube/config" rollout status deployment coredns -n kube-system --timeout=180s

# Helm is needed by FortiAIGate deployment workflows.
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

kubectl --kubeconfig "/home/${username}/.kube/config" get nodes -o wide
kubectl --kubeconfig "/home/${username}/.kube/config" get pods -A

echo "API server certificate SANs:"
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -text | grep -A2 "Subject Alternative Name" || true

cat "/home/${username}/workloadtojoin.sh"
echo "installation done on master node"
trap - ERR
