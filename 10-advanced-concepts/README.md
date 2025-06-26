# Module 10: Advanced Concepts

## 📚 Learning Objectives

By the end of this module, you will understand:
- Custom Resource Definitions (CRDs) and Custom Resources
- Kubernetes Operators and operator patterns
- Admission Controllers and Webhooks
- Service Mesh concepts and implementation
- Advanced scheduling and node management
- Cluster administration and maintenance
- Performance optimization techniques
- Advanced troubleshooting methods

## 🎯 Prerequisites

- Completed Module 9: Package Management
- Strong understanding of core Kubernetes concepts
- Familiarity with Go programming language (optional but helpful)
- Knowledge of API concepts and RESTful services

## 📖 Theory: Advanced Kubernetes Concepts

### Custom Resource Definitions (CRDs)

CRDs allow you to extend Kubernetes with custom resources:

#### Benefits of CRDs
- **Extensibility**: Add domain-specific resources
- **API Consistency**: Use kubectl and Kubernetes APIs
- **Validation**: Built-in schema validation
- **Storage**: Automatic etcd storage and retrieval

#### CRD Structure
```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: databases.stable.example.com
spec:
  group: stable.example.com
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              size:
                type: string
              version:
                type: string
          status:
            type: object
  scope: Namespaced
  names:
    plural: databases
    singular: database
    kind: Database
```

### Kubernetes Operators

Operators are applications that extend Kubernetes functionality:

#### Operator Pattern
1. **Observe**: Watch for changes in custom resources
2. **Analyze**: Determine current vs desired state
3. **Act**: Take actions to reconcile state

#### Operator Framework Tools
- **Operator SDK**: Framework for building operators
- **Kubebuilder**: SDK for building Kubernetes APIs
- **KUDO**: Kubernetes Universal Declarative Operator

### Admission Controllers

Admission controllers intercept and modify API requests:

#### Types of Admission Controllers
- **Validating**: Validate requests before persistence
- **Mutating**: Modify requests before validation
- **Both**: Can validate and mutate

#### Admission Webhooks
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionWebhook
metadata:
  name: pod-validator
webhooks:
- name: validate-pods.example.com
  clientConfig:
    service:
      name: webhook-service
      namespace: default
      path: /validate
  rules:
  - operations: ["CREATE", "UPDATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
```

### Service Mesh

Service mesh provides communication infrastructure for microservices:

#### Key Features
- **Traffic Management**: Routing, load balancing, circuit breaking
- **Security**: mTLS, authentication, authorization
- **Observability**: Metrics, logs, traces
- **Policy**: Rate limiting, access control

#### Popular Service Mesh Solutions
- **Istio**: Feature-rich service mesh
- **Linkerd**: Lightweight and easy to use
- **Consul Connect**: HashiCorp's service mesh
- **AWS App Mesh**: Managed service mesh

## 🧪 Hands-on Labs

### Lab 1: Creating Custom Resource Definitions

1. **Create a simple CRD**:

```bash
kubectl apply -f - <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: webapps.stable.example.com
spec:
  group: stable.example.com
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              replicas:
                type: integer
                minimum: 1
                maximum: 10
              image:
                type: string
              port:
                type: integer
                minimum: 1
                maximum: 65535
            required:
            - image
            - port
          status:
            type: object
            properties:
              availableReplicas:
                type: integer
              conditions:
                type: array
                items:
                  type: object
                  properties:
                    type:
                      type: string
                    status:
                      type: string
                    lastUpdateTime:
                      type: string
                      format: date-time
    additionalPrinterColumns:
    - name: Replicas
      type: integer
      jsonPath: .spec.replicas
    - name: Available
      type: integer
      jsonPath: .status.availableReplicas
    - name: Age
      type: date
      jsonPath: .metadata.creationTimestamp
  scope: Namespaced
  names:
    plural: webapps
    singular: webapp
    kind: WebApp
    shortNames:
    - wa
EOF
```

2. **Create custom resources**:

```bash
# Create a WebApp resource
kubectl apply -f - <<EOF
apiVersion: stable.example.com/v1
kind: WebApp
metadata:
  name: my-webapp
spec:
  replicas: 3
  image: nginx:1.20
  port: 80
EOF

# List custom resources
kubectl get webapps
kubectl get wa

# Describe the custom resource
kubectl describe webapp my-webapp

# Get detailed output
kubectl get webapp my-webapp -o yaml
```

3. **Update custom resource status** (simulating a controller):

```bash
kubectl patch webapp my-webapp --type='merge' --subresource='status' -p='
{
  "status": {
    "availableReplicas": 3,
    "conditions": [
      {
        "type": "Available",
        "status": "True",
        "lastUpdateTime": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
      }
    ]
  }
}'

# Check updated status
kubectl get webapp my-webapp
```

### Lab 2: Building a Simple Operator

1. **Create a basic operator using shell script** (simulates controller logic):

```bash
# Create operator namespace
kubectl create namespace webapp-operator

# Create RBAC for the operator
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: webapp-operator
  namespace: webapp-operator
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: webapp-operator
rules:
- apiGroups: ["stable.example.com"]
  resources: ["webapps"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: webapp-operator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: webapp-operator
subjects:
- kind: ServiceAccount
  name: webapp-operator
  namespace: webapp-operator
EOF
```

2. **Create operator deployment**:

```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-operator
  namespace: webapp-operator
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp-operator
  template:
    metadata:
      labels:
        app: webapp-operator
    spec:
      serviceAccountName: webapp-operator
      containers:
      - name: operator
        image: bitnami/kubectl
        command:
        - /bin/bash
        - -c
        - |
          while true; do
            echo "Checking WebApp resources..."
            
            # Get all WebApp resources
            kubectl get webapps --all-namespaces -o json | jq -r '.items[] | "\(.metadata.namespace) \(.metadata.name) \(.spec.replicas) \(.spec.image) \(.spec.port)"' | while read namespace name replicas image port; do
              if [ ! -z "\$namespace" ]; then
                echo "Processing WebApp: \$namespace/\$name"
                
                # Create or update deployment
                kubectl apply -f - <<DEPLOY
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: \$name-deployment
            namespace: \$namespace
            ownerReferences:
            - apiVersion: stable.example.com/v1
              kind: WebApp
              name: \$name
              uid: \$(kubectl get webapp \$name -n \$namespace -o jsonpath='{.metadata.uid}')
          spec:
            replicas: \$replicas
            selector:
              matchLabels:
                app: \$name
            template:
              metadata:
                labels:
                  app: \$name
              spec:
                containers:
                - name: web
                  image: \$image
                  ports:
                  - containerPort: \$port
          DEPLOY
                
                # Create or update service
                kubectl apply -f - <<SERVICE
          apiVersion: v1
          kind: Service
          metadata:
            name: \$name-service
            namespace: \$namespace
            ownerReferences:
            - apiVersion: stable.example.com/v1
              kind: WebApp
              name: \$name
              uid: \$(kubectl get webapp \$name -n \$namespace -o jsonpath='{.metadata.uid}')
          spec:
            selector:
              app: \$name
            ports:
            - port: 80
              targetPort: \$port
          SERVICE
                
                # Update status
                available=\$(kubectl get deployment \$name-deployment -n \$namespace -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo 0)
                kubectl patch webapp \$name -n \$namespace --type='merge' --subresource='status' -p="{
                  \"status\": {
                    \"availableReplicas\": \$available,
                    \"conditions\": [{
                      \"type\": \"Available\",
                      \"status\": \"True\",
                      \"lastUpdateTime\": \"\$(date -u +\"%Y-%m-%dT%H:%M:%SZ\")\"
                    }]
                  }
                }" 2>/dev/null || true
              fi
            done
            
            sleep 30
          done
EOF
```

3. **Test the operator**:

```bash
# Create a WebApp in default namespace
kubectl apply -f - <<EOF
apiVersion: stable.example.com/v1
kind: WebApp
metadata:
  name: operator-test
spec:
  replicas: 2
  image: nginx:1.21
  port: 80
EOF

# Wait and check if operator created resources
sleep 60
kubectl get webapp operator-test
kubectl get deployment operator-test-deployment
kubectl get service operator-test-service

# Test scaling
kubectl patch webapp operator-test --type='merge' -p='{"spec":{"replicas":4}}'

# Wait and check scaling
sleep 60
kubectl get deployment operator-test-deployment
kubectl get webapp operator-test
```

### Lab 3: Admission Controllers

1. **Create a validating admission webhook**:

```bash
# Create webhook service
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pod-validator
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: pod-validator
  template:
    metadata:
      labels:
        app: pod-validator
    spec:
      containers:
      - name: webhook
        image: nginx
        ports:
        - containerPort: 8443
        volumeMounts:
        - name: webhook-config
          mountPath: /etc/nginx/conf.d/
      volumes:
      - name: webhook-config
        configMap:
          name: webhook-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: webhook-config
data:
  default.conf: |
    server {
        listen 8443 ssl;
        ssl_certificate /etc/ssl/certs/tls.crt;
        ssl_certificate_key /etc/ssl/private/tls.key;
        
        location /validate {
            add_header Content-Type application/json;
            return 200 '{"apiVersion": "admission.k8s.io/v1", "kind": "AdmissionResponse", "response": {"uid": "\$arg_uid", "allowed": true}}';
        }
    }
---
apiVersion: v1
kind: Service
metadata:
  name: pod-validator-service
spec:
  selector:
    app: pod-validator
  ports:
  - port: 443
    targetPort: 8443
EOF
```

2. **Create TLS certificates for webhook**:

```bash
# Generate certificates (simplified for demo)
openssl req -x509 -newkey rsa:2048 -keyout webhook.key -out webhook.crt -days 365 -nodes -subj "/CN=pod-validator-service.default.svc"

# Create secret with certificates
kubectl create secret tls webhook-certs --cert=webhook.crt --key=webhook.key

# Update deployment to use certificates
kubectl patch deployment pod-validator -p='
{
  "spec": {
    "template": {
      "spec": {
        "volumes": [
          {
            "name": "webhook-config",
            "configMap": {
              "name": "webhook-config"
            }
          },
          {
            "name": "webhook-certs",
            "secret": {
              "secretName": "webhook-certs"
            }
          }
        ],
        "containers": [
          {
            "name": "webhook",
            "volumeMounts": [
              {
                "name": "webhook-config",
                "mountPath": "/etc/nginx/conf.d/"
              },
              {
                "name": "webhook-certs",
                "mountPath": "/etc/ssl/certs/",
                "readOnly": true
              },
              {
                "name": "webhook-certs",
                "mountPath": "/etc/ssl/private/",
                "readOnly": true
              }
            ]
          }
        ]
      }
    }
  }
}'

# Clean up certificate files
rm webhook.key webhook.crt
```

### Lab 4: Advanced Scheduling

1. **Node affinity and anti-affinity**:

```bash
# Label nodes for scheduling
kubectl label nodes $(kubectl get nodes -o jsonpath='{.items[0].metadata.name}') disk-type=ssd
kubectl label nodes $(kubectl get nodes -o jsonpath='{.items[0].metadata.name}') zone=us-west-1a

# Create deployment with node affinity
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ssd-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ssd-app
  template:
    metadata:
      labels:
        app: ssd-app
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: disk-type
                operator: In
                values:
                - ssd
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1
            preference:
              matchExpressions:
              - key: zone
                operator: In
                values:
                - us-west-1a
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - ssd-app
              topologyKey: kubernetes.io/hostname
      containers:
      - name: app
        image: nginx
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
EOF
```

2. **Taints and tolerations**:

```bash
# Add taint to node
kubectl taint node $(kubectl get nodes -o jsonpath='{.items[0].metadata.name}') special=true:NoSchedule

# Create pod with toleration
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: toleration-pod
spec:
  tolerations:
  - key: "special"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
  containers:
  - name: app
    image: nginx
EOF

# Create pod without toleration (should not schedule)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: no-toleration-pod
spec:
  containers:
  - name: app
    image: nginx
EOF

# Check pod scheduling
kubectl get pods -o wide
kubectl describe pod no-toleration-pod

# Remove taint
kubectl taint node $(kubectl get nodes -o jsonpath='{.items[0].metadata.name}') special=true:NoSchedule-
```

3. **Pod disruption budgets**:

```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-app
spec:
  replicas: 4
  selector:
    matchLabels:
      app: critical-app
  template:
    metadata:
      labels:
        app: critical-app
    spec:
      containers:
      - name: app
        image: nginx
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: critical-app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: critical-app
EOF

# Check PDB status
kubectl get pdb
kubectl describe pdb critical-app-pdb
```

## 💡 Best Practices

### 1. Custom Resources and Operators
- Design clear and intuitive APIs
- Implement proper validation and defaults
- Use status subresources for status updates
- Implement proper error handling and retry logic
- Follow Kubernetes API conventions

### 2. Admission Controllers
- Keep webhook responses fast (< 10s timeout)
- Implement proper error handling
- Use mutating webhooks carefully
- Test thoroughly before production deployment
- Monitor webhook performance and availability

### 3. Advanced Scheduling
- Use node affinity for hardware requirements
- Implement pod anti-affinity for high availability
- Use taints and tolerations for dedicated nodes
- Configure appropriate pod disruption budgets
- Monitor resource utilization and scheduling efficiency

### 4. Performance Optimization
- Monitor API server performance
- Optimize etcd performance and backup strategies
- Use resource quotas and limit ranges
- Implement horizontal pod autoscaling
- Tune garbage collection and resource cleanup

## 🔧 Troubleshooting Advanced Features

### Common Problems and Solutions

#### 1. CRD and Operator Issues

**Problem**: Custom resources not being processed by operator
**Diagnosis**:
```bash
kubectl get crd
kubectl describe crd <crd-name>
kubectl logs -n <operator-namespace> deployment/<operator-name>
```

**Solutions**:
- Check CRD schema validation
- Verify operator RBAC permissions
- Check operator logs for errors
- Validate custom resource specifications

#### 2. Admission Controller Problems

**Problem**: Admission webhook causing API failures
**Diagnosis**:
```bash
kubectl get validatingadmissionwebhook
kubectl describe validatingadmissionwebhook <webhook-name>
kubectl get events --sort-by=.metadata.creationTimestamp
```

**Solutions**:
- Check webhook service availability
- Verify TLS certificates
- Review webhook timeout settings
- Test webhook endpoint manually

#### 3. Scheduling Issues

**Problem**: Pods not scheduling as expected
**Diagnosis**:
```bash
kubectl describe pod <pod-name>
kubectl get nodes --show-labels
kubectl describe node <node-name>
```

**Solutions**:
- Check node labels and taints
- Verify resource availability
- Review affinity and anti-affinity rules
- Check pod disruption budgets

### Advanced Troubleshooting Commands

```bash
# Check API server metrics
kubectl get --raw /metrics | grep apiserver

# Check etcd performance
kubectl get --raw /healthz/etcd

# Monitor resource usage
kubectl top nodes
kubectl top pods --all-namespaces --sort-by=cpu

# Check admission controllers
kubectl get admissionregistration.k8s.io/v1/validatingadmissionwebhooks
kubectl get admissionregistration.k8s.io/v1/mutatingadmissionwebhooks

# Analyze scheduling decisions
kubectl get events --field-selector reason=FailedScheduling
```

## 📝 Assessment Questions

1. **Multiple Choice**: What is the primary purpose of Custom Resource Definitions (CRDs)?
   - a) To replace built-in Kubernetes resources
   - b) To extend Kubernetes with domain-specific resources
   - c) To improve cluster performance
   - d) To provide better security

2. **Multiple Choice**: Which admission controller type can modify incoming requests?
   - a) Validating
   - b) Mutating
   - c) Static
   - d) Dynamic

3. **Practical**: Create a custom resource definition for a "Database" resource with appropriate validation, and build a simple operator that creates a StatefulSet when a Database resource is created.

4. **Scenario**: Design an advanced scheduling strategy for a multi-tier application that requires database pods on SSD nodes, web pods distributed across zones, and cache pods co-located with web pods.

## 🎯 Module Summary

You have learned:
- ✅ Custom Resource Definitions and custom resources
- ✅ Kubernetes Operators and the operator pattern
- ✅ Admission Controllers and webhook implementation
- ✅ Advanced scheduling with affinity and anti-affinity
- ✅ Taints, tolerations, and pod disruption budgets
- ✅ Service mesh concepts and implementation
- ✅ Performance optimization techniques
- ✅ Advanced troubleshooting methodologies
- ✅ Best practices for extending Kubernetes

## 🔄 Next Steps

Ready for the next module? Continue to:
**[Module 11: Real-World Projects](../11-real-world-projects/README.md)**

## 📚 Additional Resources

- [Kubernetes API Extension Documentation](https://kubernetes.io/docs/concepts/extend-kubernetes/)
- [Operator Pattern Guide](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)
- [Admission Controllers Reference](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)
- [Advanced Scheduling Guide](https://kubernetes.io/docs/concepts/scheduling-eviction/)

---

**🚀 Advanced Tip**: The true power of Kubernetes lies in its extensibility. Master these advanced concepts to build robust, scalable, and maintainable Kubernetes-native applications!
