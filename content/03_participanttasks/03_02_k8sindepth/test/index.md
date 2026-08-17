cd $HOME/k8s-101-workshop/terraform/
nodename=$(terraform output -json | jq -r .linuxvm_master_FQDN.value)
cd $HOME
cat <<EOF  | tee nginx_ingress_rule_with_cert_${nodename}.yaml
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
      - path: /bootcamp
        pathType: ImplementationSpecific
        backend:
          service:
            name: kubernetes-bootcamp
            port:
              number: 80  
EOF
kubectl apply -f nginx_ingress_rule_with_cert_${nodename}.yaml