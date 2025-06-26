# Module 7: Security in Kubernetes

## 📚 Learning Objectives

By the end of this module, you will understand:
- Kubernetes security architecture and threat model
- Role-Based Access Control (RBAC)
- Security Contexts and Pod Security Standards
- Secrets management and encryption
- Network security and policies
- Container image security
- Security scanning and compliance
- Best practices for cluster hardening

## 🎯 Prerequisites

- Completed Module 6: Networking
- Basic understanding of security concepts (authentication, authorization, encryption)
- Knowledge of Linux permissions and users

## 📖 Theory: Kubernetes Security

### Security Architecture

Kubernetes security operates on multiple layers:

1. **Cluster Security**: Node hardening, network security
2. **Authentication**: Who is making the request
3. **Authorization**: What the requester can do
4. **Admission Control**: Request validation and mutation
5. **Runtime Security**: Pod and container security
6. **Network Security**: Traffic encryption and isolation

### Authentication and Authorization

#### Authentication Methods
- X.509 certificates
- Bearer tokens
- Basic authentication (deprecated)
- OpenID Connect (OIDC)
- Service Account tokens

#### Authorization Modes
- **RBAC** (Role-Based Access Control) - Recommended
- **ABAC** (Attribute-Based Access Control)
- **Node Authorization**
- **Webhook Authorization**

### Role-Based Access Control (RBAC)

RBAC uses four main objects:

#### 1. Role and ClusterRole
Define permissions within a namespace (Role) or cluster-wide (ClusterRole):

```yaml
# Namespace-scoped Role
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: development
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "create", "update", "patch"]

---
# Cluster-scoped ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secret-reader
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
```

#### 2. RoleBinding and ClusterRoleBinding
Bind roles to users, groups, or service accounts:

```yaml
# RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: development
subjects:
- kind: User
  name: jane
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io

---
# ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-secrets-global
subjects:
- kind: User
  name: admin
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

### Service Accounts

Service Accounts provide identity for Pods:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-service-account
  namespace: default
secrets:
- name: my-service-account-token
---
apiVersion: v1
kind: Secret
metadata:
  name: my-service-account-token
  annotations:
    kubernetes.io/service-account.name: my-service-account
type: kubernetes.io/service-account-token
```

### Security Contexts

Security Contexts define security settings for Pods and containers:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
    fsGroupChangePolicy: "Always"
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: sec-ctx-demo
    image: busybox
    command: [ "sh", "-c", "sleep 1h" ]
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      capabilities:
        drop:
        - ALL
        add:
        - NET_BIND_SERVICE
```

### Pod Security Standards

Pod Security Standards replace Pod Security Policies:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: secure-namespace
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### Secrets Management

Kubernetes Secrets store sensitive data:

```yaml
# Opaque Secret
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque
data:
  username: YWRtaW4=  # base64 encoded
  password: MWYyZDFlMmU2N2Rm  # base64 encoded

---
# TLS Secret
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1CRUdJTi... # base64 encoded cert
  tls.key: LS0tLS1CRUdJTi... # base64 encoded key
```

## 🧪 Hands-on Labs

### Lab 1: RBAC Implementation

1. **Create a test namespace and service account**:

```bash
# Create namespace
kubectl create namespace rbac-test

# Create service account
kubectl create serviceaccount developer -n rbac-test
```

2. **Create a Role with specific permissions**:

```bash
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: rbac-test
  name: developer-role
rules:
- apiGroups: [""]
  resources: ["pods", "configmaps", "services"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
EOF
```

3. **Bind the Role to the service account**:

```bash
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: rbac-test
subjects:
- kind: ServiceAccount
  name: developer
  namespace: rbac-test
roleRef:
  kind: Role
  name: developer-role
  apiGroup: rbac.authorization.k8s.io
EOF
```

4. **Test RBAC permissions**:

```bash
# Create a Pod using the service account
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: rbac-test-pod
  namespace: rbac-test
spec:
  serviceAccountName: developer
  containers:
  - name: kubectl-container
    image: bitnami/kubectl
    command: ['sleep', '3600']
EOF

# Test permissions inside the Pod
kubectl exec -it rbac-test-pod -n rbac-test -- kubectl get pods -n rbac-test
kubectl exec -it rbac-test-pod -n rbac-test -- kubectl get secrets -n rbac-test
kubectl exec -it rbac-test-pod -n rbac-test -- kubectl get nodes

# Check what the service account can do
kubectl auth can-i get pods --as=system:serviceaccount:rbac-test:developer -n rbac-test
kubectl auth can-i delete secrets --as=system:serviceaccount:rbac-test:developer -n rbac-test
kubectl auth can-i get nodes --as=system:serviceaccount:rbac-test:developer
```

### Lab 2: Security Contexts and Pod Security

1. **Create a Pod with security context**:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: security-demo
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
  containers:
  - name: security-demo
    image: busybox
    command: [ "sh", "-c", "sleep 1h" ]
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      capabilities:
        drop:
        - ALL
    volumeMounts:
    - name: tmp-volume
      mountPath: /tmp
  volumes:
  - name: tmp-volume
    emptyDir: {}
EOF
```

2. **Test security context settings**:

```bash
# Check user and group
kubectl exec security-demo -- id

# Try to write to root filesystem (should fail)
kubectl exec security-demo -- touch /root-file 2>/dev/null && echo "FAIL: Can write to root" || echo "SUCCESS: Cannot write to root"

# Write to allowed location
kubectl exec security-demo -- touch /tmp/allowed-file && echo "SUCCESS: Can write to /tmp"

# Check process capabilities
kubectl exec security-demo -- grep Cap /proc/1/status
```

3. **Create a restricted Pod using Pod Security Standards**:

```bash
# Create a namespace with restricted Pod Security Standard
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: restricted-namespace
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
EOF

# Try to create a privileged Pod (should be rejected)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: privileged-pod
  namespace: restricted-namespace
spec:
  containers:
  - name: privileged-container
    image: nginx
    securityContext:
      privileged: true
EOF

# Create a compliant Pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: compliant-pod
  namespace: restricted-namespace
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: compliant-container
    image: nginx:1.20
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      capabilities:
        drop:
        - ALL
    volumeMounts:
    - name: tmp-volume
      mountPath: /tmp
    - name: cache-volume
      mountPath: /var/cache/nginx
    - name: run-volume
      mountPath: /var/run
  volumes:
  - name: tmp-volume
    emptyDir: {}
  - name: cache-volume
    emptyDir: {}
  - name: run-volume
    emptyDir: {}
EOF
```

### Lab 3: Secrets Management

1. **Create different types of secrets**:

```bash
# Create generic secret from literals
kubectl create secret generic app-secrets \
  --from-literal=username=admin \
  --from-literal=password=secretpassword

# Create secret from files
echo -n 'admin' > username.txt
echo -n 'secretpassword' > password.txt
kubectl create secret generic file-secrets \
  --from-file=username.txt \
  --from-file=password.txt

# Clean up files
rm username.txt password.txt

# Create TLS secret (self-signed for demo)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=example.com"

kubectl create secret tls tls-secret \
  --cert=tls.crt \
  --key=tls.key

# Clean up files
rm tls.key tls.crt
```

2. **Use secrets in Pods**:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: secret-demo
spec:
  containers:
  - name: secret-demo
    image: nginx
    env:
    - name: USERNAME
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: username
    - name: PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: password
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
    - name: tls-volume
      mountPath: /etc/tls
      readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: file-secrets
  - name: tls-volume
    secret:
      secretName: tls-secret
EOF
```

3. **Test secret access**:

```bash
# Check environment variables
kubectl exec secret-demo -- env | grep -E "(USERNAME|PASSWORD)"

# Check mounted secrets
kubectl exec secret-demo -- ls -la /etc/secrets
kubectl exec secret-demo -- cat /etc/secrets/username.txt
kubectl exec secret-demo -- ls -la /etc/tls
```

### Lab 4: Network Security with Network Policies

1. **Create test applications**:

```bash
# Create frontend, backend, and database
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
        tier: web
    spec:
      containers:
      - name: frontend
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
        tier: api
    spec:
      containers:
      - name: backend
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
        tier: db
    spec:
      containers:
      - name: database
        image: nginx
        ports:
        - containerPort: 80
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
---
apiVersion: v1
kind: Service
metadata:
  name: database-service
spec:
  selector:
    app: database
  ports:
  - port: 80
EOF
```

2. **Test connectivity before network policies**:

```bash
# Test from frontend to backend
kubectl exec deployment/frontend -- curl -s backend-service

# Test from frontend to database (should work but shouldn't in production)
kubectl exec deployment/frontend -- curl -s database-service
```

3. **Apply network policies for micro-segmentation**:

```bash
kubectl apply -f - <<EOF
# Deny all traffic by default
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
# Allow frontend to backend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
---
# Allow backend to database
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-database
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
          app: backend
    ports:
    - protocol: TCP
      port: 80
---
# Allow DNS for all pods
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to: []
    ports:
    - protocol: UDP
      port: 53
EOF
```

4. **Test connectivity after network policies**:

```bash
# Frontend to backend should work
kubectl exec deployment/frontend -- timeout 10 curl -s backend-service || echo "Connection failed/timeout"

# Frontend to database should fail
kubectl exec deployment/frontend -- timeout 5 curl -s database-service || echo "Connection blocked (expected)"

# Backend to database should work
kubectl exec deployment/backend -- timeout 10 curl -s database-service || echo "Connection failed/timeout"
```

## 💡 Best Practices

### 1. Authentication and Authorization
- Use service accounts instead of user accounts for applications
- Implement least privilege principle with RBAC
- Regularly audit and review permissions
- Use strong authentication methods

### 2. Container Security
- Use minimal base images
- Run containers as non-root users
- Implement read-only root filesystems
- Drop unnecessary capabilities
- Use security contexts consistently

### 3. Secrets Management
- Never store secrets in container images
- Use Kubernetes secrets for sensitive data
- Encrypt secrets at rest
- Rotate secrets regularly
- Limit secret access with RBAC

### 4. Network Security
- Implement network policies for micro-segmentation
- Use TLS for all communications
- Secure ingress with proper authentication
- Monitor network traffic

### 5. Cluster Hardening
- Keep Kubernetes and nodes updated
- Secure the etcd cluster
- Use Pod Security Standards
- Implement admission controllers
- Regular security audits

## 🔧 Troubleshooting Security Issues

### Common Security Problems

#### 1. RBAC Permission Denied

**Problem**: User or service account cannot perform actions
**Diagnosis**:
```bash
kubectl auth can-i <verb> <resource> --as=<user/service-account>
kubectl describe rolebinding <binding-name>
kubectl describe clusterrolebinding <binding-name>
```

**Solutions**:
- Check role and binding configurations
- Verify subject names and namespaces
- Test with broader permissions first

#### 2. Pod Security Policy Violations

**Problem**: Pods rejected due to security policies
**Diagnosis**:
```bash
kubectl describe pod <pod-name>
kubectl get events --sort-by=.metadata.creationTimestamp
```

**Solutions**:
- Review Pod Security Standards requirements
- Update security contexts
- Check namespace labels and policies

#### 3. Network Policy Blocking Traffic

**Problem**: Pods cannot communicate due to network policies
**Diagnosis**:
```bash
kubectl get networkpolicies
kubectl describe networkpolicy <policy-name>
```

**Solutions**:
- Temporarily remove policies to test
- Check label selectors
- Ensure DNS traffic is allowed

### Security Audit Commands

```bash
# Check RBAC permissions
kubectl auth can-i --list --as=<user>
kubectl get rolebindings,clusterrolebindings --all-namespaces

# Review security contexts
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.securityContext}{"\n"}{end}'

# Check secrets
kubectl get secrets --all-namespaces
kubectl describe secret <secret-name>

# Review network policies
kubectl get networkpolicies --all-namespaces
```

## 📝 Assessment Questions

1. **Multiple Choice**: Which RBAC object defines permissions within a specific namespace?
   - a) ClusterRole
   - b) Role
   - c) RoleBinding
   - d) ClusterRoleBinding

2. **Multiple Choice**: What should you set to run a container as a non-root user?
   - a) runAsUser: 0
   - b) runAsNonRoot: true
   - c) privileged: false
   - d) readOnlyRootFilesystem: true

3. **Practical**: Create an RBAC setup where a service account can only read pods and configmaps in a specific namespace but cannot delete them.

4. **Scenario**: Design a security setup for a three-tier application (frontend, backend, database) with appropriate network policies, RBAC, and security contexts.

## 🎯 Module Summary

You have learned:
- ✅ Kubernetes security architecture and principles
- ✅ RBAC implementation and best practices
- ✅ Security contexts and Pod Security Standards
- ✅ Secrets management and encryption
- ✅ Network security with Network Policies
- ✅ Container and cluster hardening techniques
- ✅ Security troubleshooting and auditing
- ✅ Compliance and governance practices

## 🔄 Next Steps

Ready for the next module? Continue to:
**[Module 8: Monitoring and Logging](../08-monitoring-logging/README.md)**

## 📚 Additional Resources

- [Kubernetes Security Documentation](https://kubernetes.io/docs/concepts/security/)
- [RBAC Guide](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)

---

**🔒 Security Reminder**: Security is an ongoing process. Regularly update your knowledge, audit your configurations, and stay informed about security best practices and vulnerabilities!
