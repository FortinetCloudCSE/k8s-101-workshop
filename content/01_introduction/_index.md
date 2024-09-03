---
title: "Kubernetes TECWorkshop"
linkTitle: "Introduction"
weight: 1
archetype: home
---

### Welcome to K8s 101 workshop

## About Kubernetes

**Kubernetes** is an open-source container orchestration platform that automates the deployment, scaling, and management of containerized applications. Originally developed by Google and now maintained by the Cloud Native Computing Foundation (CNCF), Kubernetes has become the de facto standard for managing containerized workloads in production environments. **K8s** is short name of Kubernetes. 

![](https://wac-cdn.atlassian.com/dam/jcr:8a8c5eff-cedd-4e46-a397-9d635a098afc/Kubernetes-vs-Docker-article_2@2x.jpg?cdnVersion=1456)

## Workshop Objectives

In this workshop, you will:

- Understand why containers are important, and how they fit into a microservices architecture orchestrated by K8s
- Build a Kubernetes cluster on a Virtual Machine (VM)in Azure.
- Gain a fundamental understanding of Kubernetes concepts.
- Learn how to deploy, manage, and scale applications using Kubernetes.
- Explore key Kubernetes resources such as Pods, Deployments, Services, and more.
- Gain hands-on experience with practical examples.



## Building a K8s cluster from scratch vs using Managed Services like AKS,EKS,GKE?

- Building a self-managed cluster instead of relying on managed services for learning Kubernetes offers beginners hands-on experience, deeper understanding of core concepts, and greater control over configurations. 

- Building a cluster offers deeper understanding of core Kubernetes components such as pods, nodes, and controllers.

- In production environments, many organizations use managed Kubernetes services provided by major cloud providers. 

- These services—Amazon Elastic Kubernetes Service (EKS), Azure Kubernetes Service (AKS), and Google Kubernetes Engine (GKE)—are managed Kubernetes offerings from AWS, Azure, and Google Cloud. They provide features such as automated updates, scaling, monitoring, and seamless integration with other cloud services.

- However, the choice often depends on factors such as existing cloud provider relationships, specific feature requirements, pricing, and the level of control and customization desired by the organization.

In this workshop, we begin with **Azure Managed Kubernetes (AKS)** for an easy start, followed by a deep dive into **self-managed Kubernetes with kubeadm**, covering the installation of every component.

## Formatting Conventions
- Yellow Highlighted Text: 
Indicates that is a command lines you can execute on shell.
- Black Box: 
Contains bash commands intended for you to copy and paste directly into your terminal for your task.
- Grey Box: 
Displays the output from executed commands. The text above each box explains the command's purpose and intent.

Unless explicitly stated otherwise, all CLI commands should be executed directly in the **Azure Cloud Shell**.
