---
title: "Task 2 - Configuration"
menuTitle: "Task 2 - configmap and secret"
weight: 2
---

### Configuring Applications with ConfigMaps and Secrets

Objective: Master injecting configuration into Pods.
Description: Learn to externalize application configuration using ConfigMaps and the Downward API. Understand how to pass environment variables, configure application settings, and expose Pod and container metadata to applications. Labs include creating ConfigMaps and using the Downward API to expose Pod information.

**ConfigMaps:**

In Kubernetes, ConfigMaps are a resource object used to store non-sensitive configuration data in key-value pairs that can be consumed by pods or other system components. They provide a way to decouple configuration artifacts from container images, allowing for more flexible and manageable application configurations.

Here are some reasons why ConfigMaps are used in Kubernetes:

- Separation of Concerns: ConfigMaps allow you to separate configuration data from application code. This separation makes it easier to manage configurations independently of the application's lifecycle, which can be particularly useful in scenarios where multiple instances of the same application are deployed with different configurations.

- Dynamic Configuration Updates: ConfigMaps support dynamic updates, meaning that changes to the configuration can be applied to running pods without requiring a restart. This allows for more flexibility and agility in managing application configurations.

- Environment Agnostic: ConfigMaps are environment-agnostic, meaning that the same configuration can be used across multiple environments (e.g., development, testing, production) without modification. This helps maintain consistency and simplifies the deployment process.

- Immutable Infrastructure: By externalizing configurations into ConfigMaps, the underlying infrastructure becomes more immutable. This means that changes to configurations do not require modifications to the underlying infrastructure, making deployments more predictable and reliable.

- Centralized Management: ConfigMaps provide a centralized location for managing configuration data. This can be particularly beneficial in large-scale deployments where multiple applications and components require different configurations.

- Integration with Other Resources: ConfigMaps can be easily integrated with other Kubernetes resources such as pods, deployments, and services. This allows you to inject configuration data into your application containers at runtime, making them highly configurable and adaptable to different environments.

Overall, ConfigMaps play a crucial role in Kubernetes by providing a flexible and efficient mechanism for managing configuration data in a containerized environment, contributing to improved application deployment, scalability, and maintainability.


**Secrets:**

In Kubernetes, Secrets are another type of resource object used to store sensitive information, such as passwords, OAuth tokens, and SSH keys, in a secure manner. They are similar to ConfigMaps but are specifically designed to handle sensitive data. Here are some key aspects of Secrets in Kubernetes:

- Secure Storage: Secrets are stored securely within the Kubernetes cluster, encrypted at rest by default. This ensures that sensitive information is not exposed or accessible to unauthorized users.

- Base64 Encoding: Secret data is typically stored in Base64 encoded format. While Base64 encoding does not provide encryption, it helps prevent accidental exposure of sensitive data in logs or other places where plaintext might be displayed.

- Multiple Types of Secrets: Kubernetes supports various types of Secrets, including generic secrets, Docker registry credentials, TLS certificates, and service account tokens. Each type of Secret has its specific use case and configuration options.

- Usage in Pods: Secrets can be mounted as volumes or exposed as environment variables within pods. This allows containers running within the pod to access the sensitive information stored in the Secret without exposing it directly in the container specification or source code.

- Access Control: Kubernetes provides role-based access control (RBAC) mechanisms to manage access to Secrets. This ensures that only authorized users or applications can create, read, update, or delete Secrets within the cluster.

- Automatic Injection: In some cases, Kubernetes can automatically inject certain types of Secrets into pods. For example, service account tokens are automatically mounted as a volume in pods running within the Kubernetes cluster, allowing them to authenticate with the Kubernetes API server.

- Immutable Once Created: Unlike ConfigMaps, Secrets are immutable once created. This means that you cannot update the data stored in a Secret directly. Instead, you must delete the existing Secret and create a new one with the updated data.

Overall, Secrets in Kubernetes provide a secure and convenient way to manage sensitive information within a cluster, ensuring that sensitive data is protected from unauthorized access while still being accessible to the applications that need it.


## Creating ConfigMaps:
```bash
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-index-html
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
      <title>Welcome to NGINX!</title>
    </head>
    <body>
      <h1>Welcome to NGINX!</h1>
      <p>This is a custom index.html page served by NGINX at $(date).</p>
    </body>
    </html>
EOF
```

To get configmap, try ```kubectl get configmap```

## Creating Secret:

- Firstly, we need encode a secret value to base64. On linux you can use the following commands to encode.

- Encode a string to base64:

```echo -n 'your_secret_value' | base64```

for example: 

```bash
base64_encoded_username=$(echo -n 'ftntadmin' | base64)
base64_encoded_password=$(echo -n 'password123' | base64)

cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: nginx-secret
type: Opaque
data:
  username: $base64_encoded_username
  password: $base64_encoded_password
EOF
```

There are several types of built in Secrets [!https://kubernetes.io/docs/concepts/configuration/secret/#secret-types] in Kubernetes. Opaque is a secret which is an arbitrary user defined data. 


## Creating a pod using confimap and secret  

```bash
cat << EOF | tee nginx-pod-with-configmap-secret.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod-with-configmap-secret
spec:
  containers:
  - name: nginx-container
    image: nginx:latest
    ports:
    - containerPort: 80
    volumeMounts:
    - name: nginx-config-volume
      mountPath: /usr/share/nginx/html
    - name: nginx-secret-volume
      mountPath: /etc/nginx/secret
      readOnly: true
  volumes:
  - name: nginx-config-volume
    configMap:
      name: nginx-index-html
  - name: nginx-secret-volume
    secret:
      secretName: nginx-secret
EOF
kubectl apply -f nginx-pod-with-configmap-secret.yaml
```

### Review Questions

- how to access nginx web page from container inside ?

answer
```bash
kubectl exec -it po/nginx-pod-with-configmap-secret -- curl http://127.0.0.1
```
- delete pod nginx-pod-with-configmap-secret  and create again, check the web page of nginx again ? did you see any difference ? why ?
answer
```
it will remain same, as configmap did not change. 
```

- how to make nginx server web page with secret just created 

answer

- Create a sample configmap, then update below nginx-deployment to use the ConfigMap

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

Answer

```bash
cat << EOF | tee nginx_deployment_cm.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-webpage
data:
  index.html: |
    <html>
    <head>
    <title>Welcome to NGINX!</title>
    </head>
    <body>
    <h1>Hello, Kubernetes!</h1>
    </body>
    </html>

kubectl create -f nginx_deployment_cm.yaml
```
and deployment

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: webpage
          mountPath: /usr/share/nginx/html  # NGINX serves content from this directory
      volumes:
      - name: webpage
        configMap:
          name: nginx-webpage  # Name of your ConfigMap
```

