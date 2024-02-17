---
title: "Task 3 - Rolling Update"
menuTitle: "Rolling Update"
chapter: false
weight: 3
---

### Performing a Rolling Update 
Objectives
Perform a rolling update using kubectl.
Updating an application
Users expect applications to be available all the time, and developers are expected to deploy new versions of them several times a day. In Kubernetes this is done with rolling updates. A rolling update allows a Deployment update to take place with zero downtime. It does this by incrementally replacing the current Pods with new ones. The new Pods are scheduled on Nodes with available resources, and Kubernetes waits for those new Pods to start before removing the old Pods.

In the previous module we scaled our application to run multiple instances. This is a requirement for performing updates without affecting application availability. By default, the maximum number of Pods that can be unavailable during the update and the maximum number of new Pods that can be created, is one. Both options can be configured to either numbers or percentages (of Pods). In Kubernetes, updates are versioned and any Deployment update can be reverted to a previous (stable) version.

Rolling updates overview

![Alt text for the image](https://kubernetes.io/docs/tutorials/kubernetes-basics/public/images/module_06_rollingupdates3.svg)


Similar to application Scaling, if a Deployment is exposed publicly, the Service will load-balance the traffic only to available Pods during the update. An available Pod is an instance that is available to the users of the application.

Rolling updates allow the following actions:

Promote an application from one environment to another (via container image updates)
Rollback to previous versions
Continuous Integration and Continuous Delivery of applications with zero downtime
If a Deployment is exposed publicly, the Service will load-balance the traffic only to available Pods during the update.


In the following interactive tutorial, we'll update our application to a new version, and also perform a rollback.

How to Perform:
```bash

kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=jocatalin/kubernetes-bootcamp:v2
kubectl rollout status deployment/kubernetes-bootcamp
```
you will see

```bash
ubuntu@ubuntu22:~$ kubectl rollout status deployment/kubernetes-bootcamp
Waiting for deployment "kubernetes-bootcamp" rollout to finish: 5 out of 10 new replicas have been updated...
deployment "kubernetes-bootcamp" successfully rolled out

```
to rollback to old version just 
```bash
kubectl set image deployments/kubernetes-bootcamp kubernetes-bootcamp=gcr.io/google-samples/kubernetes-bootcamp:v1 
kubectl rollout status deployment/kubernetes-bootcamp
```

### Adjust the Site's [Frontmatter](https://gohugo.io/content-management/front-matter/) in config.toml file 
{{% notice note %}} Config.toml must be modified for each new repo as it controls overall parameters for the site {{% /notice %}}
1. Open the **config.toml** file under the repo root to change a few parameters of the site
   - Edit the **baseUrl** parameter to match the GitHub Page for your site (**it will match your TECWorkshop reop name**)
   - Edit the **themeVariant** parameter depending on the type of TEC Content you're using
   
{{% notice info %}}  Currently available themeVariants are:
- Workshop
- Demo
- UseCase
- Spotlight
{{% /notice %}}
      
   - Optionally Edit the **logoBannerText** parameter, if you want to override the themeVariant Text under Fortinet Logo
   - Optionally Edit the **logoBannerSubText** parameter, if you want to add description under Banner Text
   - Add additional resource URL's to the bottom of the left menu bar with **[[menu.shortcuts]]**
     - menu.shortcuts are displayed lowest to highest according to their weight
   - Additional customizations can be made with **themeVariants**, so email [fortinetcloudcse@fortinet.com](mailto:fortinetcloudcse@fortinet.com) to request global site changes
  ![config](config.png)
