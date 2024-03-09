---
title: "Kubernetes Overview"
chapter: false
menuTitle: "Kubernetes Overview"
weight: 2
---

##  What is Kubernetes, and Why Kubernetes

Kubernetes is a powerful platform designed to automate deploying, scaling, and operating application containers, making it an excellent choice for managing microservices-based applications that need to scale from a few users to millions of internet users while ensuring high availability. Here's how Kubernetes addresses these specific requirements:

{{% notice info %}}

A microservice is like a small, specialized team in a company. Each team focuses on a specific task, such as marketing or customer support, and works independently. Similarly, in software, a microservice is a small, self-contained component that handles a specific function of an application, like user authentication or order processing.

{{% /notice %}}

![](https://i0.wp.com/vitalflux.com/wp-content/uploads/2018/03/microservices-styled-architecture.png?w=513&ssl=1)

![](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/containers/aks-microservices/images/aks.svg)

### Scaling from Few Users to Millions

* Horizontal Pod Autoscaling (HPA): 
Kubernetes can automatically adjust the number of running pods (where you container is running) of your microservices based on the actual demand observed. As the number of users grows, HPA increases the number of pods to maintain performance and reduce latency. Conversely, it reduces the number of pods during low demand periods to save resources.

* Kubernetes Cluster Autoscaler (KCA):
The Kubernetes Cluster Autoscaler is an automated component that adjusts the number of nodes (virtual machines) in a Kubernetes cluster to meet the current demand for application resources. It works closely with cloud providers to dynamically scale the cluster's infrastructure by adding nodes when there's insufficient capacity for application workloads (scaling out/up) and removing nodes when they're underutilized (scaling in/down). This ensures efficient resource use and maintains application performance as user demand changes, enabling seamless scalability from a few users to millions without manual intervention.

* HPA (Horizontal Pod Autoscaler) scales your pods across existing nodes, while KCA (Kubernetes Cluster Autoscaler) scales the nodes themselves. Together, HPA and KCA enable Kubernetes to efficiently scale to meet the demands of millions of users, optimizing cost management.

* Resource Management: 
Kubernetes efficiently manages the computing, networking, and storage resources that your microservices need to run. It ensures that each microservice has the resources it requires and is isolated from other services to prevent one service from over-consuming resources at the expense of others


### Kubernetes vs. Docker
While both Kubernetes and Docker are centered around containerization, they serve different aspects of application development and deployment:

Docker is primarily a container runtime and toolset that makes it easy to build, package, and run applications in containers. Docker containers encapsulate an application with its dependencies, making it easy to run across different computing environments consistently.

Kubernetes, on the other hand, is a container orchestration platform that manages containers running across multiple hosts. It provides the infrastructure for deploying, scaling, and managing containerized applications. Kubernetes works with Docker and other container runtimes (like containerd and CRI-O) to manage the lifecycle of containers in a more extensive, distributed environment.

In essence, while Docker focuses on the individual container and its lifecycle, Kubernetes focuses on managing clusters of containers, including scaling, healing, and updating them with minimal downtime. This makes Kubernetes particularly well-suited for microservices-based applications that need to scale dynamically and require high availability, as it automates many of the manual processes involved in deploying and scaling containerized applications.

For applications expected to grow from a few users to millions and require constant availability, Kubernetes provides a robust, scalable platform that can adapt to changing demands, manage deployments and updates seamlessly, and ensure that services are always available to end-users.


##  Kubernetes architecture 

Kubernetes is a powerful platform designed to manage containerized applications across a cluster of machines, providing tools for deploying applications, scaling them as necessary, and managing changes to existing containerized applications. Its architecture is designed to be highly modular, distributing responsibilities across various components that work together to form a robust system. Here’s an overview of the key components within the Kubernetes architecture, using the example of autoscaling a microservice to illustrate their roles:

![](https://Kubernetes.io/images/docs/Kubernetes-cluster-architecture.svg)

In the diagram above, a Node can be any platform capable of running your Pod, such as a bare metal machine, an IoT edge device, a cloud-based virtual machine, and more."

### Kubernetes Master (Control-Plane) Components
* Kubernetes API Server (kube-apiserver): 

This is the front end of the Kubernetes control plane, handling REST requests and updating objects in the etcd database with the desired state. For example, when scaling a microservice, a request to update the number of replicas in a Deployment would be sent to the API Server. 

* Etcd: 

A consistent and highly-available key-value store used as Kubernetes' backing store for all cluster data. It holds the actual state of the cluster, including the number of replicas for a scaled service.

* Kube-Scheduler (kube-scheduler): 

This component watches for newly created Pods with no assigned node and selects a node for them to run on based on various scheduling criteria. In the autoscaling scenario, once the desired number of replicas increases, the Scheduler decides on which nodes the additional Pods should be created, taking into account the resources available on each node.

* Controller Manager (kube-controller-manager): 

Runs controller processes, which are background tasks that handle routine tasks in the cluster. The Replication Controller ensures the number of Pods matches the desired state specified in the etcd for a scaled service. If a Pod crashes, the Controller Manager works to bring the system back to the desired state.

### Kubernetes Worker Node Components
* Kubelet: 
An agent that runs on each node in the cluster, ensuring that containers are running in a Pod. The Kubelet takes a set of PodSpecs and ensures that the containers described in those PodSpecs are running and healthy. When autoscaling a microservice, the Kubelet on each node starts the containers for the new Pods assigned to its node.

* Kube-Proxy (kube-proxy): 
Maintains network rules on nodes, allowing network communication to your Pods from network sessions inside or outside of your cluster. It ensures that each Pod gets its IP address and provides load balancing to distribute traffic to the Pods of a scaled service.

* Container Runtime Interface (CRI): 
Enables Kubernetes to use different container runtimes, like Docker, containerd, or any other implementation that matches the CRI. The runtime is responsible for running the containers as part of the Pods. common CRI are cri-o, containerd and docker. Kubernetes is deprecating Docker as a container runtime after v1.20. 

* Container Network Interface (CNI) Plugins: 
Provide the networking layer for Pods, enabling connectivity between Pod networks within the cluster. This is crucial for service discovery and allowing microservices to communicate with each other across multiple nodes. common CNI like Calico , Cilium , Flannel etc., Managed Kubernetes like EKS, AKS, and GKE often has it's own CNI which often optimized for cloud networking. 

* Container Storage Interface (CSI) Plugins: 
Allow Kubernetes to interface with a wide range of storage systems, making it possible to use persistent storage for stateful applications in the cluster.

Below let's summarize with a comparsion between Kubernetes components and a manufacturing environment analogy.

| Kubernetes Component         | Manufacturing Analogy                 | Description                                                                                                                                                                                                                          |
|------------------------------|---------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------| 
| Master Node                  | Central Command Center                | Coordinates the activities within the Kubernetes cluster, overseeing operations and making critical decisions, similar to how a command center manages a manufacturing facility's operations.                                               |
| Worker Node                  | Factory                               | Runs the containers and manages workloads, akin to a factory where products are manufactured.                                                                         
| API Server                   | Design House                          | Acts as the central management entity for the cluster, similar to how a design house plans and stores blueprints. It processes all REST requests and updates the state of the cluster.                                                             |
| Container                    | Robot Machine                         | Represents a single, focused task or application, similar to a robot machine designed for a specific manufacturing process.                                                                                                         |
| Kubelet                      | Supervisor                            | Manages the containers on a node, ensuring they are running as expected, much like a supervisor overseeing factory operations.                                                                                                       |
| Pod                          | Manufacturing Cell                    | The smallest deployable unit in Kubernetes, comparable to a manufacturing cell where a group of machines work together on a task.                                                                                                   |
| Controller Manager           | Production Manager                    | Oversees and regulates the state of the cluster, like a production manager ensuring manufacturing goals are met.                                                                                                                    |
| Scheduler                    | Planner                               | Decides on which node a pod should run, optimizing resource use, similar to a planner scheduling manufacturing processes for efficiency.                                                                                            |
| etcd                         | Blueprint Storage                     | A key-value store for cluster data, acting as the single source of truth, analogous to the secure storage and management of blueprints.                                                                                             |
| Container Runtime            | Utility Infrastructure                | Provides the necessary environment and tools to run containers, akin to the utility infrastructure (electricity, water, gas) that powers machinery in a factory.                                                                    |
| Container Network Interface (CNI) | Factory's Internal Transportation System | Ensures that network traffic can be routed appropriately between containers, nodes, and external services, just like a factory's transportation system moves materials and products efficiently between different sections. |


## Different Kubernetes distribution

* Self-Managed Kubernetes:
Self-Managed Kubernetes distributions like Minikube, MicroK8s, K3s/K3d, and OpenShift give users full control over their Kubernetes environments, suitable for a range of scenarios from development to enterprise production.

* Cloud-Managed Kubernetes:
Cloud-managed Kubernetes services, such as Azure Kubernetes Service (AKS), Google Kubernetes Engine (GKE), and Amazon Elastic Kubernetes Service (EKS), simplify the deployment, management, and scaling of Kubernetes clusters. These services abstract away the complexity of the Kubernetes control plane (master node), handling its provisioning, setup, scaling, and maintenance automatically.

By managing the control plane, these services take away the operational overhead of running a Kubernetes cluster. Users don't need to worry about the intricacies of setting up and maintaining Kubernetes masters, updating them, or managing their availability and scalability. This abstraction allows developers and operations teams to focus on deploying and managing their applications within Kubernetes, leveraging the powerful orchestration capabilities of Kubernetes without the need to manage its underlying infrastructure.

Choosing between self-managed and cloud-managed Kubernetes depends on an organization's specific needs, expertise, and whether they prefer the control and flexibility of managing their own environment or the convenience and integration of a cloud-managed service.