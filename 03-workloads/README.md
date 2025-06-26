# Module 03: Workloads - Pods, Deployments, and Services

This module covers the core workload resources in Kubernetes: Pods, Deployments, ReplicaSets, Services, and other workload controllers.

## 📚 Learning Objectives

By the end of this module, you will:
- Master Pod concepts and lifecycle management
- Deploy and manage applications using Deployments
- Understand ReplicaSets and scaling strategies
- Configure Services for network connectivity
- Implement DaemonSets and StatefulSets
- Manage Jobs and CronJobs for batch workloads
- Apply rolling updates and rollback strategies

## 📋 Module Outline

1. [Understanding Pods](#1-understanding-pods)
2. [Deployments and ReplicaSets](#2-deployments-and-replicasets)
3. [Services and Service Discovery](#3-services-and-service-discovery)
4. [DaemonSets](#4-daemonsets)
5. [StatefulSets](#5-statefulsets)
6. [Jobs and CronJobs](#6-jobs-and-cronjobs)
7. [Scaling and Updates](#7-scaling-and-updates)
8. [Hands-on Labs](#8-hands-on-labs)
9. [Assessment](#9-assessment)

---

## 1. Understanding Pods

### What is a Pod?

A Pod is the smallest deployable unit in Kubernetes that:
- Contains one or more containers
- Shares network (IP address and ports)
- Shares storage volumes
- Is scheduled together on the same node
- Lives and dies together

### Pod Lifecycle

```
Pending → Running → Succeeded/Failed
    ↓
ContainerCreating
    ↓
ImagePullBackOff (if image issues)
    ↓
CrashLoopBackOff (if container crashes)
```

### Pod States

| Phase | Description |
|-------|-------------|
| **Pending** | Pod accepted but not yet scheduled |
| **Running** | Pod bound to node, containers created |
| **Succeeded** | All containers terminated successfully |
| **Failed** | All containers terminated, at least one failed |
| **Unknown** | Pod state could not be obtained |

### Basic Pod Manifest

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
    tier: frontend
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - containerPort: 80
      name: http
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "500m"
    env:
    - name: ENV_VAR
      value: "production"
  restartPolicy: Always
```

### Multi-Container Pods

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
spec:
  containers:
  # Main application container
  - name: web-app
    image: nginx:1.21
    ports:
    - containerPort: 80
    volumeMounts:
    - name: shared-data
      mountPath: /usr/share/nginx/html
  
  # Sidecar container for log processing
  - name: log-processor
    image: busybox
    command: ['sh', '-c', 'while true; do echo "Processing logs..." >> /var/log/app.log; sleep 30; done']
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log
  
  # Init container for setup
  initContainers:
  - name: setup
    image: busybox
    command: ['sh', '-c', 'echo "Setup complete" > /shared/setup.txt']
    volumeMounts:
    - name: shared-data
      mountPath: /shared
  
  volumes:
  - name: shared-data
    emptyDir: {}
  - name: shared-logs
    emptyDir: {}
```

### Pod Configuration Patterns

#### 1. Resource Management
```yaml
spec:
  containers:
  - name: app
    image: myapp:latest
    resources:
      requests:          # Guaranteed resources
        memory: "128Mi"
        cpu: "100m"
      limits:           # Maximum resources
        memory: "256Mi"
        cpu: "500m"
```

#### 2. Health Checks
```yaml
spec:
  containers:
  - name: app
    image: myapp:latest
    livenessProbe:      # Restart if fails
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
    readinessProbe:     # Remove from service if fails
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
```

#### 3. Environment Variables
```yaml
spec:
  containers:
  - name: app
    image: myapp:latest
    env:
    - name: ENV_VAR
      value: "direct-value"
    - name: SECRET_VAR
      valueFrom:
        secretKeyRef:
          name: app-secret
          key: password
    - name: CONFIG_VAR
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database-url
```

---

## 2. Deployments and ReplicaSets

### Understanding Deployments

Deployments provide:
- **Declarative updates** for Pods and ReplicaSets
- **Rolling updates** with zero downtime
- **Rollback capabilities** to previous versions
- **Scaling** up and down
- **Pause and resume** of rollouts

### Deployment Architecture

```
Deployment
    ↓ (manages)
ReplicaSet
    ↓ (creates)
Pods
```

### Basic Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
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
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
```

### Deployment Strategies

#### 1. Rolling Update (Default)
```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1      # Max pods unavailable during update
      maxSurge: 1           # Max extra pods during update
```

#### 2. Recreate Strategy
```yaml
spec:
  strategy:
    type: Recreate  # Terminate all pods, then create new ones
```

### Advanced Deployment Configuration

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  annotations:
    deployment.kubernetes.io/revision: "1"
spec:
  replicas: 5
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
        version: "v1.0"
    spec:
      containers:
      - name: web
        image: nginx:1.21
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 25%
  revisionHistoryLimit: 10
```

### Managing Deployments

```bash
# Create deployment
kubectl create deployment nginx --image=nginx:1.21 --replicas=3

# Scale deployment
kubectl scale deployment nginx --replicas=5

# Update image
kubectl set image deployment/nginx nginx=nginx:1.22

# Check rollout status
kubectl rollout status deployment/nginx

# View rollout history
kubectl rollout history deployment/nginx

# Rollback to previous version
kubectl rollout undo deployment/nginx

# Rollback to specific revision
kubectl rollout undo deployment/nginx --to-revision=2

# Pause rollout
kubectl rollout pause deployment/nginx

# Resume rollout
kubectl rollout resume deployment/nginx
```

---

## 3. Services and Service Discovery

### Service Types

| Type | Description | Use Case |
|------|-------------|----------|
| **ClusterIP** | Internal cluster access only | Internal communication |
| **NodePort** | External access via node ports | Development/testing |
| **LoadBalancer** | External load balancer | Production external access |
| **ExternalName** | DNS alias to external service | External service integration |

### ClusterIP Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
  - name: http
    port: 80
    targetPort: 80
    protocol: TCP
  type: ClusterIP
```

### NodePort Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport
spec:
  selector:
    app: nginx
  ports:
  - name: http
    port: 80
    targetPort: 80
    nodePort: 30080
    protocol: TCP
  type: NodePort
```

### LoadBalancer Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-loadbalancer
spec:
  selector:
    app: nginx
  ports:
  - name: http
    port: 80
    targetPort: 80
    protocol: TCP
  type: LoadBalancer
```

### Service Discovery

Services provide DNS names for pod discovery:

```bash
# Service DNS format
<service-name>.<namespace>.svc.cluster.local

# Examples
nginx-service.default.svc.cluster.local
database.production.svc.cluster.local
api.backend.svc.cluster.local
```

### Endpoints

```yaml
# Kubernetes automatically creates Endpoints
apiVersion: v1
kind: Endpoints
metadata:
  name: nginx-service
subsets:
- addresses:
  - ip: 10.244.0.5
  - ip: 10.244.0.6
  - ip: 10.244.0.7
  ports:
  - name: http
    port: 80
    protocol: TCP
```

---

## 4. DaemonSets

### What are DaemonSets?

DaemonSets ensure that a copy of a Pod runs on all (or some) nodes:
- **Log collection** (Fluentd, Filebeat)
- **Monitoring** (Node Exporter, cAdvisor)
- **Network plugins** (Calico, Flannel)
- **Storage daemons** (Ceph, GlusterFS)

### DaemonSet Example

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-elasticsearch
  namespace: kube-system
  labels:
    k8s-app: fluentd-logging
spec:
  selector:
    matchLabels:
      name: fluentd-elasticsearch
  template:
    metadata:
      labels:
        name: fluentd-elasticsearch
    spec:
      tolerations:
      # Allow scheduling on master nodes
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      containers:
      - name: fluentd-elasticsearch
        image: quay.io/fluentd_elasticsearch/fluentd:v2.5.2
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      terminationGracePeriodSeconds: 30
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
```

### DaemonSet Management

```bash
# Create DaemonSet
kubectl apply -f daemonset.yaml

# View DaemonSet
kubectl get daemonsets -n kube-system

# Describe DaemonSet
kubectl describe daemonset fluentd-elasticsearch -n kube-system

# Update DaemonSet
kubectl patch daemonset fluentd-elasticsearch -n kube-system -p '{"spec":{"template":{"spec":{"containers":[{"name":"fluentd-elasticsearch","image":"quay.io/fluentd_elasticsearch/fluentd:v2.6.0"}]}}}}'

# Delete DaemonSet
kubectl delete daemonset fluentd-elasticsearch -n kube-system
```

---

## 5. StatefulSets

### What are StatefulSets?

StatefulSets provide:
- **Stable network identities** (persistent hostnames)
- **Stable persistent storage** (tied to Pod identity)
- **Ordered deployment and scaling**
- **Ordered rolling updates**

Use cases:
- **Databases** (MySQL, PostgreSQL, MongoDB)
- **Distributed systems** (Kafka, Zookeeper, Elasticsearch)
- **Applications requiring persistent identity**

### StatefulSet Example

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
          name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "password"
        volumeMounts:
        - name: mysql-persistent-storage
          mountPath: /var/lib/mysql
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1"
  volumeClaimTemplates:
  - metadata:
      name: mysql-persistent-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 10Gi

---
apiVersion: v1
kind: Service
metadata:
  name: mysql
  labels:
    app: mysql
spec:
  ports:
  - port: 3306
    name: mysql
  clusterIP: None
  selector:
    app: mysql
```

### StatefulSet Pod Naming

StatefulSet pods have predictable names:
```
mysql-0
mysql-1
mysql-2
```

### Headless Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-headless
spec:
  clusterIP: None  # Headless service
  selector:
    app: mysql
  ports:
  - port: 3306
```

---

## 6. Jobs and CronJobs

### Jobs

Jobs run pods to completion:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: data-migration
spec:
  template:
    spec:
      containers:
      - name: migration
        image: python:3.9
        command: ["python", "migrate.py"]
        env:
        - name: DATABASE_URL
          value: "postgresql://user:pass@db:5432/myapp"
      restartPolicy: Never
  backoffLimit: 4  # Retry limit
```

### Parallel Jobs

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: parallel-processing
spec:
  parallelism: 3      # Run 3 pods in parallel
  completions: 9      # Need 9 successful completions
  template:
    spec:
      containers:
      - name: worker
        image: busybox
        command: ["sh", "-c", "echo Processing item && sleep 10"]
      restartPolicy: Never
```

### CronJobs

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-job
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: postgres:13
            command:
            - /bin/bash
            - -c
            - |
              pg_dump -h database-service -U postgres myapp > /backup/backup-$(date +%Y%m%d).sql
            env:
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: password
            volumeMounts:
            - name: backup-storage
              mountPath: /backup
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: backup-pvc
          restartPolicy: OnFailure
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
```

---

## 7. Scaling and Updates

### Horizontal Pod Autoscaler (HPA)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-deployment
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Manual Scaling

```bash
# Scale deployment
kubectl scale deployment nginx-deployment --replicas=5

# Scale ReplicaSet
kubectl scale rs nginx-rs --replicas=3

# Scale StatefulSet
kubectl scale statefulset mysql --replicas=5
```

### Rolling Updates

```bash
# Update deployment image
kubectl set image deployment/nginx-deployment nginx=nginx:1.22

# Update with specific strategy
kubectl patch deployment nginx-deployment -p '{"spec":{"strategy":{"rollingUpdate":{"maxSurge":"50%","maxUnavailable":"50%"}}}}'

# Monitor rollout
kubectl rollout status deployment/nginx-deployment

# Rollback if needed
kubectl rollout undo deployment/nginx-deployment
```

---

## 8. Hands-on Labs

### Lab 1: Pod Lifecycle Management

**Objective**: Understand pod creation, monitoring, and troubleshooting

```bash
# Create a pod with resource limits
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: resource-demo
  labels:
    app: demo
spec:
  containers:
  - name: app
    image: nginx:latest
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "500m"
    ports:
    - containerPort: 80
EOF

# Monitor pod creation
kubectl get pods -w

# Check pod details
kubectl describe pod resource-demo

# Check resource usage
kubectl top pod resource-demo

# Access pod logs
kubectl logs resource-demo

# Execute commands in pod
kubectl exec -it resource-demo -- bash

# Clean up
kubectl delete pod resource-demo
```

### Lab 2: Deployment Management

**Objective**: Deploy and manage applications with rolling updates

```bash
# Create deployment
kubectl create deployment web-app --image=nginx:1.20 --replicas=3

# Expose deployment
kubectl expose deployment web-app --port=80 --type=NodePort

# Check rollout status
kubectl rollout status deployment/web-app

# Update deployment
kubectl set image deployment/web-app nginx=nginx:1.21

# Monitor update
kubectl rollout status deployment/web-app

# Check rollout history
kubectl rollout history deployment/web-app

# Scale deployment
kubectl scale deployment web-app --replicas=5

# Rollback to previous version
kubectl rollout undo deployment/web-app

# Clean up
kubectl delete deployment web-app
kubectl delete service web-app
```

### Lab 3: Multi-Container Pod

**Objective**: Deploy and manage multi-container pods

```bash
# Create multi-container pod
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: multi-container
spec:
  containers:
  - name: web
    image: nginx:latest
    ports:
    - containerPort: 80
    volumeMounts:
    - name: shared-data
      mountPath: /usr/share/nginx/html
  - name: content-generator
    image: busybox
    command: ['sh', '-c', 'while true; do echo "<h1>Hello from $(hostname) at $(date)</h1>" > /usr/share/nginx/html/index.html; sleep 30; done']
    volumeMounts:
    - name: shared-data
      mountPath: /usr/share/nginx/html
  volumes:
  - name: shared-data
    emptyDir: {}
EOF

# Test the application
kubectl port-forward pod/multi-container 8080:80 &
curl http://localhost:8080

# Check logs from both containers
kubectl logs multi-container -c web
kubectl logs multi-container -c content-generator

# Clean up
kubectl delete pod multi-container
```

### Lab 4: Service Discovery

**Objective**: Implement service discovery between applications

```bash
# Create backend service
cat <<EOF | kubectl apply -f -
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
        image: nginx:latest
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
    targetPort: 80
EOF

# Create frontend that connects to backend
cat <<EOF | kubectl apply -f -
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
    spec:
      containers:
      - name: frontend
        image: busybox
        command: ['sleep', '3600']
EOF

# Test service discovery
kubectl exec -it deployment/frontend -- nslookup backend-service
kubectl exec -it deployment/frontend -- wget -qO- http://backend-service

# Clean up
kubectl delete deployment backend frontend
kubectl delete service backend-service
```

### Lab 5: StatefulSet with Persistent Storage

**Objective**: Deploy a stateful application with persistent storage

```bash
# Create StatefulSet with PVC template
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis
spec:
  serviceName: redis
  replicas: 3
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:6
        ports:
        - containerPort: 6379
        volumeMounts:
        - name: redis-data
          mountPath: /data
  volumeClaimTemplates:
  - metadata:
      name: redis-data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi

---
apiVersion: v1
kind: Service
metadata:
  name: redis
spec:
  clusterIP: None
  selector:
    app: redis
  ports:
  - port: 6379
EOF

# Check StatefulSet status
kubectl get statefulset redis
kubectl get pods -l app=redis

# Check persistent volumes
kubectl get pvc

# Test Redis connectivity
kubectl exec -it redis-0 -- redis-cli ping

# Clean up
kubectl delete statefulset redis
kubectl delete service redis
kubectl delete pvc redis-data-redis-0 redis-data-redis-1 redis-data-redis-2
```

---

## 9. Assessment

### Knowledge Check Questions

1. **Pod Concepts**: What's the difference between a Pod and a container?

2. **Deployment Strategies**: When would you use Recreate vs RollingUpdate strategy?

3. **Service Types**: What are the differences between ClusterIP, NodePort, and LoadBalancer services?

4. **StatefulSets**: Why would you use a StatefulSet instead of a Deployment?

5. **Jobs vs CronJobs**: What's the difference and when would you use each?

### Practical Exercises

#### Exercise 1: Complete Application Stack
Deploy a complete web application stack:
- Frontend (nginx) - Deployment with 3 replicas
- Backend API (node.js) - Deployment with 2 replicas  
- Database (PostgreSQL) - StatefulSet with persistent storage
- Configure services for communication
- Implement health checks

#### Exercise 2: Batch Processing System
Create a batch processing system:
- Job for data processing
- CronJob for daily reports
- Shared storage between jobs
- Error handling and retry logic

#### Exercise 3: Auto-scaling Application
Implement auto-scaling:
- Deployment with resource requests/limits
- HPA for CPU-based scaling
- Load testing to trigger scaling
- Monitor scaling behavior

### Hands-on Project: E-commerce Platform

Deploy a complete e-commerce platform:

```yaml
# Frontend Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"

---
# Backend API Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: node:16
        command: ['sleep', '3600']
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_URL
          value: "postgresql://user:pass@database:5432/ecommerce"

---
# Database StatefulSet
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: database
spec:
  serviceName: database
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: postgres
        image: postgres:13
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: "ecommerce"
        - name: POSTGRES_USER
          value: "user"
        - name: POSTGRES_PASSWORD
          value: "pass"
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: postgres-data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 5Gi

---
# Services
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    nodePort: 30080
  type: NodePort

---
apiVersion: v1
kind: Service
metadata:
  name: api-service
spec:
  selector:
    app: api
  ports:
  - port: 3000

---
apiVersion: v1
kind: Service
metadata:
  name: database
spec:
  selector:
    app: database
  ports:
  - port: 5432
  clusterIP: None
```

### Assessment Rubric

| Skill Area | Beginner | Intermediate | Advanced |
|------------|----------|--------------|----------|
| **Pod Management** | Create basic pods | Multi-container pods | Advanced configurations |
| **Deployments** | Basic deployments | Rolling updates | Complex strategies |
| **Services** | ClusterIP services | All service types | Service mesh integration |
| **StatefulSets** | Basic stateful apps | Persistent storage | Distributed systems |
| **Scaling** | Manual scaling | HPA configuration | Performance optimization |

---

## 📚 Additional Resources

### Official Documentation
- [Pods](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)

### Best Practices
- [Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Health Checks](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Pod Security](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

---

## ✅ Module Completion Checklist

- [ ] Understand Pod concepts and lifecycle
- [ ] Deploy and manage Deployments
- [ ] Configure various Service types
- [ ] Implement StatefulSets with persistent storage
- [ ] Create and manage DaemonSets
- [ ] Use Jobs and CronJobs for batch processing
- [ ] Apply scaling strategies (manual and automatic)
- [ ] Complete all hands-on labs
- [ ] Pass assessment with 80% or higher

---

**Next Module**: [04-configuration](../04-configuration/README.md) - Configuration Management with ConfigMaps and Secrets

**Estimated Time**: 7-8 days  
**Difficulty**: Intermediate  
**Prerequisites**: Module 02 completed
