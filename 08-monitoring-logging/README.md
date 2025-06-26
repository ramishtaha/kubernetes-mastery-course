# Module 8: Monitoring and Logging

## 📚 Learning Objectives

By the end of this module, you will understand:
- Kubernetes observability concepts and architecture
- Native monitoring with metrics-server and kubectl
- Application and infrastructure monitoring
- Centralized logging strategies
- Alerting and notification systems
- Performance monitoring and troubleshooting
- Best practices for observability in production

## 🎯 Prerequisites

- Completed Module 7: Security
- Basic understanding of monitoring concepts (metrics, logs, traces)
- Knowledge of system administration and troubleshooting

## 📖 Theory: Observability in Kubernetes

### The Three Pillars of Observability

1. **Metrics**: Quantitative measurements (CPU, memory, request count)
2. **Logs**: Discrete events with timestamps
3. **Traces**: Request flows through distributed systems

### Kubernetes Monitoring Architecture

#### Native Components
- **metrics-server**: Core metrics for HPA and kubectl top
- **cAdvisor**: Container metrics collection
- **kubelet**: Node and Pod metrics
- **kube-state-metrics**: Kubernetes object metrics

#### External Solutions
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Metrics visualization
- **ELK/EFK Stack**: Centralized logging
- **Jaeger/Zipkin**: Distributed tracing

### Key Metrics to Monitor

#### Cluster Level
- Node resource utilization
- Pod count and distribution
- API server performance
- etcd performance

#### Application Level
- Request rate, latency, and errors
- Resource consumption
- Application-specific metrics
- Business metrics

#### Infrastructure Level
- CPU, memory, disk, network
- Storage performance
- Network latency and throughput

## 🧪 Hands-on Labs

### Lab 1: Native Monitoring with metrics-server

1. **Install metrics-server**:

```bash
# Download and apply metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# For local development (if using self-signed certificates)
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# Wait for deployment to be ready
kubectl wait --for=condition=available --timeout=300s deployment/metrics-server -n kube-system
```

2. **Test metrics collection**:

```bash
# Check node metrics
kubectl top nodes

# Check pod metrics
kubectl top pods --all-namespaces

# Check metrics for specific namespace
kubectl top pods -n kube-system
```

3. **Create a test application to monitor**:

```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cpu-stress
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cpu-stress
  template:
    metadata:
      labels:
        app: cpu-stress
    spec:
      containers:
      - name: cpu-stress
        image: containerstack/cpustress
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 256Mi
        env:
        - name: CPU_CORE
          value: "1"
        - name: TIMEOUT
          value: "300s"
EOF
```

4. **Monitor resource usage**:

```bash
# Watch CPU and memory usage
watch kubectl top pods

# In another terminal, check detailed resource usage
kubectl describe pod -l app=cpu-stress
```

### Lab 2: Application Logging

1. **Create an application with different log levels**:

```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: log-generator
spec:
  replicas: 2
  selector:
    matchLabels:
      app: log-generator
  template:
    metadata:
      labels:
        app: log-generator
    spec:
      containers:
      - name: log-generator
        image: busybox
        command:
        - /bin/sh
        - -c
        - |
          i=0
          while true; do
            i=$((i+1))
            echo "$(date): INFO - Log entry $i"
            sleep 5
            
            if [ $((i % 3)) -eq 0 ]; then
              echo "$(date): WARNING - This is a warning message $i" >&2
            fi
            
            if [ $((i % 10)) -eq 0 ]; then
              echo "$(date): ERROR - This is an error message $i" >&2
            fi
          done
EOF
```

2. **View and filter logs**:

```bash
# View logs from all pods
kubectl logs -l app=log-generator

# Follow logs from a specific pod
kubectl logs -f deployment/log-generator

# View logs from all containers in the deployment
kubectl logs -f deployment/log-generator --all-containers=true

# View logs with timestamps
kubectl logs deployment/log-generator --timestamps=true

# View recent logs (last 10 lines)
kubectl logs deployment/log-generator --tail=10

# View logs from the last hour
kubectl logs deployment/log-generator --since=1h
```

3. **Multi-container logging example**:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-logs
spec:
  containers:
  - name: main-app
    image: busybox
    command:
    - /bin/sh
    - -c
    - |
      while true; do
        echo "$(date): Main app is running"
        sleep 10
      done
  - name: sidecar-logger
    image: busybox
    command:
    - /bin/sh
    - -c
    - |
      while true; do
        echo "$(date): Sidecar performing health check"
        sleep 15
      done
EOF

# View logs from specific container
kubectl logs multi-container-logs -c main-app
kubectl logs multi-container-logs -c sidecar-logger

# View logs from all containers
kubectl logs multi-container-logs --all-containers=true
```

### Lab 3: Basic Prometheus Monitoring

1. **Install Prometheus using manifests**:

```bash
# Create namespace
kubectl create namespace monitoring

# Create service account and RBAC
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
- apiGroups: [""]
  resources:
  - nodes
  - nodes/proxy
  - services
  - endpoints
  - pods
  verbs: ["get", "list", "watch"]
- apiGroups:
  - extensions
  resources:
  - ingresses
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: monitoring
EOF
```

2. **Create Prometheus configuration**:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
    - job_name: 'kubernetes-nodes'
      kubernetes_sd_configs:
      - role: node
      relabel_configs:
      - source_labels: [__address__]
        regex: '(.*):10250'
        replacement: '${1}:9100'
        target_label: __address__
    - job_name: 'kubernetes-pods'
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
    - job_name: 'kubernetes-service-endpoints'
      kubernetes_sd_configs:
      - role: endpoints
      relabel_configs:
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
        action: keep
        regex: true
EOF
```

3. **Deploy Prometheus**:

```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      serviceAccountName: prometheus
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: config
          mountPath: /etc/prometheus
        - name: storage
          mountPath: /prometheus
        args:
        - '--config.file=/etc/prometheus/prometheus.yml'
        - '--storage.tsdb.path=/prometheus'
        - '--web.console.libraries=/etc/prometheus/console_libraries'
        - '--web.console.templates=/etc/prometheus/consoles'
        - '--web.enable-lifecycle'
      volumes:
      - name: config
        configMap:
          name: prometheus-config
      - name: storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: monitoring
spec:
  selector:
    app: prometheus
  ports:
  - port: 9090
    targetPort: 9090
    nodePort: 30090
  type: NodePort
EOF
```

4. **Access Prometheus UI**:

```bash
# Get Prometheus URL
echo "Prometheus UI: http://$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}'):30090"

# Port forward for local access
kubectl port-forward -n monitoring service/prometheus 9090:9090
```

### Lab 4: Custom Application Metrics

1. **Create an application that exposes metrics**:

```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: metrics-app
  template:
    metadata:
      labels:
        app: metrics-app
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: metrics-app
        image: nginx
        ports:
        - containerPort: 80
        - containerPort: 8080
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d
        - name: metrics-script
          mountPath: /usr/local/bin
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-metrics-config
      - name: metrics-script
        configMap:
          name: metrics-script
          defaultMode: 0755
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-metrics-config
data:
  default.conf: |
    server {
        listen 80;
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
        location /metrics {
            proxy_pass http://localhost:8080/metrics;
        }
    }
    server {
        listen 8080;
        location /metrics {
            add_header Content-Type text/plain;
            return 200 "# HELP http_requests_total Total HTTP requests
    # TYPE http_requests_total counter
    http_requests_total{method=\"GET\",status=\"200\"} 42
    # HELP app_memory_usage Application memory usage
    # TYPE app_memory_usage gauge
    app_memory_usage 1024000
    ";
        }
    }
---
apiVersion: v1
kind: Service
metadata:
  name: metrics-app
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
spec:
  selector:
    app: metrics-app
  ports:
  - name: web
    port: 80
    targetPort: 80
  - name: metrics
    port: 8080
    targetPort: 8080
EOF
```

2. **Test metrics endpoint**:

```bash
# Test metrics endpoint
kubectl port-forward service/metrics-app 8080:8080 &
curl http://localhost:8080/metrics

# Stop port forward
kill %1
```

### Lab 5: Log Aggregation Setup

1. **Create a simple log aggregation setup**:

```bash
# Create a fluentd daemonset for log collection
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: fluentd
  template:
    metadata:
      labels:
        name: fluentd
    spec:
      serviceAccount: fluentd
      serviceAccountName: fluentd
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1-debian-elasticsearch
        env:
        - name:  FLUENT_ELASTICSEARCH_HOST
          value: "elasticsearch.kube-system.svc.cluster.local"
        - name:  FLUENT_ELASTICSEARCH_PORT
          value: "9200"
        - name: FLUENT_ELASTICSEARCH_SCHEME
          value: "http"
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
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fluentd
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: fluentd
rules:
- apiGroups:
  - ""
  resources:
  - pods
  - namespaces
  verbs:
  - get
  - list
  - watch
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: fluentd
roleRef:
  kind: ClusterRole
  name: fluentd
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: fluentd
  namespace: kube-system
EOF
```

2. **Check DaemonSet deployment**:

```bash
# Check fluentd pods on all nodes
kubectl get ds -n kube-system
kubectl get pods -n kube-system -l name=fluentd

# Check logs from fluentd
kubectl logs -n kube-system -l name=fluentd --tail=20
```

## 💡 Best Practices

### 1. Metrics Collection
- Focus on the four golden signals: latency, traffic, errors, saturation
- Use appropriate metric types (counter, gauge, histogram, summary)
- Implement proper labeling strategy
- Set up alerting on critical metrics

### 2. Logging Strategy
- Implement structured logging (JSON format)
- Use consistent log levels and formats
- Avoid logging sensitive information
- Implement log rotation and retention policies

### 3. Monitoring Architecture
- Separate monitoring infrastructure from application workloads
- Implement redundancy for critical monitoring components
- Use resource limits for monitoring components
- Plan for monitoring data retention and storage

### 4. Alerting
- Define clear SLIs (Service Level Indicators) and SLOs (Service Level Objectives)
- Implement tiered alerting (info, warning, critical)
- Avoid alert fatigue with proper thresholds
- Include context and runbooks in alerts

## 🔧 Troubleshooting Monitoring Issues

### Common Problems and Solutions

#### 1. Metrics Not Available

**Problem**: kubectl top or metrics not working
**Diagnosis**:
```bash
kubectl get apiservice v1beta1.metrics.k8s.io -o yaml
kubectl logs -n kube-system deployment/metrics-server
kubectl describe nodes
```

**Solutions**:
- Check metrics-server deployment
- Verify kubelet configuration
- Check certificate issues
- Ensure proper RBAC permissions

#### 2. High Resource Usage

**Problem**: Monitoring components consuming too many resources
**Diagnosis**:
```bash
kubectl top pods -n monitoring
kubectl describe pod <pod-name> -n monitoring
```

**Solutions**:
- Adjust resource limits
- Optimize metric retention
- Scale monitoring components
- Review metric cardinality

#### 3. Missing Logs

**Problem**: Logs not appearing in centralized system
**Diagnosis**:
```bash
kubectl logs <pod-name>
kubectl describe pod <log-collector-pod>
kubectl get events
```

**Solutions**:
- Check log collector configuration
- Verify log file paths and permissions
- Check network connectivity
- Review log forwarding rules

### Monitoring Health Commands

```bash
# Check cluster resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Monitor events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check system pods
kubectl get pods -n kube-system

# Monitor resource quotas
kubectl describe quota --all-namespaces

# Check persistent volume usage
kubectl get pv,pvc --all-namespaces
```

## 📝 Assessment Questions

1. **Multiple Choice**: Which component provides core metrics for HPA and kubectl top?
   - a) Prometheus
   - b) metrics-server
   - c) cAdvisor
   - d) Grafana

2. **Multiple Choice**: What are the three pillars of observability?
   - a) Monitoring, Alerting, Dashboards
   - b) Metrics, Logs, Traces
   - c) CPU, Memory, Network
   - d) Applications, Infrastructure, Security

3. **Practical**: Set up monitoring for a web application that exposes custom metrics and configure alerts for high error rates.

4. **Scenario**: Design a complete observability solution for a microservices application including metrics collection, log aggregation, and alerting.

## 🎯 Module Summary

You have learned:
- ✅ Kubernetes observability concepts and architecture
- ✅ Native monitoring with metrics-server
- ✅ Application and infrastructure monitoring
- ✅ Log collection and aggregation strategies
- ✅ Custom metrics and Prometheus integration
- ✅ Troubleshooting monitoring issues
- ✅ Best practices for production observability
- ✅ Performance monitoring and optimization

## 🔄 Next Steps

Ready for the next module? Continue to:
**[Module 9: Package Management](../09-package-management/README.md)**

## 📚 Additional Resources

- [Kubernetes Monitoring Guide](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-usage-monitoring/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [ELK Stack Guide](https://www.elastic.co/elastic-stack/)

---

**📊 Monitoring Tip**: Good observability is about making the invisible visible. Monitor what matters, alert on what's actionable, and always include context for effective troubleshooting!
