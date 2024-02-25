---
title: "Chapter2 - Review"
menuTitle: "Chapter2 - Review"
weight: 4
---


### Challenge

1. Use `kubectl run` to create a POD with juiceshop image and add a label owner=dev 

2. Use `kubectl create deployment` to create a deployment for juiceshop

3. Use create a yaml file for juiceshop deployment and use `kubectl create -f` to create the deployment 

4. Use `kubectl` to find the specifcation for imagePullPolicy which is need for create a POD. 

5. which kubectl cli and answer what is the imagePullPolicy avaiable to choose. 

Answer: 

```bash
kubectl explain Pod.spec.containers.imagePullPolicy
```
Answer 
```bash
Always, Never, IfNotPresent
```

6. use curl to get namespace 

Try to use curl command instead `kubectl` to get namespace for cluster. you have to give client key and certificate to authenticate to kube-API server.

Answer

```bash
sudo snap install yq
cat ~/.kube/config | yq .users[0].user.client-certificate-data | base64 -d > k8sadmin.crt
cat ~/.kube/config | yq .users[0].user.client-key-data | base64 -d > k8sadmin.key

SERVER="10.0.0.4"
curl --key k8sadmin.key --cert k8sadmin.crt https://$SERVER:6443/api/v1/pods --insecure -s -w "\n" |
  jq -r '.items[] | "\(.metadata.namespace)\t\(.metadata.name)\t\(.status.containerStatuses[0].ready)\t\(.status.phase)\t\(.status.containerStatuses[0].restartCount)\t\(.spec.containers|length)"' |
  column -t -s $'\t'

```

