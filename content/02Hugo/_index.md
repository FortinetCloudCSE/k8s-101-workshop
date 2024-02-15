---
title: "Ch 2 Kubernetes Overview"
chapter: false
menuTitle: "Ch 2: Kubernetes Overview"
weight: 20
---
### *** What is Kubernetes, and Why Kubernetes

Kubernetes is a powerful platform designed to automate deploying, scaling, and operating application containers, making it an excellent choice for managing microservices-based applications that need to scale from a few users to millions of internet users while ensuring high availability. Here's how Kubernetes addresses these specific requirements:

Scaling from Few Users to Millions
Horizontal Pod Autoscaling (HPA): Kubernetes can automatically adjust the number of running instances (pods) of your microservices based on the actual demand observed. As the number of users grows, HPA increases the number of pods to maintain performance and reduce latency. Conversely, it reduces the number of pods during low demand periods to save resources.

Resource Management: Kubernetes efficiently manages the computing, networking, and storage resources that your microservices need to run. It ensures that each microservice has the resources it requires and is isolated from other services to prevent one service from over-consuming resources at the expense of others.

Always Online and Frequent Updates Without Downtime
Rolling Updates: When updating the application, Kubernetes can replace old versions of microservices with new ones incrementally, without taking the entire application offline. This ensures that your application remains available to users even as updates are being deployed.

Rollbacks: If an update causes issues, Kubernetes can automatically roll back to the previous version of the microservice, minimizing the impact on users.

Self-healing: Kubernetes constantly monitors the health of your microservices. If a microservice crashes or becomes unresponsive, Kubernetes automatically restarts it or replaces it with a new instance, ensuring that the application remains available.

Kubernetes vs. Docker
While both Kubernetes and Docker are centered around containerization, they serve different aspects of application development and deployment:

Docker is primarily a container runtime and toolset that makes it easy to build, package, and run applications in containers. Docker containers encapsulate an application with its dependencies, making it easy to run across different computing environments consistently.

Kubernetes, on the other hand, is a container orchestration platform that manages containers running across multiple hosts. It provides the infrastructure for deploying, scaling, and managing containerized applications. Kubernetes works with Docker and other container runtimes (like containerd and CRI-O) to manage the lifecycle of containers in a more extensive, distributed environment.

In essence, while Docker focuses on the individual container and its lifecycle, Kubernetes focuses on managing clusters of containers, including scaling, healing, and updating them with minimal downtime. This makes Kubernetes particularly well-suited for microservices-based applications that need to scale dynamically and require high availability, as it automates many of the manual processes involved in deploying and scaling containerized applications.

For applications expected to grow from a few users to millions and require constant availability, Kubernetes provides a robust, scalable platform that can adapt to changing demands, manage deployments and updates seamlessly, and ensure that services are always available to end-users.

###  Kubernetes architecture 

Kubernetes is a powerful platform designed to manage containerized applications across a cluster of machines, providing tools for deploying applications, scaling them as necessary, and managing changes to existing containerized applications. Its architecture is designed to be highly modular, distributing responsibilities across various components that work together to form a robust system. Here’s an overview of the key components within the Kubernetes architecture, using the example of autoscaling a microservice to illustrate their roles:

Kubernetes Master Components
Kubernetes API Server (kube-apiserver): This is the front end of the Kubernetes control plane, handling REST requests and updating objects in the etcd database with the desired state. For example, when scaling a microservice, a request to update the number of replicas in a Deployment would be sent to the API Server.

Etcd: A consistent and highly-available key-value store used as Kubernetes' backing store for all cluster data. It holds the actual state of the cluster, including the number of replicas for a scaled service.

Kube-Scheduler (kube-scheduler): This component watches for newly created Pods with no assigned node and selects a node for them to run on based on various scheduling criteria. In the autoscaling scenario, once the desired number of replicas increases, the Scheduler decides on which nodes the additional Pods should be created, taking into account the resources available on each node.

Controller Manager (kube-controller-manager): Runs controller processes, which are background tasks that handle routine tasks in the cluster. The Replication Controller ensures the number of Pods matches the desired state specified in the etcd for a scaled service. If a Pod crashes, the Controller Manager works to bring the system back to the desired state.

Kubernetes Node Components
Kubelet: An agent that runs on each node in the cluster, ensuring that containers are running in a Pod. The Kubelet takes a set of PodSpecs and ensures that the containers described in those PodSpecs are running and healthy. When autoscaling a microservice, the Kubelet on each node starts the containers for the new Pods assigned to its node.

Kube-Proxy (kube-proxy): Maintains network rules on nodes, allowing network communication to your Pods from network sessions inside or outside of your cluster. It ensures that each Pod gets its IP address and provides load balancing to distribute traffic to the Pods of a scaled service.

Container Runtime Interface (CRI): Enables Kubernetes to use different container runtimes, like Docker, containerd, or any other implementation that matches the CRI. The runtime is responsible for running the containers as part of the Pods.

Container Network Interface (CNI) Plugins: Provide the networking layer for Pods, enabling connectivity between Pod networks within the cluster. This is crucial for service discovery and allowing microservices to communicate with each other.

Container Storage Interface (CSI) Plugins: Allow Kubernetes to interface with a wide range of storage systems, making it possible to use persistent storage for stateful applications in the cluster.

Example: Microservice Autoscaling
Imagine a microservice that needs to scale up due to increased traffic. The process involves multiple components of the Kubernetes architecture:

Autoscaling Request: The Horizontal Pod Autoscaler (HPA) monitors traffic/load metrics and sends a request to the Kubernetes API Server to increase the number of replicas for the microservice Deployment.

State Update: The API Server updates the desired state in the etcd store, increasing the desired number of replicas.

Reconciliation: The Controller Manager detects the difference between the desired and actual states and creates new Pod objects to meet the desired state.

Scheduling: The Kube-Scheduler assigns the new Pods to suitable nodes based on resource availability.

Container Creation: The Kubelet on each designated node communicates with the container runtime via the CRI to create the additional containers required for the new Pods.

Networking and Storage: Kube-Proxy updates network rules to allow traffic to the new Pods, while CNI and CSI plugins ensure the new Pods have the necessary network connectivity and storage resources, respectively.

Through this coordinated effort, Kubernetes can efficiently scale a microservice to meet demand, ensuring high availability and optimal resource utilization across the cluster.

### Different Kubernetes distribution

Self-Managed Kubernetes
Self-managed Kubernetes distributions are tailored for organizations seeking control over their Kubernetes clusters' configuration, management, and operation. These can be deployed in various environments, including on-premises, cloud, or hybrid setups.

Kubeadm
Use Case: Standard Kubernetes cluster creation and management.
Key Features: Kubeadm is a tool provided by the Kubernetes community that simplifies the process of setting up and configuring a standard Kubernetes cluster. It automates the tasks of bootstrapping a new Kubernetes cluster, joining new nodes to the cluster, and setting up cluster networking. It's widely used for its simplicity and flexibility, allowing users to easily create a Kubernetes cluster that adheres to best practices and community standards.
Minikube
Use Case: Local development and testing.
Key Features: Simplifies the process of running a single-node Kubernetes cluster on a local machine, ideal for learning Kubernetes or developing applications in a Kubernetes environment without a cloud provider.
MicroK8s
Use Case: Workstations, edge, IoT, and appliances.
Key Features: Provides a low-maintenance, easily installable, small-footprint Kubernetes for any environment. Designed for simplicity and ease of use, with quick installation and operation.
K3s and K3d
Use Case: Edge computing, IoT, CI/CD environments, and development.
Key Features: K3s offers a lightweight, easy-to-install Kubernetes distribution suitable for resource-constrained environments. K3d facilitates running K3s in Docker containers, making it easy to manage lightweight Kubernetes environments for development and testing.
OpenShift
Use Case: Enterprise production environments.
Key Features: An enterprise Kubernetes platform with integrated development and operations tools, robust security features, built-in CI/CD, and automated operations.
Summary
Self-Managed Kubernetes options cater to a broad spectrum of needs, from local development with Minikube and lightweight deployments with MicroK8s and K3s/K3d, to comprehensive enterprise solutions like OpenShift. Kubeadm stands out for its focus on creating standard Kubernetes clusters, offering a straightforward path to setting up and managing a Kubernetes cluster that adheres to best practices. Each of these tools provides the flexibility and control necessary for managing Kubernetes environments across various scenarios, whether for development, testing, or production.

Cloud-Managed Kubernetes
Cloud-Managed Kubernetes services offer a hands-off approach to Kubernetes cluster management, where the cloud provider takes care of the setup, scalability, and maintenance of the Kubernetes infrastructure. These services integrate deeply with cloud-specific resources and services.

Amazon Elastic Kubernetes Service (EKS)
Use Case: AWS users requiring deep integration with AWS services.
Key Features: Manages the Kubernetes control plane, integrates with AWS services, and offers scalability and security for Kubernetes workloads.
Azure Kubernetes Service (AKS)
Use Case: Applications deployed on Azure.
Key Features: Simplifies the management of a Kubernetes environment on Azure, offers integrated CI/CD experiences, and integrates with Azure services for security, monitoring, and compliance.
Google Kubernetes Engine (GKE)
Use Case: Leveraging Google's infrastructure and services.
Key Features: Provides advanced cluster management features, integrates with Google Cloud services, and offers auto-scaling and a fully managed Kubernetes environment.
Summary
Self-Managed Kubernetes distributions like Minikube, MicroK8s, K3s/K3d, and OpenShift give users full control over their Kubernetes environments, suitable for a range of scenarios from development to enterprise production.

Cloud-Managed Kubernetes services such as EKS, AKS, and GKE, on the other hand, are designed for users who prefer to outsource the complexity of cluster management to their cloud provider, benefiting from deep cloud service integration, managed infrastructure, and scalability.

Choosing between self-managed and cloud-managed Kubernetes depends on an organization's specific needs, expertise, and whether they prefer the control and flexibility of managing their own environment or the convenience and integration of a cloud-managed service.



