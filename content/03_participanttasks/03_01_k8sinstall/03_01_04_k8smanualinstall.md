---
title: "Kubernetes Step by Step Install "
linkTitle: "Optional-Task Manual Installation"
weight: 5
---

### Step by Step approach for install master node

{{% notice warning %}}
This is only for experienced users who want to explore the details of using kubeadm to install a Kubernetes cluster.
{{% /notice %}}

The automated scripts for this workshop are:

```bash
scripts/install_kubeadm_masternode.sh
scripts/install_kubeadm_workernode.sh
scripts/deploy_application_with_hpa_masternode.sh
```

This manual page explains the same flow step by step using the updated installation approach:

- containerd as the container runtime
- kubeadm, kubelet, and kubectl from `pkgs.k8s.io`
- Calico CNI
- one master/control-plane VM and one worker VM


{{< notice info >}}
For FortiAIGate 8.0.1 lab readiness, this workshop pins Kubernetes to `v1.30`, which is above the FortiAIGate minimum of Kubernetes 1.25.0. The full FortiAIGate deployment still needs ingress, Helm, and storage prerequisites validated before installing FortiAIGate.
{{< /notice >}}

Default versions:

```bash
K8S_MINOR=v1.30
CALICO_VERSION=v3.28.2
POD_CIDR=10.244.0.0/16
SERVICE_CIDR=10.96.0.0/12
```

### Create SSH helper aliases from Azure Cloud Shell

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
    export FQDN=${nodename}
    ssh -o "StrictHostKeyChecking=no" -t $username@$nodename "export FQDN=${FQDN}; exec bash"
}
alias ssh_master="ssh_master_function"

alias k='kubectl'
EOF_ALIAS
source $HOME/.bashrc
```

### Generate SSH key for master and worker node

Clean existing kubeconfig:

```bash
rm -f ~/.kube/config
```

Clean known hosts:

```bash
rm -f /home/$(whoami)/.ssh/known_hosts
```

Get the VM password:

```bash
cd $HOME/k8s-101-workshop/terraform/
vmpassword=$(terraform output -json | jq -r .linuxvm_password.value)
echo $vmpassword
```

Generate SSH key:

```bash
[ ! -f ~/.ssh/id_rsa ] && ssh-keygen -q -N "" -f ~/.ssh/id_rsa
```

Copy SSH key to master node:

```bash
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
ssh-copy-id -f -o 'StrictHostKeyChecking=no' $username@$nodename
```

Copy SSH key to worker node:

```bash
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_worker_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)
ssh-copy-id -f -o 'StrictHostKeyChecking=no' $username@$nodename
```

### Connect to the master node

All of the following sections through **Install Calico CNI** run **on the master VM**, not in Azure Cloud Shell. Cloud Shell has no systemd, so `sudo`, `systemctl`, and `crictl` will fail there with `System has not been booted with systemd as init system`.

Open a shell on the master node using the alias defined earlier:

```bash
ssh_master
```

Your prompt should change to the VM's user (for example `azureuser@node-master`). Confirm you are on the node and that `FQDN` came across with you:

```bash
hostname
echo "$FQDN"
```

`ssh_master` exports `FQDN` onto the node automatically — the **Initialize the master node** step below needs it for the API server certificate.

### Connect to the worker node

The **Manual node preparation**, **Install containerd**, **Install kubeadm, kubelet, and kubectl**, and **Configure kubelet node IP** sections must also run on the worker VM. Open a **second Azure Cloud Shell tab** so you can keep the master session open, and connect:

```bash
ssh_worker
```

{{% notice note %}}
You should be running this workshop from **Azure Cloud Shell**. To get a second, independent session, duplicate your Azure portal browser tab (right-click the tab → **Duplicate**, or open [portal.azure.com](https://portal.azure.com) in a new tab) and open Cloud Shell there. This keeps your master-node session live in the first tab while you prepare the worker node in the second.
{{% /notice %}}

Run those four sections on the worker, then stop — the worker does **not** run `kubeadm init` or Calico. It only joins the cluster later, in **Join the worker node**.

{{% notice tip %}}
If the `ssh_master` / `ssh_worker` aliases aren't available, connect directly from the `terraform/` directory:

```bash
cd $HOME/k8s-101-workshop/terraform/
username=$(terraform output -json | jq -r .linuxvm_username.value)
master=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
# master node (note: pass FQDN through for kubeadm init)
ssh -o 'StrictHostKeyChecking=no' -t $username@$master "export FQDN=${master}; exec bash"
```
{{% /notice %}}

### Manual node preparation

Run the following on both master and worker nodes.

Disable swap:

```bash
sudo swapoff -a
sudo sed -i.bak '/ swap / s/^/#/' /etc/fstab
```

Install required packages:

```bash
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gpg jq socat conntrack iproute2
```

Load kernel modules:

```bash
cat <<'MODULES' | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
MODULES
sudo modprobe overlay
sudo modprobe br_netfilter
```

Configure sysctl:

```bash
cat <<'SYSCTL' | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
SYSCTL
sudo sysctl --system
```

### Install containerd

Run on both master and worker nodes.

```bash
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl daemon-reload
sudo systemctl enable containerd
sudo systemctl restart containerd
sudo systemctl is-active --quiet containerd
```

Create crictl configuration:

```bash
cat <<'CRICTL' | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
CRICTL
```

Verify containerd. Use `ctr`, which ships with containerd — `crictl` is not
installed yet (it arrives with `kubeadm` in the next section):

```bash
systemctl status containerd --no-pager
sudo ctr version
```

### Install kubeadm, kubelet, and kubectl

Run on both master and worker nodes.

```bash
K8S_MINOR="${K8S_MINOR:-v1.30}"

sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/Release.key" | sudo gpg --dearmor --batch --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

cat <<EOF_REPO | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/ /
EOF_REPO
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet
```

Now that `kubeadm` has pulled in `cri-tools`, `crictl` is available. Verify it can
talk to containerd through the CRI socket (using the `/etc/crictl.yaml` created earlier):

```bash
sudo crictl info
```

### Configure kubelet node IP

Run on both master and worker nodes.

```bash
local_ip=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
cat <<EOF_KUBELET | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS=--node-ip=${local_ip} --cluster-dns=10.96.0.10
EOF_KUBELET
sudo systemctl restart kubelet
```

### Initialize the master node

Run only on the master node.

```bash
POD_CIDR="10.244.0.0/16"
SERVICE_CIDR="10.96.0.0/12"
local_ip=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
NODENAME="node-master"
# FQDN must be the Azure public DNS name for this student's master VM.
# Support lowercase fqdn for backward compatibility, but prefer uppercase FQDN.
FQDN="${FQDN:-${fqdn:-}}"
: "${FQDN:?ERROR: FQDN is required. Example: export FQDN=<student>-master.<region>.cloudapp.azure.com}"

sudo kubeadm reset -f \
  --cri-socket=unix:///run/containerd/containerd.sock || true
sudo rm -rf \
  /etc/kubernetes \
  /etc/cni/net.d \
  /var/lib/cni \
  /var/lib/kubelet \
  /var/lib/etcd
rm -rf "$HOME/.kube"
sudo systemctl restart containerd
sudo systemctl restart kubelet || true
sudo kubeadm config images pull --cri-socket unix:///run/containerd/containerd.sock
sudo kubeadm init \
  --cri-socket=unix:///run/containerd/containerd.sock \
  --apiserver-advertise-address="$local_ip" \
  --apiserver-cert-extra-sans="$local_ip,$FQDN" \
  --service-cidr="$SERVICE_CIDR" \
  --pod-network-cidr="$POD_CIDR" \
  --node-name "$NODENAME" \
  --token-ttl=0
```

Configure kubectl on the master node:

```bash
mkdir -p $HOME/.kube
sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl --kubeconfig "$HOME/.kube/config" config set-cluster kubernetes --server "https://${FQDN}:6443"
```

Create the worker join command:

```bash
kubeadm token create --print-join-command > ~/workloadtojoin.sh
sed -i 's/^kubeadm join/sudo kubeadm join --cri-socket unix:\/\/\/run\/containerd\/containerd.sock/g' ~/workloadtojoin.sh
chmod +x ~/workloadtojoin.sh
cat ~/workloadtojoin.sh
```

### Install Calico CNI

Run only on the master node.

```bash
CALICO_VERSION="${CALICO_VERSION:-v3.28.2}"
POD_CIDR="10.244.0.0/16"

curl -fLO "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml"
# Use server-side apply: the Calico operator CRDs are too large for client-side
# apply, which fails with "metadata.annotations: Too long" and silently skips them.
kubectl apply --server-side --force-conflicts -f tigera-operator.yaml
kubectl rollout status deployment tigera-operator -n tigera-operator --timeout=180s

curl -fLO "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/custom-resources.yaml"
sed -i -e "s?192.168.0.0/16?${POD_CIDR}?g" custom-resources.yaml
sed -i -e "s?VXLANCrossSubnet?VXLAN?g" custom-resources.yaml
sed -i '/calicoNetwork:/a\    bgp: Disabled' custom-resources.yaml
kubectl apply -f custom-resources.yaml

# The operator creates the calico-system namespace asynchronously. Poll for at
# most five minutes; Kubernetes 1.30's kubectl does not support --for=create.
calico_namespace_ready=false
for attempt in $(seq 1 60); do
  if kubectl get namespace calico-system >/dev/null 2>&1; then
    calico_namespace_ready=true
    break
  fi

  echo "Waiting for calico-system namespace... attempt ${attempt}/60"
  sleep 5
done

if [ "$calico_namespace_ready" != true ]; then

  echo "ERROR: Calico did not create the calico-system namespace."
  kubectl get pods -n tigera-operator -o wide
  kubectl logs -n tigera-operator deployment/tigera-operator --tail=200
  kubectl describe installation default
  echo "Stop here and resolve the Calico operator error before continuing."
else
  kubectl rollout status \
    deployment/calico-kube-controllers \
    -n calico-system \
    --timeout=600s

  kubectl rollout status \
    daemonset/calico-node \
    -n calico-system \
    --timeout=600s

  kubectl rollout status \
    deployment/coredns \
    -n kube-system \
    --timeout=300s
fi
```

### Join the worker node

Copy `workloadtojoin.sh` from master to worker and run it on the worker node.

From Azure Cloud Shell:

```bash
cd $HOME/k8s-101-workshop/terraform/
master=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
worker=$(terraform output -json | jq -r .linuxvm_worker_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)

ssh -o 'StrictHostKeyChecking=no' $username@$master \
"kubeadm token create --print-join-command | sed 's#^kubeadm join#sudo kubeadm join --cri-socket unix:///run/containerd/containerd.sock#' > ~/workloadtojoin.sh && chmod +x ~/workloadtojoin.sh && cat ~/workloadtojoin.sh"

scp -o 'StrictHostKeyChecking=no' $username@$master:~/workloadtojoin.sh ./workloadtojoin.sh
scp -o 'StrictHostKeyChecking=no' ./workloadtojoin.sh $username@$worker:~/workloadtojoin.sh

# Reset any prior Kubernetes state on the worker before joining. Without this,
# a re-run can fail preflight or retain stale kubelet and CNI state.
ssh -o 'StrictHostKeyChecking=no' "$username@$worker" 'bash -s' <<'REMOTE'
set -e
sudo kubeadm reset -f \
  --cri-socket=unix:///run/containerd/containerd.sock || true
sudo rm -rf \
  /etc/kubernetes \
  /etc/cni/net.d \
  /var/lib/cni \
  /var/lib/kubelet
sudo mkdir -p /etc/kubernetes/manifests
sudo systemctl restart containerd
sudo systemctl restart kubelet || true
REMOTE

ssh -o 'StrictHostKeyChecking=no' -t "$username@$worker" "sudo bash ~/workloadtojoin.sh"
```

{{% notice note %}}
If you are on the worker node directly (via `ssh_worker`) instead of driving it from Cloud Shell, you still need a fresh join command from the master. The worker cannot create its own bootstrap token, and `~/workloadtojoin.sh` exists only on the master unless it was copied previously.

In the master-node session, generate a fresh command:

```bash
kubeadm token create --print-join-command | \
  sed 's#^kubeadm join#sudo kubeadm join --cri-socket unix:///run/containerd/containerd.sock#'
```

Copy the complete command that this prints. Then, in the worker-node session, reset the old Kubernetes state:

```bash
sudo kubeadm reset -f \
  --cri-socket=unix:///run/containerd/containerd.sock || true
sudo rm -rf \
  /etc/kubernetes \
  /etc/cni/net.d \
  /var/lib/cni \
  /var/lib/kubelet
sudo mkdir -p /etc/kubernetes/manifests
sudo systemctl restart containerd
sudo systemctl restart kubelet || true
```

Finally, paste and run the fresh `sudo kubeadm join ...` command from the master. Do not run an old `~/workloadtojoin.sh`; its token may be missing or expired.
{{% /notice %}}

### Copy kubeconfig to Azure Cloud Shell

```bash
cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)

rm -rf $HOME/.kube/
mkdir -p ~/.kube/
scp -o 'StrictHostKeyChecking=no' $username@$nodename:~/.kube/config $HOME/.kube/config
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'; echo
```

### Verify

```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl cluster-info
```

Expected result:

```bash
NAME          STATUS   ROLES           VERSION
node-worker   Ready    <none>          v1.30.x
node-master   Ready    control-plane   v1.30.x
```
