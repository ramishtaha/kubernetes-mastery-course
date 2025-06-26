# Module 6: Networking in Kubernetes

## 📚 Learning Objectives

By the end of this module, you will understand:
- Kubernetes networking model and architecture
- Service types and their use cases
- Ingress controllers and routing
- Network Policies for security
- DNS in Kubernetes
- Load balancing and service discovery
- Troubleshooting network issues

## 🎯 Prerequisites

- Completed Module 5: Storage
- Basic understanding of networking concepts (IP, DNS, HTTP/HTTPS)
- Knowledge of load balancing concepts

## 📖 Theory: Kubernetes Networking

### Networking Model

Kubernetes networking follows these principles:
1. **Pod-to-Pod Communication**: All Pods can communicate without NAT
2. **Node-to-Pod Communication**: Nodes can communicate with all Pods
3. **Service Discovery**: Services provide stable endpoints for Pods
4. **External Access**: Ingress provides external access to services

### Pod Networking

Each Pod gets its own IP address:
- Containers in a Pod share the network namespace
- Containers communicate via localhost
- Pod IPs are ephemeral and change when Pods restart

```yaml
# Pod with multiple containers sharing network
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
spec:
  containers:
  - name: web
    image: nginx
    ports:
    - containerPort: 80
  - name: sidecar
    image: busybox
    command: ['sh', '-c', 'while true; do wget -qO- localhost:80; sleep 30; done']
```

### Services

Services provide stable networking for Pods:

#### 1. ClusterIP (Default)
- Internal cluster communication only
- Stable cluster-internal IP and DNS name

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
```

#### 2. NodePort
- Exposes service on each node's IP at a static port
- Accessible from outside the cluster

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-nodeport
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080
  type: NodePort
```

#### 3. LoadBalancer
- Provisions external load balancer (cloud provider)
- Combines NodePort and external load balancer

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-loadbalancer
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080
  type: LoadBalancer
```

#### 4. ExternalName
- Maps service to external DNS name
- No proxying, returns CNAME record

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  type: ExternalName
  externalName: database.example.com
```

### Ingress

Ingress manages external HTTP/HTTPS access:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
```

### Network Policies

Network Policies control traffic flow between Pods:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-to-db
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: web
    ports:
    - protocol: TCP
      port: 5432
```

## 🧪 Hands-on Labs

### Lab 1: Service Types and Communication

1. **Create a multi-tier application**:

```bash
# Create backend deployment
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: nginx
        ports:
        - containerPort: 80
        env:
        - name: SERVICE_NAME
          value: "Backend Service"
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF
```

2. **Create frontend deployment**:

```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: nginx
        ports:
        - containerPort: 80
        env:
        - name: BACKEND_URL
          value: "http://backend-service"
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: NodePort
EOF
```

3. **Test internal communication**:

```bash
# Get service information
kubectl get services

# Test internal service discovery
kubectl run test-pod --image=busybox --rm -it -- sh

# Inside the test pod:
# nslookup backend-service
# nslookup frontend-service
# wget -qO- backend-service
# exit
```

4. **Test external access via NodePort**:

```bash
# Get NodePort
kubectl get service frontend-service

# Get node IP
kubectl get nodes -o wide

# Access service (replace with your node IP and NodePort)
curl http://<NODE-IP>:<NODEPORT>
```

### Lab 2: Ingress Controller Setup

1. **Install NGINX Ingress Controller**:

```bash
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/baremetal/deploy.yaml

# Wait for deployment
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Check ingress controller status
kubectl get pods -n ingress-nginx
```

2. **Create applications for ingress**:

```bash
kubectl apply -f - <<EOF
# App 1
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
      - name: app1
        image: hashicorp/http-echo
        args:
        - "-text=Hello from App 1!"
        ports:
        - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: app1-service
spec:
  selector:
    app: app1
  ports:
  - port: 80
    targetPort: 5678
---
# App 2
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app2
  template:
    metadata:
      labels:
        app: app2
    spec:
      containers:
      - name: app2
        image: hashicorp/http-echo
        args:
        - "-text=Hello from App 2!"
        ports:
        - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: app2-service
spec:
  selector:
    app: app2
  ports:
  - port: 80
    targetPort: 5678
EOF
```

3. **Create Ingress rules**:

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: path-based-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /app1
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
      - path: /app2
        pathType: Prefix
        backend:
          service:
            name: app2-service
            port:
              number: 80
EOF
```

4. **Test ingress routing**:

```bash
# Get ingress information
kubectl get ingress

# Get ingress controller NodePort
kubectl get service -n ingress-nginx

# Test routing (replace with your ingress controller IP and port)
INGRESS_PORT=$(kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[0].nodePort}')
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')

curl http://$NODE_IP:$INGRESS_PORT/app1
curl http://$NODE_IP:$INGRESS_PORT/app2
```

### Lab 3: DNS and Service Discovery

1. **Create a test application with service**:

```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dns-test-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dns-test
  template:
    metadata:
      labels:
        app: dns-test
    spec:
      containers:
      - name: app
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: dns-test-service
spec:
  selector:
    app: dns-test
  ports:
  - port: 80
    targetPort: 80
EOF
```

2. **Test DNS resolution**:

```bash
# Create a debug pod
kubectl run dns-debug --image=busybox --rm -it -- sh

# Inside the debug pod, test DNS:
# nslookup dns-test-service
# nslookup dns-test-service.default.svc.cluster.local
# nslookup kubernetes
# nslookup kubernetes.default.svc.cluster.local

# Test connectivity
# wget -qO- dns-test-service
# exit
```

3. **Examine DNS configuration**:

```bash
# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check CoreDNS configuration
kubectl get configmap -n kube-system coredns -o yaml

# Check service endpoints
kubectl get endpoints dns-test-service
```

### Lab 4: Network Policies

1. **Create test namespaces and applications**:

```bash
# Create namespaces
kubectl create namespace frontend
kubectl create namespace backend

# Deploy apps in different namespaces
kubectl apply -f - <<EOF
# Frontend app
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-app
  namespace: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: app
        image: busybox
        command: ['sh', '-c', 'while true; do sleep 30; done']
---
# Backend app
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-app
  namespace: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: app
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
  namespace: backend
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 80
EOF
```

2. **Test connectivity before network policies**:

```bash
# Test connection from frontend to backend
kubectl exec -n frontend deployment/frontend-app -- wget -qO- backend-service.backend.svc.cluster.local
```

3. **Apply restrictive network policy**:

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: backend
spec:
  podSelector: {}
  policyTypes:
  - Ingress
EOF
```

4. **Test connectivity after policy**:

```bash
# This should fail/timeout
kubectl exec -n frontend deployment/frontend-app -- timeout 10 wget -qO- backend-service.backend.svc.cluster.local
```

5. **Create allowing network policy**:

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: frontend
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
EOF

# Label the frontend namespace
kubectl label namespace frontend name=frontend
```

6. **Test connectivity after allowing policy**:

```bash
# This should work now
kubectl exec -n frontend deployment/frontend-app -- wget -qO- backend-service.backend.svc.cluster.local
```

## 💡 Best Practices

### 1. Service Design
- Use descriptive service names
- Choose appropriate service types
- Implement health checks
- Plan for service discovery

### 2. Network Security
- Implement Network Policies for micro-segmentation
- Use namespace isolation
- Secure ingress with TLS
- Monitor network traffic

### 3. Performance Optimization
- Use appropriate service types for your use case
- Implement proper load balancing
- Monitor network latency and throughput
- Optimize DNS resolution

### 4. Ingress Management
- Use path-based or host-based routing effectively
- Implement SSL/TLS termination
- Configure proper timeouts and limits
- Use rate limiting when appropriate

## 🔧 Troubleshooting Network Issues

### Common Problems and Solutions

#### 1. Service Not Accessible

**Problem**: Cannot reach service from Pod
**Diagnosis**:
```bash
kubectl get services
kubectl describe service <service-name>
kubectl get endpoints <service-name>
kubectl describe pod <pod-name>
```

**Solutions**:
- Check service selector matches Pod labels
- Verify target port matches container port
- Check if Pods are running and ready
- Test DNS resolution

#### 2. Ingress Not Working

**Problem**: Cannot access application via ingress
**Diagnosis**:
```bash
kubectl get ingress
kubectl describe ingress <ingress-name>
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

**Solutions**:
- Check ingress controller is running
- Verify ingress rules and backend services
- Check DNS resolution for hostnames
- Verify SSL/TLS configuration

#### 3. Network Policy Blocking Traffic

**Problem**: Pods cannot communicate after applying network policies
**Diagnosis**:
```bash
kubectl get networkpolicies
kubectl describe networkpolicy <policy-name>
kubectl get pods --show-labels
```

**Solutions**:
- Check network policy selectors
- Verify namespace and pod labels
- Test with temporary allow-all policy
- Check policy ordering and conflicts

### Network Diagnostic Commands

```bash
# Check service connectivity
kubectl get svc,endpoints
kubectl describe service <service-name>

# Test DNS resolution
kubectl run test-dns --image=busybox --rm -it -- nslookup <service-name>

# Check network policies
kubectl get networkpolicies --all-namespaces
kubectl describe networkpolicy <policy-name>

# Monitor ingress
kubectl get ingress --all-namespaces
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Check node network configuration
kubectl get nodes -o wide
kubectl describe node <node-name>
```

## 📝 Assessment Questions

1. **Multiple Choice**: Which service type exposes the service on each node's IP at a static port?
   - a) ClusterIP
   - b) NodePort
   - c) LoadBalancer
   - d) ExternalName

2. **Multiple Choice**: What is the default DNS domain for services in Kubernetes?
   - a) cluster.local
   - b) svc.cluster.local
   - c) default.svc.cluster.local
   - d) kubernetes.local

3. **Practical**: Create an ingress that routes traffic to different services based on the path (/api goes to api-service, /web goes to web-service).

4. **Scenario**: Design a network policy that allows only database pods to receive traffic from application pods in the same namespace, but blocks all other traffic.

## 🎯 Module Summary

You have learned:
- ✅ Kubernetes networking model and Pod communication
- ✅ Different service types and their use cases
- ✅ Ingress controllers and HTTP routing
- ✅ Network Policies for traffic control
- ✅ DNS and service discovery
- ✅ Network troubleshooting techniques
- ✅ Best practices for network security and performance

## 🔄 Next Steps

Ready for the next module? Continue to:
**[Module 7: Security](../07-security/README.md)**

## 📚 Additional Resources

- [Kubernetes Networking Concepts](https://kubernetes.io/docs/concepts/services-networking/)
- [Service Types Guide](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Ingress Controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

---

**💡 Pro Tip**: Always test your network configurations in a development environment and implement network policies gradually to avoid accidentally blocking legitimate traffic!
