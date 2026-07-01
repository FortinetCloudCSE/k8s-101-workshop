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
NAME        REFERENCE                     TARGETS        MINPODS   MAXPODS
nginx-hpa   Deployment/nginx-deployment   <unknown>/50%   2         10
```

After Metrics Server starts collecting CPU metrics, the HPA target changes from `<unknown>` to a CPU percentage.


## FortiAIGate readiness checks

After this task completes, run these checks before starting a FortiAIGate deployment:

```bash
kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods -A
helm version
kubectl get ingressclass
kubectl get storageclass
```

For FortiAIGate, confirm that the cluster has a working CNI, Helm, ingress, and a storage design appropriate for the deployment.

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
