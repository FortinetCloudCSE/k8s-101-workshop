---
title: "Task 8 - Service Mesh"
menuTitle: "Service Mesh"
chapter: false
weight: 5
---
### What is Service Mesh and Why

Service mesh solutions like Istio are used to manage complex service-to-service communication within microservices architectures efficiently and securely. They provide a dedicated infrastructure layer built right into the application runtime environment that abstracts and controls inter-service communication, making it easier to implement critical features without altering the application code. Among the numerous use cases and benefits, the most important ones include:
{{% expand title="Click for Detail..." %}}
1. Traffic Management
Service meshes offer sophisticated traffic routing rules, load balancing, and control mechanisms that enable A/B testing, canary releases, and blue-green deployments. This allows developers to gradually roll out changes in a controlled manner, directing traffic between different versions of a service based on weights, HTTP headers, or other criteria.

2. Security
Security is a critical aspect of service meshes. They enhance security by providing mutual TLS (mTLS) for service-to-service encryption, strong identity and certificate management for services, and fine-grained access control policies. This ensures that communication within the cluster is secure and authenticated, significantly reducing the risk of man-in-the-middle attacks or data eavesdropping.

3. Observability
Service meshes inherently offer deep insights into the behavior of the services in the mesh. They provide detailed telemetry data on service performance, including metrics, logs, and traces, which are invaluable for monitoring, troubleshooting, and understanding the system's behavior. This level of observability helps detect and resolve issues quickly, ensuring high availability and reliability.

4. Reliability and Resilience
Implementing resilience patterns such as retries, timeouts, circuit breakers, and rate limiting can be complex. Service meshes like Istio enable these features out of the box, helping services to gracefully handle failures and prevent cascading failures in a microservices architecture. This improves the overall stability and reliability of applications.

5. Policy Enforcement
Service meshes allow operators to implement and enforce policies across all communications within the mesh without changing application code. This includes access policies, routing rules, and quotas. Policy enforcement ensures that the organization's governance and regulatory requirements are consistently met across all services.

Conclusion
The most important use case of a service mesh like Istio is to provide a comprehensive solution that addresses critical operational challenges of microservices architectures, including traffic management, security, observability, resilience, and policy enforcement. By abstracting these functionalities into the infrastructure layer, Istio allows developers and operators to focus on building and maintaining their applications rather than managing the complexities of service-to-service communication.
{{% /expand %}}
### Understanding How Service Mesh Works

Istio enhances Kubernetes applications by injecting an Envoy proxy as a **sidecar container** into each pod that's marked for Istio injection. This process is facilitated by Kubernetes' Mutating Admission Webhook, which automatically modifies pod creation requests to include the **Envoy** sidecar. This setup ensures that all inbound and outbound traffic from the application pods is managed through the Envoy proxy.
{{% expand title="Click for Detail..." %}}
By integrating these sidecar containers within the client namespace for both backend and frontend components, Istio leverages the Envoy sidecar to provide sophisticated traffic management, heightened security, and comprehensive observability features. The control plane component, known as **istiod**, unifies functionalities of previously separate components (like **Pilot**, **Citadel**, and **Galley**) into a single binary. It plays a crucial role in mesh configuration, proxy configuration distribution, service discovery, and enforcing authentication and authorization policies.

The Istio service mesh employs an istio-ingressgateway, which is essentially an Envoy proxy that operates as a load balancer. This gateway serves as the entry point for external traffic into the mesh, applying Istio's routing rules and policies before traffic reaches the application services.

Istio also utilizes **init-container** to setup iptables rules to redirect traffic from the client applications to the Envoy proxy. This ensures that even intra-mesh communication benefits from Istio's traffic management and security mechanisms.
{{% /expand %}}
### Preparation for Istio/Envoy Installation

Prior to deploying Istio/Envoy, it's essential to verify the availability of an external IP for the load balancer. Istio's architecture includes an ingress gateway that necessitates an external IP address to function correctly. Ensuring this requirement is met is a critical step in the preparation phase for a successful Istio installation.
{{% expand title="Click for Detail..." %}}

Before installing Istio/Envoy, check if there is a free external IP available for a load balancer, as Istio will install an ingress gateway that requires a load balancer with an external IP.


```bash
kubectl get svc -A -o json | jq '.items[] | select(.spec.type == "LoadBalancer") | {name: .metadata.name, namespace: .metadata.namespace,status: .status}'
```
Below you will find a loadBalancer kong-proxy with external IP 10.0.0.4 exist. 

```bash
kubectl get svc -A -o json | jq '.items[] | select(.spec.type == "LoadBalancer") | {name: .metadata.name, namespace: .metadata.namespace,status: .status}'
{
  "name": "kong-proxy",
  "namespace": "kong",
  "status": {
    "loadBalancer": {
      "ingress": [
        {
          "ip": "10.0.0.4"
        }
      ]
    }
  }
}
``` 

delete it to release external ip for istio to use 

```bash
kubectl delete svc kong-proxy -n kong
```
{{% /expand %}}
### install istio-envoy

{{% expand title="Click for Detail..." %}}
- Download and Extract Istio
```
curl -L --retry 3 --retry-delay 5  https://istio.io/downloadIstio | ISTIO_VERSION=1.20.3 sh -
cd istio-1.20.3
```
- add path to istioctl 

The istioctl command-line tool is in the bin directory; you might want to add it to your path for ease of use:
```
export PATH=$PWD/bin:$PATH
```

- Install Istio Using istioctl

Istio offers different configuration profiles for installation. For a standard installation (which is suitable for most use cases), you can use the default profile:
```bash
istioctl install --set profile=default -y
```
This command uses istioctl to install Istio with the default profile.  

expected to see 

```bash
ubuntu@ubuntu22:~/istio-1.20.3$ istioctl install --set profile=default -y
✔ Istio core installed                                                                                             
✔ Istiod installed                                                                                                 
✔ Ingress gateways installed                                                                                       
✔ Installation complete                                                                               Made this installation the default for injection and validation.
```
{{% /expand %}}

### Verify The Installation
{{% expand title="Click for Detail..." %}}
A new LoadBalacner with name istio-ingressgateway shall be installed with external-ip.

```bash
kubectl get svc istio-ingressgateway -n istio-system
NAME                   TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)                                      AGE
istio-ingressgateway   LoadBalancer   10.110.27.52   10.0.0.4      15021:30311/TCP,80:32317/TCP,443:31503/TCP   106s
```
istio-ingressgateway is istio dataplane proxy which is envoy. 

```bash
ubuntu@ubuntu22:~$ k get pod -n istio-system -l app=istio-ingressgateway -o yaml | grep image: | uniq
      image: docker.io/istio/proxyv2:1.20.3
```
istiod is the control plane component called pilot. 

```bash

ubuntu@ubuntu22:~$ k get pod -n istio-system -l app=istiod -o yaml | grep image: | uniq
      image: docker.io/istio/pilot:1.20.3

```




Check that the Istio control plane services and pods are up and running:

And verify that the corresponding Istio control plane pods are all in a RUNNING state:

```
kubectl get pods -n istio-system
```
{{% /expand %}}
### Enable Automatic Sidecar Injection
{{% expand title="Click for Detail..." %}}

Enable automatic sidecar injection for your namespace with below 

```bash
kubectl create namespace client
kubectl get namespace client
kubectl label namespace client istio-injection=enabled
```
this will allow istio insert sidecar container for pod that labeled with **istio-injection=enabled**  
{{% /expand %}}
### Demo

{{% expand title="Click for Detail..." %}}
- Create demo application  in client namespace

We deploy both frontend svc and backend svc in client namespace. the traffic from frontend will reach backend svc via istio envoy proxy. 

- Deploy a simple HTTP echo service as the backend:


```bash
cd $HOME
cat << EOF | sudo tee > client_app_backend.yaml
apiVersion: v1
kind: Service
metadata:
  name: echo-service
  namespace: client
spec:
  ports:
  - port: 80
    name: http
    targetPort: 5678
  selector:
    app: echo
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo-deployment
  namespace: client
spec:
  replicas: 1
  selector:
    matchLabels:
      app: echo
  template:
    metadata:
      labels:
        app: echo
    spec:
      containers:
      - name: echo
        image: hashicorp/http-echo
        args:
        - "-text=Hello from backend service"
        ports:
        - containerPort: 5678
EOF
kubectl apply -f client_app_backend.yaml

```
- Deploy frontend application in client namespace.

```bash
cd $HOME
cat <<EOF | sudo tee > client_app_frontend.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: client-deployment
  namespace: client
spec:
  replicas: 1
  selector:
    matchLabels:
      app: client
  template:
    metadata:
      labels:
        app: client
    spec:
      containers:
      - name: client
        image: curlimages/curl
        command: ["/bin/sh", "-c"]
        args:
        - >
          while true; do
            sleep 10;
            curl echo-service.client.svc.cluster.local;
          done
EOF

kubectl apply -f client_app_frontend.yaml
```
- Check deployment of client application 
```bash
kubectl get all -n client
```
you are expected to see both frontend pod and backend pod (echo) will has two container running . one of the container is the injected sidecar container.

```bash
ubuntu@ubuntu22:~$ kubectl get all -n client
NAME                                    READY   STATUS    RESTARTS   AGE
pod/client-deployment-965cf5696-lgj8n   2/2     Running   0          32s
pod/echo-deployment-ddd46554c-lpqh6     2/2     Running   0          4m11s

NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/echo-service   ClusterIP   10.100.72.165   <none>        80/TCP    4m11s

NAME                                READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/client-deployment   1/1     1            1           32s
deployment.apps/echo-deployment     1/1     1            1           4m11s

NAME                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/client-deployment-965cf5696   1         1         1       32s
replicaset.apps/echo-deployment-ddd46554c     1         1         1       4m11s
```

- Check the container injected into application in client namespace

Istio injected two container into pod in client namespace. one is 
init container with name "istio-init" and other one is sidecar container "istio-proxy" doing actual proxy for traffic. 
the init container "istio-init" setup necessary iptables rules to intercept and redirect inbound and outbound traffic to and from the application containers to the Envoy proxy sidecar container. This process ensures that all traffic can be managed, monitored, and manipulated by Istio's service mesh functionalities, such as traffic control, security policies, and observability features.

```bash

ubuntu@ubuntu22:~$ k get pod -l app=client -n client -o yaml | grep initContainers: -A 20
    initContainers:
    - args:
      - istio-iptables
      - -p
      - "15001"
      - -z
      - "15006"
      - -u
      - "1337"
      - -m
      - REDIRECT
      - -i
      - '*'
      - -x
      - ""
      - -b
      - '*'
      - -d
      - 15090,15021,15020
      - --log_output_level=default:info
      image: docker.io/istio/proxyv2:1.20.3
```
and 
```bash
ubuntu@ubuntu22:~$ k get pod -l app=client -n client -o yaml | grep sidecar 
      sidecar.istio.io/status: '{"initContainers":["istio-init"],"containers":["istio-proxy"],"volumes":["workload-socket","credential-socket","workload-certs","istio-envoy","istio-data","istio-podinfo","istio-token","istiod-ca-cert"],"imagePullSecrets":null,"revision":"default"}'
      - sidecar
```

- Enable mTLS 

this show how to use Istio to automatically encrypt traffic between two services (frontend and backend) within the client namespace, using Istio's mutual TLS (mTLS) capabilities. This ensures that the communication is secure and authenticated in both directions.

```bash
cat << EOF | sudo tee > client_peer_tls.yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: client
spec:
  mtls:
    mode: STRICT
EOF

kubectl apply -f client_peer_tls.yaml
```

- create httpbin service in client namespace

the httpbin support return http header, we can use this to check the "X-Forwarded-Client-Cert" field in header.

```bash
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.5/samples/httpbin/httpbin.yaml -n client 

```
- Verify Traffic Between frontend and httpbin


```bash

podname=$(kubectl get pod -n client -l app=httpbin -o jsonpath={.items..metadata.name}
kubectl exec -it po/$podname -n client -- curl http://httpbin.client.svc.cluster.local:8000/headers

```
```bash
The "X-Forwarded-Client-Cert" is the indication that traffic is encrypted by mTLS.
{
  "headers": {
    "Accept": "*/*", 
    "Host": "httpbin.client.svc.cluster.local:8000", 
    "User-Agent": "curl/8.6.0", 
    "X-B3-Parentspanid": "a333da69eeb71b8a", 
    "X-B3-Sampled": "0", 
    "X-B3-Spanid": "a72fed568e00c0dc", 
    "X-B3-Traceid": "0fb433e1abb5a37ba333da69eeb71b8a", 
    "X-Envoy-Attempt-Count": "1", 
    "X-Forwarded-Client-Cert": "By=spiffe://cluster.local/ns/client/sa/httpbin;Hash=cd72c6a2fc780df9feda914bf7ea0ffb4e8766101225952bff12ae692c3793af;Subject=\"\";URI=spiffe://cluster.local/ns/client/sa/default"
  }
}
```

- Verify Traffic Between frontend POD to backend service 

Verify the setup by checking the logs of the client pod to see responses from the backend service:

Check the Logs of the Client Pod

```bash
kubectl logs -n client -l app=client -c client
```

you are expected to see that backend echo "Hello from backend service" indicate that service-mesh is working 

```bash
ubuntu@ubuntu22:~$ kubectl logs -n client -l app=client -c client
   0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0Hello from backend service
100    27  100    27    0     0   1321      0 --:--:-- --:--:-- --:--:--  1350
ubuntu@ubuntu22:~$ 
``` 
{{% /expand %}}

### Service-Mesh obvserbility

{{% expand title="Click for Detail..." %}}
We can install a ISTIO added on **kiali** to check the Web GUI based dashboard 
together with **prometheus**, kiali show you a comprehensive traffic graph 

- install kiali
Install Kiali for observability:

```bash
ISTIO_HOME="$HOME/istio-1.20.3"
kubectl apply -f ${ISTIO_HOME}/samples/addons/kiali.yaml
kubectl apply -f ${ISTIO_HOME}/samples/addons/prometheus.yaml

```

- check kiali deployment

```bash
kubectl rollout status deployment kiali -n istio-system
kubectl get deployment -n istio-system -l app=kiali
kubectl get deployment -n istio-system -l app=prometheus
kubectl get svc -n istio-system -l app=kiali

```
you expected to see 
```bash
deployment "kiali" successfully rolled out
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
kiali   1/1     1            1           7m7s
kubectl get deployment -n istio-system -l app=prometheus
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
prometheus   1/1     1            1           4m21s
NAME    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)              AGE
kiali   ClusterIP   10.102.25.174   <none>        20001/TCP,9090/TCP   4m40s
```

- expose kiali dashboard

Forward the Kiali dashboard port to make it accessible:

kiali by default only created clusterIP type service on TCP port 20001, to expose this service to internet, we can use NodePort service for Kiali.

```bash
kubectl expose deployment kiali  --type NodePort --name kialinodeport -n istio-system
```
check the nodeport service 
```bash
kubectl  get svc -l app=kiali -n istio-system
```
you shall see a NodePort Svc similar as below with TCP port on 31602.

```bash
ubuntu@ubuntu22:~$ k get svc -l app=kiali -n istio-system
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                          AGE
kiali           ClusterIP   10.102.25.174   <none>        20001/TCP,9090/TCP               9m26s
kialinodeport   NodePort    10.110.24.115   <none>        20001:31602/TCP,9090:30481/TCP   30s
``` 

**optional** As an alternative to creating a NodePort service for Kiali, you can temporarily expose the service using kubectl port-forward combined with socat. This method is useful for quick, temporary access without configuring a permanent service type in Kubernetes.  

No matter use NodePort or `kubectl port-forward` with `socat`, if you're using Azure, remember to open TCP port 31602 (or any other port you pickup ) to allow incoming traffic. This step ensures external access to the Kiali UI through the configured port. 

```bash
kubectl port-forward svc/kiali 20001:20001 -n istio-system &
socat TCP-LISTEN:31602,reuseaddr,fork TCP:127.0.0.1:20001
```



Verify access: 
```bash

curl http://k8strainingmaster001.westus.cloudapp.azure.com:31602

```

this expect to get response 
```bash
<a href="/kiali/">Found</a>.
```
then use your web browser to access `http://k8strainingmaster001.westus.cloudapp.azure.com:31602` 


you are expected to see web page like this




![kiali frontpage](https://istio.io/latest/docs/tasks/observability/kiali/kiali-overview.png)

{{% /expand %}}



