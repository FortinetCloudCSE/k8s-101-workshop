#!/usr/bin/env bash
set -euo pipefail
set -x

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

error_handler() {
    echo -e "\e[31mAn error occurred. Exiting...\e[0m" >&2
    tput bel || true
}
trap error_handler ERR

# Match the master script.
K8S_MINOR="${K8S_MINOR:-v1.30}"
CLUSTERDNSIP="10.96.0.10"
NODENAME="${NODENAME:-node-worker}"

local_ip="$(ip route get 8.8.8.8 | awk -F'src ' 'NR==1{split($2,a," ");print a[1]}')"

echo "Using Kubernetes repo: ${K8S_MINOR}"
echo "Worker node name: ${NODENAME}"
echo "Worker private IP: ${local_ip}"

sudo hostnamectl set-hostname "${NODENAME}"
grep -q " ${NODENAME}$" /etc/hosts || echo "${local_ip} ${NODENAME}" | sudo tee -a /etc/hosts

sudo swapoff -a || true
sudo sed -i.bak '/ swap / s/^/#/' /etc/fstab || true

sudo apt-get update -y
sudo apt-get install -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  apt-transport-https ca-certificates curl gpg jq socat conntrack iproute2

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

cat <<'CRICTL' | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
CRICTL

cat <<EOF_KUBELET | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS=--node-ip=${local_ip} --cluster-dns=${CLUSTERDNSIP}
EOF_KUBELET
sudo systemctl enable --now kubelet

# Make repeat lab runs non-interactive by cleaning any old partial join state.
sudo kubeadm reset -f || true
sudo rm -rf /etc/kubernetes /var/lib/kubelet /var/lib/cni /etc/cni/net.d
sudo mkdir -p /etc/kubernetes/manifests
sudo systemctl restart containerd
sudo systemctl restart kubelet || true

echo "installation done on worker node"
trap - ERR