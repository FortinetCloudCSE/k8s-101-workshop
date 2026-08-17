---
title: "Task 2 - Deploy and Scalling Application"
linkTitle: "Task 2 - Scaling Application"
weight: 2
---

## Objective

This task deploys an nginx application and demonstrates basic Kubernetes scaling with HPA.

The updated script keeps the original workshop flow but updates the supporting components:

- Local Path Provisioner for simple lab storage
- Metrics Server for HPA CPU metrics
- MetalLB for LoadBalancer testing
- Kong Ingress Controller for ingress testing
- cert-manager for a self-signed test certificate
- nginx deployment and HPA

## Deploy the application and HPA demo

Run this from Azure Cloud Shell:

```bash
cd $HOME/k8s-101-workshop/terraform/
master=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
username=$(terraform output -json | jq -r .linuxvm_username.value)

scp -o 'StrictHostKeyChecking=no' $HOME/k8s-101-workshop/scripts/deploy_application_with_hpa_masternode.sh $username@$master:~/deploy_application_with_hpa_masternode.sh
ssh -o 'StrictHostKeyChecking=no' -t $username@$master "export FQDN=${master}; bash ~/deploy_application_with_hpa_masternode.sh"
```

## Verify resources

```bash
kubectl get nodes
kubectl get pods -A
kubectl get deployment nginx-deployment
kubectl get hpa
kubectl get ingress
kubectl get svc -A
```

Expected nginx deployment:

```bash
NAME               READY   UP-TO-DATE   AVAILABLE
nginx-deployment   2/2     2            2
```

Expected HPA object:

```bash
NAME        REFERENCE                     TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   Deployment/nginx-deployment   <unknown>/50%   2         10        2          34s
```

After Metrics Server starts collecting CPU metrics, the HPA target changes from `<unknown>` to a CPU percentage.


## FortiAIGate readiness checks

After this task completes, run these checks before starting a FortiAIGate deployment:

{{< tabs >}}
{{% tab title="1.Cluster-info" %}}
```bash
kubectl cluster-info
```
{{% /tab %}}
{{% tab title="1.Expected Output" style="info" %}}
Expected output
```
Kubernetes control plane is running at https://k8sXX-master.eastus.cloudapp.azure.com:6443
CoreDNS is running at https://k8sXX-master.eastus.cloudapp.azure.com:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```
{{% /tab %}}
{{% tab title="2.Check Nodes" %}}
```bash
kubectl get nodes -o wide
```
{{% /tab %}}
{{% tab title="2.Expected Output" style="info" %}}
```
NAME          STATUS   ROLES           AGE   VERSION
node-master   Ready    control-plane   53m   v1.30.14
node-worker   Ready    <none>          50m   v1.30.14
```
{{% /tab %}}
{{% tab title="3.Check Pods" %}}
```bash
kubectl get pods -A
```
{{% /tab %}}
{{% tab title="3.Expected Output" style="info" %}}
```
NAMESPACE            NAME                                       READY   STATUS    RESTARTS   AGE
calico-apiserver     calico-apiserver-66f4fd9b6d-9fcwp          1/1     Running   0          53m
calico-apiserver     calico-apiserver-66f4fd9b6d-xnb9q          1/1     Running   0          53m
calico-system        calico-kube-controllers-7677dd5467-9d2cj   1/1     Running   0          53m
calico-system        calico-node-lgddt                          1/1     Running   0          53m
calico-system        calico-node-rj584                          1/1     Running   0          51m
calico-system        calico-typha-6f4bcd7686-8lpqc              1/1     Running   0          53m
calico-system        csi-node-driver-bzl2x                      2/2     Running   0          51m
calico-system        csi-node-driver-g6k5j                      2/2     Running   0          53m
cert-manager         cert-manager-5b98df59d6-fld8m              1/1     Running   0          48m
cert-manager         cert-manager-cainjector-f48cd678-8gsrt     1/1     Running   0          48m
cert-manager         cert-manager-webhook-76cdf6c497-bzn54      1/1     Running   0          48m
default              nginx-deployment-d68499895-d4kn6           1/1     Running   0          48m
default              nginx-deployment-d68499895-tzl8x           1/1     Running   0          48m
kube-system          coredns-55cb58b774-qddlw                   1/1     Running   0          53m
kube-system          coredns-55cb58b774-zkf9k                   1/1     Running   0          53m
kube-system          etcd-node-master                           1/1     Running   0          54m
kube-system          kube-apiserver-node-master                 1/1     Running   0          54m
kube-system          kube-controller-manager-node-master        1/1     Running   0          54m
kube-system          kube-proxy-nncmh                           1/1     Running   0          51m
kube-system          kube-proxy-sg5nk                           1/1     Running   0          53m
kube-system          kube-scheduler-node-master                 1/1     Running   0          54m
kube-system          metrics-server-75778854d4-c2l97            1/1     Running   0          49m
local-path-storage   local-path-provisioner-7dd969c95d-sfkpk    1/1     Running   0          49m
metallb-system       controller-589cbf5c44-h96m8                1/1     Running   0          49m
metallb-system       speaker-glbw9                              1/1     Running   0          49m
metallb-system       speaker-nl9fc                              1/1     Running   0          49m
tigera-operator      tigera-operator-576646c5b6-6twqm           1/1     Running   0          53m
```
{{% /tab %}}
{{% tab title="4.helm version" %}}
```bash
helm version
```
{{% /tab %}}
{{% tab title="4.Expected Output" style="info" %}}
Expected output
```
version.BuildInfo{Version:"v4.1", GitCommit:"c94d381b03be117e7e57908edbf642104e00eb8f", GitTreeState:"clean", GoVersion:"go1.26.4", KubeClientVersion:"v1.35"}
```
{{% /tab %}}
{{% tab title="5.Ingressclass" %}}
```bash
kubectl get ingressclass
```
{{% /tab %}}
{{% tab title="5.Expected Output" style="info" %}}
Expected output
```
No resources found
```
{{% /tab %}}
{{% tab title="6.Storage Class" %}}
```bash
kubectl get storageclass
```
{{% /tab %}}
{{% tab title="6.Expected Output" style="info" %}}
Expected output
```
NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  52m
```
{{% /tab %}}
{{< /tabs >}}

## Generate load

Run a temporary load generator from the cluster:

```bash
kubectl run -i --tty load-generator --rm --image=busybox:1.36 --restart=Never -- /bin/sh
```

Inside the shell, run:

```bash
while true; do wget -q -O- http://nginx-deployment.default.svc.cluster.local; done
```

In another terminal, watch HPA:

```bash
watch kubectl get hpa
```

You can also watch pods scale:

```bash
watch kubectl get pods -l app=nginx
```

## Stop load

Press `CTRL+C` in the load generator shell, then type:

```bash
exit
```

## Cleanup

{{< tabs >}}
{{% tab title="Cleanup Application" %}}

```bash
kubectl delete hpa nginx-hpa --ignore-not-found
kubectl delete ingress nginx --ignore-not-found
kubectl delete deployment nginx-deployment --ignore-not-found
kubectl delete service nginx-deployment --ignore-not-found
kubectl delete pod load-generator --ignore-not-found
```
{{% /tab %}}
{{% tab title="Cleanup Addons" %}}

```bash
kubectl delete -f https://raw.githubusercontent.com/Kong/kubernetes-ingress-controller/v3.5.0/deploy/single/all-in-one-dbless.yaml --ignore-not-found
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.2/cert-manager.yaml --ignore-not-found
kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml --ignore-not-found
kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml --ignore-not-found
kubectl delete -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.31/deploy/local-path-storage.yaml --ignore-not-found
```
{{% /tab %}}
{{< /tabs >}}

### Summary

This chapter demonstrates deploying an application, exposing it through Kubernetes objects, installing Metrics Server, and using HPA to scale pods based on CPU utilization.

### Review Questions

1. Describe how to make the client application generate more traffic.
{{% expand title="Click for Answer..." %}}
Run a load generator pod and continuously call the nginx service.
{{% /expand %}}

2. How many minutes do you need to wait before nginx pods start increasing?
{{% expand title="Click for Answer..." %}}
It depends on when Metrics Server reports CPU data and when HPA decides to scale. Wait a few minutes and monitor with `kubectl get hpa`.
{{% /expand %}}

3. How do you stop sending traffic to nginx deployment?
{{% expand title="Click for Answer..." %}}
Stop or delete the load generator pod.
{{% /expand %}}
