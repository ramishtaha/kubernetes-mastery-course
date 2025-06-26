# Module 02: Kubernetes Basics and Fundamental Concepts

This module covers the core concepts and fundamental building blocks of Kubernetes. You'll learn about the API, objects, namespaces, and resource management.

## 📚 Learning Objectives

By the end of this module, you will:
- Understand the Kubernetes API and object model
- Master namespaces and resource organization
- Use labels and selectors effectively
- Manage resources with quotas and limits
- Work with annotations and metadata
- Navigate the kubectl command-line interface

## 📋 Module Outline

1. [Kubernetes API and Objects](#1-kubernetes-api-and-objects)
2. [Namespaces and Resource Organization](#2-namespaces-and-resource-organization)
3. [Labels and Selectors](#3-labels-and-selectors)
4. [Annotations and Metadata](#4-annotations-and-metadata)
5. [Resource Quotas and Limits](#5-resource-quotas-and-limits)
6. [kubectl Mastery](#6-kubectl-mastery)
7. [Hands-on Labs](#7-hands-on-labs)
8. [Assessment](#8-assessment)

---

## 1. Kubernetes API and Objects

### Understanding the Kubernetes API

The Kubernetes API is the foundation of everything in Kubernetes. It's a RESTful API that:
- Accepts and responds to HTTP requests
- Stores objects in etcd
- Validates object specifications
- Manages object lifecycle

### API Structure

```
https://kubernetes-api-server:6443/api/v1/namespaces/default/pods
         │                          │    │   │          │     │
         └─ API Server              │    │   │          │     └─ Resource
                                   │    │   │          └─ Namespace
                                   │    │   └─ API Group
                                   │    └─ Version
                                   └─ Base Path
```

### Kubernetes Objects

Every entity in Kubernetes is an object with:

1. **Object Metadata**: Basic information about the object
2. **Object Spec**: Desired state specified by the user
3. **Object Status**: Current state observed by the system

### Basic Object Structure

```yaml
apiVersion: v1              # API version
kind: Pod                   # Object type
metadata:                   # Object metadata
  name: my-pod
  namespace: default
  labels:
    app: my-app
  annotations:
    description: "Example pod"
spec:                       # Desired state
  containers:
  - name: web
    image: nginx:latest
    ports:
    - containerPort: 80
status:                     # Current state (managed by Kubernetes)
  phase: Running
  conditions:
  - type: Ready
    status: "True"
```

### API Groups and Versions

Kubernetes organizes APIs into groups:

| API Group | Version | Resources | Example |
|-----------|---------|-----------|---------|
| Core (legacy) | v1 | pods, services, configmaps | /api/v1/pods |
| apps | v1 | deployments, replicasets | /apis/apps/v1/deployments |
| batch | v1 | jobs, cronjobs | /apis/batch/v1/jobs |
| networking.k8s.io | v1 | networkpolicies | /apis/networking.k8s.io/v1/networkpolicies |

### Exploring the API

```bash
# List all API resources
kubectl api-resources

# Get specific API versions
kubectl api-versions

# Explain a resource
kubectl explain pod
kubectl explain pod.spec
kubectl explain pod.spec.containers

# Get API server info
kubectl cluster-info
kubectl get --raw /api/v1 | jq
```

### Object Names and UIDs

Every Kubernetes object has:
- **Name**: Human-readable identifier (unique within namespace)
- **UID**: System-generated unique identifier (cluster-wide)
- **Resource Version**: Version number for optimistic concurrency

```bash
# View object metadata
kubectl get pod <pod-name> -o yaml | head -20
```

---

## 2. Namespaces and Resource Organization

### What are Namespaces?

Namespaces provide:
- **Scope**: Logical separation of resources
- **Organization**: Group related resources
- **Security**: Isolation and access control
- **Resource Management**: Quotas and limits per namespace

### Default Namespaces

```bash
# List all namespaces
kubectl get namespaces

# Default namespaces in a new cluster:
# - default: Default namespace for user objects
# - kube-system: System components
# - kube-public: Publicly readable by all users
# - kube-node-lease: Node heartbeat objects
```

### Creating and Managing Namespaces

#### Using kubectl

```bash
# Create namespace
kubectl create namespace my-namespace

# Delete namespace (and all objects in it)
kubectl delete namespace my-namespace

# Set default namespace for current context
kubectl config set-context --current --namespace=my-namespace

# View current namespace
kubectl config view --minify | grep namespace
```

#### Using YAML

```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: development
  labels:
    purpose: development
    team: backend
  annotations:
    description: "Development environment for backend team"
---
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    purpose: production
    team: backend
```

Apply the namespace configuration:

```bash
kubectl apply -f namespace.yaml
```

### Namespace Best Practices

#### 1. Naming Conventions

```bash
# Environment-based
- development
- staging
- production

# Team-based
- team-frontend
- team-backend
- team-devops

# Application-based
- app-webstore
- app-analytics
- app-monitoring

# Feature-based (for development)
- feature-user-auth
- feature-payment
- feature-reporting
```

#### 2. Resource Organization

```yaml
# Example: Web application with database
apiVersion: v1
kind: Namespace
metadata:
  name: webstore-prod
  labels:
    app: webstore
    environment: production
    team: ecommerce
---
# All webstore production resources go in this namespace
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: webstore-prod
# ... spec
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: webstore-prod
# ... spec
```

### Working Across Namespaces

```bash
# List resources in specific namespace
kubectl get pods -n kube-system

# List resources in all namespaces
kubectl get pods --all-namespaces
kubectl get pods -A  # Short form

# Create resource in specific namespace
kubectl run nginx --image=nginx -n development

# Access services across namespaces
# Format: service-name.namespace.svc.cluster.local
# Example: database.production.svc.cluster.local
```

---

## 3. Labels and Selectors

### Understanding Labels

Labels are key-value pairs attached to objects for:
- **Identification**: Categorize and organize objects
- **Selection**: Query and filter objects
- **Grouping**: Logical grouping for operations

### Label Syntax and Rules

```yaml
# Valid label examples
metadata:
  labels:
    app: web-server
    version: "1.2.3"
    environment: production
    tier: frontend
    team: backend
    release: stable
    cost-center: marketing
    "app.kubernetes.io/name": nginx
    "app.kubernetes.io/version": "1.21"
```

### Label Rules:
- **Key**: Up to 253 characters (prefix/name format)
- **Value**: Up to 63 characters
- **Characters**: Alphanumeric, '-', '_', '.'
- **Case**: Sensitive

### Common Label Patterns

#### 1. Application Labels (Recommended)

```yaml
metadata:
  labels:
    app.kubernetes.io/name: wordpress
    app.kubernetes.io/instance: wordpress-abcxyz
    app.kubernetes.io/version: "4.9.8"
    app.kubernetes.io/component: database
    app.kubernetes.io/part-of: wordpress
    app.kubernetes.io/managed-by: helm
```

#### 2. Environment and Release Labels

```yaml
metadata:
  labels:
    environment: production
    release: stable
    version: "v1.2.3"
    tier: frontend
```

#### 3. Organizational Labels

```yaml
metadata:
  labels:
    team: backend
    project: ecommerce
    cost-center: engineering
    owner: john-doe
```

### Selectors

Selectors allow you to query objects based on labels:

#### 1. Equality-based Selectors

```bash
# Select pods with exact label match
kubectl get pods -l app=nginx
kubectl get pods -l environment=production

# Multiple labels (AND operation)
kubectl get pods -l app=nginx,environment=production

# Exclude labels
kubectl get pods -l app!=nginx
```

#### 2. Set-based Selectors

```bash
# Select pods where environment is in the set
kubectl get pods -l 'environment in (production,staging)'

# Select pods where environment is not in the set
kubectl get pods -l 'environment notin (development)'

# Select pods that have the tier label
kubectl get pods -l 'tier'

# Select pods that don't have the tier label
kubectl get pods -l '!tier'
```

#### 3. Selectors in YAML

```yaml
# Deployment selector
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
      tier: frontend
  # OR using matchExpressions
  selector:
    matchExpressions:
    - key: app
      operator: In
      values: [nginx]
    - key: tier
      operator: NotIn
      values: [backend]
```

### Label Management

```bash
# Add label to existing resource
kubectl label pod nginx-pod environment=production

# Update existing label
kubectl label pod nginx-pod environment=staging --overwrite

# Remove label
kubectl label pod nginx-pod environment-

# View labels
kubectl get pods --show-labels
kubectl get pods -L app,environment
```

### Practical Examples

#### Example 1: Multi-tier Application Labeling

```yaml
# Frontend Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  labels:
    app: ecommerce
    tier: frontend
    component: web
spec:
  selector:
    matchLabels:
      app: ecommerce
      tier: frontend
  template:
    metadata:
      labels:
        app: ecommerce
        tier: frontend
        component: web
        version: "1.0"
    spec:
      containers:
      - name: web
        image: nginx:latest

---
# Backend Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  labels:
    app: ecommerce
    tier: backend
    component: api
spec:
  selector:
    matchLabels:
      app: ecommerce
      tier: backend
  template:
    metadata:
      labels:
        app: ecommerce
        tier: backend
        component: api
        version: "2.1"
    spec:
      containers:
      - name: api
        image: node:16

---
# Database Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  labels:
    app: ecommerce
    tier: database
    component: mysql
spec:
  selector:
    matchLabels:
      app: ecommerce
      tier: database
  template:
    metadata:
      labels:
        app: ecommerce
        tier: database
        component: mysql
        version: "8.0"
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
```

Query examples:

```bash
# Get all ecommerce application components
kubectl get pods -l app=ecommerce

# Get only frontend components
kubectl get pods -l app=ecommerce,tier=frontend

# Get all components except database
kubectl get pods -l 'app=ecommerce,tier!=database'

# Get all backend and database components
kubectl get pods -l 'app=ecommerce,tier in (backend,database)'
```

---

## 4. Annotations and Metadata

### Understanding Annotations

Annotations are key-value pairs that store **non-identifying metadata**:
- **Purpose**: Store additional information about objects
- **Usage**: Tools, libraries, and integrations
- **Difference from Labels**: Not used for selection

### When to Use Annotations vs Labels

| Use Labels For | Use Annotations For |
|----------------|-------------------|
| Selecting/querying objects | Storing metadata |
| Organizing resources | Tool-specific data |
| Service selectors | Build information |
| Replica set matching | Contact information |

### Common Annotation Patterns

```yaml
metadata:
  annotations:
    # Build and deployment info
    build.version: "1.2.3-abc123"
    build.timestamp: "2023-12-01T10:30:00Z"
    build.user: "jenkins"
    
    # Contact and ownership
    contact.email: "team@company.com"
    contact.slack: "#backend-team"
    owner: "backend-team"
    
    # Tool-specific annotations
    kubernetes.io/change-cause: "Update nginx to version 1.21"
    deployment.kubernetes.io/revision: "3"
    
    # Documentation
    description: "Frontend web server for ecommerce application"
    documentation: "https://wiki.company.com/frontend"
    
    # Ingress controller specific
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    
    # Monitoring and alerting
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"
```

### Managing Annotations

```bash
# Add annotation
kubectl annotate pod nginx-pod contact.email="admin@company.com"

# Update annotation
kubectl annotate pod nginx-pod contact.email="newadmin@company.com" --overwrite

# Remove annotation
kubectl annotate pod nginx-pod contact.email-

# View annotations
kubectl get pod nginx-pod -o yaml | grep -A 10 annotations
kubectl describe pod nginx-pod | grep -A 5 Annotations
```

### Practical Example: Comprehensive Metadata

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-frontend
  namespace: production
  labels:
    # Labels for selection and organization
    app: ecommerce
    component: frontend
    tier: web
    environment: production
    version: "1.2.3"
  annotations:
    # Annotations for metadata and tools
    description: "Frontend web server for ecommerce platform"
    contact.team: "frontend-team"
    contact.email: "frontend@company.com"
    contact.slack: "#frontend-alerts"
    documentation: "https://wiki.company.com/ecommerce/frontend"
    build.version: "1.2.3"
    build.commit: "abc123def456"
    build.timestamp: "2023-12-01T10:30:00Z"
    build.pipeline: "https://jenkins.company.com/job/frontend/123"
    deployment.kubernetes.io/revision: "5"
    kubernetes.io/change-cause: "Update to version 1.2.3 with bug fixes"
    monitoring.prometheus.io/scrape: "true"
    monitoring.prometheus.io/port: "8080"
    monitoring.prometheus.io/path: "/metrics"
spec:
  selector:
    matchLabels:
      app: ecommerce
      component: frontend
      tier: web
  template:
    metadata:
      labels:
        app: ecommerce
        component: frontend
        tier: web
        version: "1.2.3"
      annotations:
        config.hash: "sha256:abc123..."  # For triggering updates
    spec:
      containers:
      - name: web
        image: company/frontend:1.2.3
        ports:
        - containerPort: 8080
```

---

## 5. Resource Quotas and Limits

### Understanding Resource Management

Kubernetes provides several mechanisms for resource management:
- **Resource Quotas**: Limit resource consumption per namespace
- **Limit Ranges**: Set default and maximum resource limits
- **Resource Requests**: Guaranteed resources for containers
- **Resource Limits**: Maximum resources containers can use

### Resource Types

#### 1. Compute Resources
```yaml
resources:
  requests:
    cpu: "100m"      # 100 millicores (0.1 CPU)
    memory: "128Mi"   # 128 Mebibytes
  limits:
    cpu: "500m"      # 500 millicores (0.5 CPU)
    memory: "256Mi"   # 256 Mebibytes
```

#### 2. Storage Resources
```yaml
resources:
  requests:
    storage: "1Gi"   # 1 Gibibyte
```

#### 3. Object Count Resources
- pods
- services
- secrets
- configmaps
- persistentvolumeclaims

### CPU Resource Units

```bash
# CPU can be specified in:
100m    # 100 millicores = 0.1 CPU
0.1     # 0.1 CPU cores
1       # 1 CPU core
2       # 2 CPU cores
```

### Memory Resource Units

```bash
# Memory can be specified in:
128Mi   # 128 * 1024 * 1024 bytes
256M    # 256 * 1000 * 1000 bytes
1Gi     # 1 * 1024 * 1024 * 1024 bytes
1G      # 1 * 1000 * 1000 * 1000 bytes
```

### Resource Quotas

Create a resource quota for a namespace:

```yaml
# resource-quota.yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: development
spec:
  hard:
    # Compute resources
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    
    # Storage resources
    requests.storage: 100Gi
    persistentvolumeclaims: "10"
    
    # Object count
    pods: "20"
    services: "10"
    secrets: "20"
    configmaps: "20"
    replicationcontrollers: "10"
```

Apply and check resource quota:

```bash
# Apply quota
kubectl apply -f resource-quota.yaml

# View quota
kubectl get resourcequota -n development
kubectl describe resourcequota compute-quota -n development
```

### Limit Ranges

Set default resource limits for objects in a namespace:

```yaml
# limit-range.yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: cpu-mem-limit-range
  namespace: development
spec:
  limits:
  - default:           # Default limits
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:    # Default requests
      cpu: "100m"
      memory: "128Mi"
    max:              # Maximum limits
      cpu: "2"
      memory: "2Gi"
    min:              # Minimum requests
      cpu: "50m"
      memory: "64Mi"
    type: Container
  - max:              # Maximum for pods
      cpu: "4"
      memory: "4Gi"
    type: Pod
```

Apply and verify:

```bash
kubectl apply -f limit-range.yaml
kubectl get limitrange -n development
kubectl describe limitrange cpu-mem-limit-range -n development
```

### Container Resource Specifications

```yaml
# deployment-with-resources.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resource-demo
  namespace: development
spec:
  replicas: 3
  selector:
    matchLabels:
      app: resource-demo
  template:
    metadata:
      labels:
        app: resource-demo
    spec:
      containers:
      - name: web
        image: nginx:latest
        ports:
        - containerPort: 80
        resources:
          requests:           # Guaranteed resources
            cpu: "100m"
            memory: "128Mi"
          limits:            # Maximum resources
            cpu: "500m"
            memory: "256Mi"
      - name: sidecar
        image: busybox
        command: ['sleep', '3600']
        resources:
          requests:
            cpu: "50m"
            memory: "64Mi"
          limits:
            cpu: "100m"
            memory: "128Mi"
```

### Monitoring Resource Usage

```bash
# View resource usage by nodes
kubectl top nodes

# View resource usage by pods
kubectl top pods
kubectl top pods -n development

# View resource usage for specific pod
kubectl top pod <pod-name>

# Detailed resource information
kubectl describe node <node-name>
kubectl describe pod <pod-name>
```

---

## 6. kubectl Mastery

### Essential kubectl Commands

#### 1. Cluster Information
```bash
# Cluster info
kubectl cluster-info
kubectl cluster-info dump

# Version information
kubectl version
kubectl version --short

# API resources
kubectl api-resources
kubectl api-versions
```

#### 2. Resource Management
```bash
# Get resources
kubectl get pods
kubectl get pods -o wide
kubectl get pods -o yaml
kubectl get pods -o json

# Describe resources
kubectl describe pod <pod-name>
kubectl describe node <node-name>

# Create resources
kubectl create deployment nginx --image=nginx
kubectl run nginx --image=nginx
kubectl apply -f manifest.yaml

# Delete resources
kubectl delete pod <pod-name>
kubectl delete deployment <deployment-name>
kubectl delete -f manifest.yaml
```

#### 3. Advanced Querying
```bash
# Use selectors
kubectl get pods -l app=nginx
kubectl get pods -l 'environment in (production,staging)'

# Multiple resources
kubectl get pods,services,deployments

# All namespaces
kubectl get pods --all-namespaces
kubectl get pods -A

# Watch for changes
kubectl get pods --watch
kubectl get pods -w
```

#### 4. Output Formatting
```bash
# Different output formats
kubectl get pods -o wide
kubectl get pods -o yaml
kubectl get pods -o json
kubectl get pods -o name

# Custom columns
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase
kubectl get pods -o custom-columns-file=columns.txt

# JSONPath
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}'
```

#### 5. Resource Editing
```bash
# Edit resources
kubectl edit pod <pod-name>
kubectl edit deployment <deployment-name>

# Patch resources
kubectl patch deployment nginx -p '{"spec":{"replicas":5}}'

# Scale resources
kubectl scale deployment nginx --replicas=10

# Rollout management
kubectl rollout status deployment/nginx
kubectl rollout history deployment/nginx
kubectl rollout undo deployment/nginx
```

### kubectl Configuration

#### 1. Context Management
```bash
# View contexts
kubectl config get-contexts
kubectl config current-context

# Switch context
kubectl config use-context <context-name>

# Set namespace for context
kubectl config set-context --current --namespace=development

# Create new context
kubectl config set-context dev-context --cluster=cluster --user=dev-user --namespace=development
```

#### 2. Multiple Cluster Management
```bash
# View cluster info
kubectl config view

# Get cluster information
kubectl cluster-info --context=<context-name>

# Use specific kubeconfig file
kubectl --kubeconfig=~/.kube/config-dev get pods
```

### Useful kubectl Aliases and Functions

Add these to your `~/.bashrc`:

```bash
# Basic aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete'
alias klog='kubectl logs'
alias kexec='kubectl exec -it'
alias kdesc='kubectl describe'

# Advanced aliases
alias kgpw='kubectl get pods -o wide'
alias kgpa='kubectl get pods --all-namespaces'
alias kgsw='kubectl get services -o wide'
alias kgdw='kubectl get deployments -o wide'

# Functions
kpf() {
    kubectl port-forward "$1" "$2"
}

klogs() {
    kubectl logs -f "$1"
}

kshell() {
    kubectl exec -it "$1" -- /bin/bash
}
```

---

## 7. Hands-on Labs

### Lab 1: Namespace and Resource Organization

**Objective**: Create a multi-namespace environment with proper organization

```bash
# Create namespaces for different environments
kubectl create namespace development
kubectl create namespace staging
kubectl create namespace production

# Label namespaces
kubectl label namespace development environment=dev
kubectl label namespace staging environment=staging
kubectl label namespace production environment=prod

# Create a development application
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: development
  labels:
    app: web-app
    environment: development
    tier: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
        environment: development
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80

---
apiVersion: v1
kind: Service
metadata:
  name: web-app-service
  namespace: development
spec:
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

# Verify deployment
kubectl get all -n development
kubectl get pods -n development --show-labels
```

### Lab 2: Label Management and Selectors

**Objective**: Practice advanced labeling and selection

```bash
# Deploy multiple applications with different labels
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-v1
  labels:
    app: ecommerce
    component: frontend
    version: v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ecommerce
      component: frontend
      version: v1
  template:
    metadata:
      labels:
        app: ecommerce
        component: frontend
        version: v1
        tier: web
    spec:
      containers:
      - name: web
        image: nginx:1.20

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-v2
  labels:
    app: ecommerce
    component: frontend
    version: v2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ecommerce
      component: frontend
      version: v2
  template:
    metadata:
      labels:
        app: ecommerce
        component: frontend
        version: v2
        tier: web
    spec:
      containers:
      - name: web
        image: nginx:1.21

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  labels:
    app: ecommerce
    component: backend
    version: v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ecommerce
      component: backend
  template:
    metadata:
      labels:
        app: ecommerce
        component: backend
        version: v1
        tier: api
    spec:
      containers:
      - name: api
        image: node:16
        command: ['sleep', '3600']
EOF

# Practice label queries
echo "=== All ecommerce components ==="
kubectl get pods -l app=ecommerce

echo "=== Frontend components only ==="
kubectl get pods -l app=ecommerce,component=frontend

echo "=== Version 1 components ==="
kubectl get pods -l app=ecommerce,version=v1

echo "=== Frontend v2 only ==="
kubectl get pods -l app=ecommerce,component=frontend,version=v2

echo "=== All components except backend ==="
kubectl get pods -l 'app=ecommerce,component!=backend'

echo "=== Web tier components ==="
kubectl get pods -l tier=web

# Add runtime labels
kubectl label pods -l app=ecommerce environment=production
kubectl label pods -l component=frontend release=stable

# View updated labels
kubectl get pods --show-labels
```

### Lab 3: Resource Quotas and Limits

**Objective**: Configure resource management for a namespace

```bash
# Create a new namespace for testing
kubectl create namespace resource-test

# Apply resource quota
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: resource-test-quota
  namespace: resource-test
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 2Gi
    limits.cpu: "4"
    limits.memory: 4Gi
    pods: "10"
    services: "5"

---
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-test-limits
  namespace: resource-test
spec:
  limits:
  - default:
      cpu: "200m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    max:
      cpu: "1"
      memory: "1Gi"
    min:
      cpu: "50m"
      memory: "64Mi"
    type: Container
EOF

# Check quotas and limits
kubectl get resourcequota -n resource-test
kubectl get limitrange -n resource-test
kubectl describe resourcequota resource-test-quota -n resource-test

# Deploy application within limits
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: quota-test
  namespace: resource-test
spec:
  replicas: 3
  selector:
    matchLabels:
      app: quota-test
  template:
    metadata:
      labels:
        app: quota-test
    spec:
      containers:
      - name: web
        image: nginx:latest
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
EOF

# Monitor resource usage
kubectl get pods -n resource-test
kubectl top pods -n resource-test
kubectl describe resourcequota resource-test-quota -n resource-test

# Try to exceed quota (this should fail)
kubectl scale deployment quota-test --replicas=15 -n resource-test
kubectl get events -n resource-test | grep quota
```

### Lab 4: Advanced kubectl Usage

**Objective**: Master advanced kubectl commands and techniques

```bash
# Create sample resources for testing
kubectl create deployment test-deploy --image=nginx --replicas=3
kubectl expose deployment test-deploy --port=80

# Advanced output formatting
echo "=== Custom columns ==="
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName

echo "=== JSONPath queries ==="
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.podIP}{"\n"}{end}'

echo "=== Resource usage ==="
kubectl top pods --sort-by=memory
kubectl top nodes --sort-by=cpu

# Watch resources
echo "=== Watching for changes (Ctrl+C to stop) ==="
kubectl get pods --watch &
WATCH_PID=$!

# Make changes in another terminal
kubectl scale deployment test-deploy --replicas=5
sleep 5
kubectl scale deployment test-deploy --replicas=1

# Stop watching
kill $WATCH_PID

# Resource management
echo "=== Resource editing ==="
kubectl patch deployment test-deploy -p '{"spec":{"replicas":2}}'

echo "=== Rollout management ==="
kubectl rollout status deployment/test-deploy
kubectl rollout history deployment/test-deploy

# Event monitoring
kubectl get events --sort-by='.lastTimestamp' | head -10

# Cleanup
kubectl delete deployment test-deploy
kubectl delete service test-deploy
```

---

## 8. Assessment

### Knowledge Check Questions

1. **API Objects**: What are the three main components of every Kubernetes object?

2. **Namespaces**: When would you use namespaces vs labels for organizing resources?

3. **Labels vs Annotations**: Give three examples each of data that should be stored in labels vs annotations.

4. **Resource Quotas**: What happens when a pod exceeds the resource limits defined in a namespace?

5. **Selectors**: Write a selector query to find all pods that:
   - Have the label `app=web`
   - Are in either `production` or `staging` environment
   - Do not have the `deprecated` label

### Practical Exercises

#### Exercise 1: Multi-Environment Setup
Create a complete multi-environment setup with:
- Three namespaces (dev, staging, prod)
- Different resource quotas for each environment
- Sample applications deployed to each environment
- Proper labeling and organization

#### Exercise 2: Label Strategy Implementation
Design and implement a comprehensive labeling strategy for:
- A three-tier web application (frontend, backend, database)
- Multiple environments and versions
- Team ownership and contact information
- Cost tracking and reporting

#### Exercise 3: Resource Management
Set up resource management for a development team:
- Create namespace with appropriate quotas
- Configure limit ranges with sensible defaults
- Deploy applications that test the limits
- Monitor and optimize resource usage

### Hands-on Project: Complete Application Deployment

Deploy a complete e-commerce application with proper organization:

```yaml
# Save as: ecommerce-complete.yaml
# Namespace
apiVersion: v1
kind: Namespace
metadata:
  name: ecommerce-prod
  labels:
    environment: production
    project: ecommerce
    team: platform
  annotations:
    contact.email: "platform@company.com"
    contact.slack: "#platform-team"
    description: "Production environment for ecommerce platform"

---
# Resource Quota
apiVersion: v1
kind: ResourceQuota
metadata:
  name: ecommerce-quota
  namespace: ecommerce-prod
spec:
  hard:
    requests.cpu: "8"
    requests.memory: 16Gi
    limits.cpu: "16"
    limits.memory: 32Gi
    pods: "50"
    services: "20"

---
# Frontend Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: ecommerce-prod
  labels:
    app: ecommerce
    component: frontend
    tier: web
    version: "1.2.3"
  annotations:
    contact.team: "frontend-team"
    build.version: "1.2.3"
    deployment.kubernetes.io/revision: "5"
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ecommerce
      component: frontend
  template:
    metadata:
      labels:
        app: ecommerce
        component: frontend
        tier: web
        version: "1.2.3"
    spec:
      containers:
      - name: web
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "256Mi"

# Continue with backend and database deployments...
```

Test the deployment:

```bash
kubectl apply -f ecommerce-complete.yaml
kubectl get all -n ecommerce-prod
kubectl describe resourcequota ecommerce-quota -n ecommerce-prod
```

### Assessment Rubric

| Skill Area | Beginner | Intermediate | Advanced |
|------------|----------|--------------|----------|
| **API Understanding** | Basic object structure | Object relationships | API extensions |
| **Namespaces** | Basic usage | Multi-env organization | Enterprise patterns |
| **Labels/Selectors** | Simple labels | Complex queries | Strategic labeling |
| **Resource Management** | Basic limits | Quota management | Optimization |
| **kubectl Mastery** | Basic commands | Advanced querying | Automation |

---

## 📚 Additional Resources

### Official Documentation
- [Kubernetes API Overview](https://kubernetes.io/docs/concepts/overview/kubernetes-api/)
- [Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
- [Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)

### Best Practices
- [Kubernetes Recommended Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/)
- [Resource Management Best Practices](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

### Tools and Utilities
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [kubectl Plugins](https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/)

---

## ✅ Module Completion Checklist

- [ ] Understand Kubernetes API and object model
- [ ] Master namespace organization and management
- [ ] Implement effective labeling strategies
- [ ] Configure resource quotas and limits
- [ ] Use annotations for metadata management
- [ ] Demonstrate advanced kubectl skills
- [ ] Complete all hands-on labs
- [ ] Pass assessment with 80% or higher

---

**Next Module**: [03-workloads](../03-workloads/README.md) - Pods, Deployments, and Workload Management

**Estimated Time**: 4-5 days  
**Difficulty**: Intermediate  
**Prerequisites**: Module 01 completed
