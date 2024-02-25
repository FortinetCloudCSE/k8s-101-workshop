---
title: "K8S install"
chapter: false
menuTitle: "K8S install"
weight: 2
---

## Objective: 

Pick the most appropriate Kubernetes runtime to install also show you how easy to use kubernetes to scale your application.

## Choose your kubernetes 
Although Cloud-Managed Kubernetes becoming the popular choice for enteprise production environments, self-managed Kubernetes gives users full control over their Kubernetes environments. Choosing the proper self-install method  can vary significantly based on the intended use case, from development and testing environments to production deployments. Here's a short description of different options to install Kubernetes, tailored to specific needs:

### Development and Testing

- Minikube:
Best For: Individual developers and small teams experimenting with Kubernetes applications or learning the Kubernetes ecosystem.

- Kind (Kubernetes in Docker):
Best For: Kubernetes contributors, developers working on CI/CD pipelines, and testing Kubernetes configurations.

- OrbStack Kubernetes:
Best for: development and testing on **MacOS desktop with Apple Silicon or intel chipset** , it eliminates the complexity of setting up and managing full-fledged Kubernetes clusters.


### Production Deployment

- Kubeadm:
Best For: Organizations looking for a customizable production-grade Kubernetes setup that adheres to best practices. Suitable for those with specific infrastructure requirements and those who wish to integrate Kubernetes into existing systems with specific configurations.

- Kubespray:
Best For: Users seeking to deploy Kubernetes on a variety of infrastructure types (cloud, on-premises, bare-metal) and require a tool that supports extensive customization and scalability.

- Rancher:
Best For: Organizations looking for an enterprise Kubernetes management platform that simplifies the operation of Kubernetes across any infrastructure, offering UI and API-based management.
