#!/bin/bash -xe

fqdn="${FQDN:-${fqdn:-localhost}}"
nodename=$(hostname)

error_handler() {
    echo -e "\e[31mAn error occurred. Exiting...\e[0m" >&2
    tput bel || true
}
trap error_handler ERR

kubectl get nodes -o wide
kubectl get node | grep -i Ready

# Local storage for simple lab PVC examples.
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.31/deploy/local-path-storage.yaml
kubectl rollout status deployment local-path-provisioner -n local-path-storage --timeout=180s
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' || true

# Metrics Server is required before HPA can report CPU utilization.
curl --retry 3 --retry-connrefused -fL "https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml" -o components.yaml
sed -i '/- --metric-resolution/a \        - --kubelet-insecure-tls' components.yaml
kubectl apply -f components.yaml
kubectl rollout status deployment metrics-server -n kube-system --timeout=180s

# Install MetalLB for LoadBalancer service testing on this small Azure VM lab.
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.2/config/manifests/metallb-native.yaml
kubectl rollout status deployment controller -n metallb-system --timeout=180s
kubectl rollout status ds speaker -n metallb-system --timeout=180s

cd "$HOME"
local_ip=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
cat <<EOF_POOL | sudo tee metallbippool.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - ${local_ip}/32
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
EOF_POOL
kubectl apply -f metallbippool.yaml

# Keep Kong/cert-manager in the original workshop flow, but update to current versions.
kubectl apply -f https://raw.githubusercontent.com/Kong/kubernetes-ingress-controller/v3.5.0/deploy/single/all-in-one-dbless.yaml
kubectl rollout status deployment proxy-kong -n kong --timeout=300s
kubectl rollout status deployment ingress-kong -n kong --timeout=300s

cat <<'EOF_NGINX' | kubectl apply -f -
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
        resources:
          requests:
            memory: "64Mi"
            cpu: "10m"
          limits:
            memory: "128Mi"
            cpu: "40m"
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: nginx
  name: nginx-deployment
  namespace: default
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: nginx
  type: ClusterIP
EOF_NGINX
kubectl rollout status deployment nginx-deployment --timeout=180s

kubectl get namespace cert-manager || kubectl create namespace cert-manager
kubectl apply --validate=false -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.2/cert-manager.yaml
kubectl rollout status deployment cert-manager -n cert-manager --timeout=300s
kubectl rollout status deployment cert-manager-cainjector -n cert-manager --timeout=300s
kubectl rollout status deployment cert-manager-webhook -n cert-manager --timeout=300s

cat <<EOF_CERT | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer-test
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: test-tls-test
spec:
  secretName: test-tls-test
  duration: 2160h
  renewBefore: 360h
  issuerRef:
    name: selfsigned-issuer-test
    kind: ClusterIssuer
  commonName: kong.example
  dnsNames:
  - ${nodename}
  - ${fqdn}
EOF_CERT

cat <<EOF_INGRESS | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx
  annotations:
    konghq.com/strip-path: 'true'
    cert-manager.io/cluster-issuer: selfsigned-issuer-test
spec:
  tls:
  - hosts:
    - ${nodename}
    - ${fqdn}
  ingressClassName: kong
  rules:
  - host: ${nodename}
    http:
      paths:
      - path: /default
        pathType: ImplementationSpecific
        backend:
          service:
            name: nginx-deployment
            port:
              number: 80
  - host: ${fqdn}
    http:
      paths:
      - path: /default
        pathType: ImplementationSpecific
        backend:
          service:
            name: nginx-deployment
            port:
              number: 80
EOF_INGRESS

cat <<'EOF_HPA' | kubectl apply -f -
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-deployment
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
EOF_HPA

kubectl get deployment nginx-deployment
kubectl get hpa
kubectl get ingress
kubectl get svc -A
kubectl get pods -A

echo "application and HPA demo components deployed"
trap - ERR
