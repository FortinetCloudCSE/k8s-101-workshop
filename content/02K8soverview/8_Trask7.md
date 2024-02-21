---
title: "Task 7 - Stateful Application "
menuTitle: "Stateful Application"
chapter: false
weight: 5
---

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

