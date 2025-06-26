# Module 12: Production Practices

## 📚 Learning Objectives

By the end of this module, you will understand:
- Production-ready cluster configuration and hardening
- Advanced deployment strategies and patterns
- Disaster recovery and backup strategies
- Performance optimization and capacity planning
- Cost optimization and resource management
- Compliance and governance frameworks
- Operational excellence and SRE practices
- Migration strategies and cluster upgrades

## 🎯 Prerequisites

- Completed Module 11: Real-World Projects
- Understanding of production environment requirements
- Knowledge of infrastructure management
- Familiarity with compliance and security standards

## 📖 Theory: Production Kubernetes

### Production Readiness Checklist

#### 1. Infrastructure Requirements
- **High Availability**: Multi-master setup, etcd clustering
- **Networking**: CNI plugin selection, load balancers
- **Storage**: Persistent volume provisioning, backup strategies
- **Security**: Certificate management, secret encryption
- **Monitoring**: Comprehensive observability stack

#### 2. Security Hardening
- **RBAC**: Principle of least privilege
- **Network Security**: Network policies, service mesh
- **Container Security**: Image scanning, security contexts
- **Secrets Management**: External secret stores, rotation
- **Audit Logging**: Complete audit trail

#### 3. Operational Excellence
- **GitOps**: Declarative infrastructure and applications
- **CI/CD**: Automated testing and deployment
- **Monitoring**: SLI/SLO definition and alerting
- **Incident Response**: Runbooks and escalation procedures
- **Documentation**: Architecture and operational guides

### Deployment Strategies

#### 1. Rolling Updates
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rolling-update-app
spec:
  replicas: 10
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 25%
  template:
    spec:
      containers:
      - name: app
        image: nginx:1.21
        readinessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
```

#### 2. Canary Deployments
```yaml
# Production deployment (90% traffic)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-production
  labels:
    version: stable
spec:
  replicas: 9
  selector:
    matchLabels:
      app: myapp
      version: stable
  template:
    metadata:
      labels:
        app: myapp
        version: stable
    spec:
      containers:
      - name: app
        image: nginx:1.20
---
# Canary deployment (10% traffic)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-canary
  labels:
    version: canary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
      version: canary
  template:
    metadata:
      labels:
        app: myapp
        version: canary
    spec:
      containers:
      - name: app
        image: nginx:1.21
```

#### 3. Feature Flags
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: feature-flags
data:
  new-ui: "true"
  payment-v2: "false"
  analytics: "true"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: feature-flag-app
spec:
  template:
    spec:
      containers:
      - name: app
        env:
        - name: FEATURE_FLAGS
          valueFrom:
            configMapKeyRef:
              name: feature-flags
              key: new-ui
```

## 🧪 Hands-on Labs

### Lab 1: Production Cluster Setup

1. **Configure cluster for production**:

```bash
# Create production namespace with resource quotas
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: production
    tier: critical
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: production-quota
  namespace: production
spec:
  hard:
    requests.cpu: "100"
    requests.memory: 200Gi
    limits.cpu: "200"
    limits.memory: 400Gi
    persistentvolumeclaims: "50"
    pods: "100"
    services: "20"
    secrets: "20"
    configmaps: "20"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: production-limits
  namespace: production
spec:
  limits:
  - default:
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    type: Container
  - max:
      cpu: "4"
      memory: "8Gi"
    min:
      cpu: "50m"
      memory: "64Mi"
    type: Container
EOF
```

2. **Implement network policies for production**:

```bash
kubectl apply -f - <<EOF
# Default deny all traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
# Allow DNS resolution
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to: []
    ports:
    - protocol: UDP
      port: 53
---
# Allow frontend to backend communication
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 8080
---
# Allow ingress to frontend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-to-frontend
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 80
EOF
```

3. **Set up pod security standards**:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: production-secure
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
---
# Pod Security Policy replacement using ValidatingAdmissionWebhook
apiVersion: v1
kind: ConfigMap
metadata:
  name: security-policies
  namespace: production
data:
  policy.rego: |
    package kubernetes.admission
    
    deny[msg] {
        input.request.kind.kind == "Pod"
        input.request.object.spec.securityContext.runAsRoot == true
        msg := "Containers must not run as root user"
    }
    
    deny[msg] {
        input.request.kind.kind == "Pod"
        input.request.object.spec.containers[_].securityContext.privileged == true
        msg := "Privileged containers are not allowed"
    }
EOF
```

### Lab 2: Disaster Recovery Implementation

1. **Set up automated backups**:

```bash
# Create backup namespace
kubectl create namespace backup-system

# ETCD backup CronJob
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: etcd-backup
  namespace: backup-system
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: etcd-backup
            image: k8s.gcr.io/etcd:3.5.0-0
            command:
            - /bin/sh
            - -c
            - |
              ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot-\$(date +%Y%m%d-%H%M%S).db \\
                --endpoints=https://127.0.0.1:2379 \\
                --cacert=/etc/etcd/ca.crt \\
                --cert=/etc/etcd/etcd-client.crt \\
                --key=/etc/etcd/etcd-client.key
              
              # Keep only last 7 backups
              ls -t /backup/etcd-snapshot-*.db | tail -n +8 | xargs -r rm
            volumeMounts:
            - name: etcd-certs
              mountPath: /etc/etcd
              readOnly: true
            - name: backup-storage
              mountPath: /backup
          volumes:
          - name: etcd-certs
            hostPath:
              path: /etc/kubernetes/pki/etcd
          - name: backup-storage
            persistentVolumeClaim:
              claimName: backup-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: backup-pvc
  namespace: backup-system
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
EOF
```

2. **Implement application data backup**:

```bash
# Database backup solution
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: database-backup
  namespace: production
spec:
  schedule: "0 1 * * *"  # Daily at 1 AM
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: pg-dump
            image: postgres:13
            command:
            - /bin/bash
            - -c
            - |
              export PGPASSWORD=\$POSTGRES_PASSWORD
              pg_dump -h postgres-service -U postgres -d production_db > /backup/db-backup-\$(date +%Y%m%d-%H%M%S).sql
              
              # Compress backup
              gzip /backup/db-backup-\$(date +%Y%m%d-%H%M%S).sql
              
              # Keep only last 30 backups
              ls -t /backup/db-backup-*.sql.gz | tail -n +31 | xargs -r rm
            env:
            - name: POSTGRES_PASSWORD
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
              claimName: database-backup-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: database-backup-pvc
  namespace: production
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
EOF
```

3. **Create disaster recovery runbook**:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: disaster-recovery-runbook
  namespace: backup-system
data:
  recovery-procedures.md: |
    # Disaster Recovery Procedures
    
    ## ETCD Recovery
    
    ### 1. Stop all API servers
    \`\`\`bash
    sudo systemctl stop kube-apiserver
    \`\`\`
    
    ### 2. Restore ETCD from backup
    \`\`\`bash
    ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot-YYYYMMDD-HHMMSS.db \\
      --data-dir /var/lib/etcd-restore \\
      --initial-cluster master=https://IP:2380 \\
      --initial-advertise-peer-urls https://IP:2380
    \`\`\`
    
    ### 3. Update ETCD configuration
    \`\`\`bash
    sudo mv /var/lib/etcd /var/lib/etcd-backup
    sudo mv /var/lib/etcd-restore /var/lib/etcd
    sudo systemctl start etcd
    sudo systemctl start kube-apiserver
    \`\`\`
    
    ## Database Recovery
    
    ### 1. Create new database instance
    \`\`\`bash
    kubectl run postgres-recovery --image=postgres:13 --env="POSTGRES_PASSWORD=password"
    \`\`\`
    
    ### 2. Restore from backup
    \`\`\`bash
    kubectl exec -it postgres-recovery -- psql -U postgres -c "CREATE DATABASE production_db;"
    kubectl exec -i postgres-recovery -- psql -U postgres -d production_db < db-backup-YYYYMMDD-HHMMSS.sql
    \`\`\`
    
    ## Application Recovery
    
    ### 1. Scale down affected applications
    \`\`\`bash
    kubectl scale deployment --all --replicas=0 -n production
    \`\`\`
    
    ### 2. Restore from GitOps repository
    \`\`\`bash
    git checkout main
    kubectl apply -k overlays/production/
    \`\`\`
    
    ### 3. Verify application health
    \`\`\`bash
    kubectl get pods -n production
    kubectl get services -n production
    \`\`\`
  
  recovery-script.sh: |
    #!/bin/bash
    set -e
    
    echo "=== Kubernetes Disaster Recovery Script ==="
    echo "This script will help recover from a disaster scenario"
    echo
    
    read -p "Select recovery type (etcd/database/application): " RECOVERY_TYPE
    
    case \$RECOVERY_TYPE in
      "etcd")
        echo "Starting ETCD recovery..."
        # Add ETCD recovery logic here
        ;;
      "database")
        echo "Starting database recovery..."
        # Add database recovery logic here
        ;;
      "application")
        echo "Starting application recovery..."
        # Add application recovery logic here
        ;;
      *)
        echo "Invalid recovery type"
        exit 1
        ;;
    esac
    
    echo "Recovery completed successfully!"
EOF
```

### Lab 3: Performance Optimization

1. **Implement resource monitoring and optimization**:

```bash
# Vertical Pod Autoscaler setup
kubectl apply -f - <<EOF
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: vpa-recommender
  namespace: production
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: resource-intensive-app
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: app
      minAllowed:
        cpu: 100m
        memory: 128Mi
      maxAllowed:
        cpu: 2
        memory: 4Gi
      controlledResources: ["cpu", "memory"]
---
# HPA with custom metrics
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: custom-metrics-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 3
  maxReplicas: 50
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
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "1000"
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
      - type: Pods
        value: 2
        periodSeconds: 60
      selectPolicy: Max
EOF
```

2. **Implement cluster monitoring and alerting**:

```bash
# Prometheus AlertManager rules
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-alerts
  namespace: monitoring
data:
  alerts.yml: |
    groups:
    - name: kubernetes-cluster
      rules:
      - alert: KubernetesNodeDown
        expr: up{job="kubernetes-nodes"} == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Kubernetes node is down"
          description: "Node {{ \$labels.instance }} has been down for more than 5 minutes"
      
      - alert: KubernetesPodCrashLooping
        expr: rate(kube_pod_container_status_restarts_total[5m]) > 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Pod is crash looping"
          description: "Pod {{ \$labels.pod }} in namespace {{ \$labels.namespace }} is crash looping"
      
      - alert: KubernetesMemoryPressure
        expr: kube_node_status_condition{condition="MemoryPressure",status="true"} == 1
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Node under memory pressure"
          description: "Node {{ \$labels.node }} is under memory pressure"
      
      - alert: KubernetesDiskPressure
        expr: kube_node_status_condition{condition="DiskPressure",status="true"} == 1
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Node under disk pressure"
          description: "Node {{ \$labels.node }} is under disk pressure"
      
      - alert: KubernetesAPIServerDown
        expr: up{job="kubernetes-apiservers"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Kubernetes API server is down"
          description: "API server has been down for more than 1 minute"
    
    - name: application-alerts
      rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.05
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High error rate detected"
          description: "Error rate is above 5% for 5 minutes"
      
      - alert: HighLatency
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 0.5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High latency detected"
          description: "95th percentile latency is above 500ms"
EOF
```

3. **Implement cost optimization**:

```bash
# Cluster cost optimization recommendations
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cost-optimization-report
  namespace: kube-system
spec:
  schedule: "0 9 * * 1"  # Weekly on Monday at 9 AM
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          serviceAccountName: cost-analyzer
          containers:
          - name: cost-analyzer
            image: bitnami/kubectl
            command:
            - /bin/bash
            - -c
            - |
              echo "=== Kubernetes Cost Optimization Report ==="
              echo "Generated on: \$(date)"
              echo
              
              echo "## Resource Utilization by Namespace"
              kubectl top pods --all-namespaces | awk '
              BEGIN {
                printf "%-20s %-10s %-10s %-10s\n", "NAMESPACE", "PODS", "CPU(m)", "MEMORY(Mi)"
                printf "%-20s %-10s %-10s %-10s\n", "---------", "----", "------", "---------"
              }
              {
                if(NR>1) {
                  ns[\$1]++;
                  cpu[\$1]+=\$3;
                  mem[\$1]+=\$4;
                }
              }
              END {
                for(i in ns) {
                  printf "%-20s %-10d %-10d %-10d\n", i, ns[i], cpu[i], mem[i]
                }
              }'
              
              echo
              echo "## Underutilized Resources"
              echo "Deployments with low CPU utilization:"
              kubectl get deployments --all-namespaces -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,REPLICAS:.spec.replicas,READY:.status.readyReplicas" | grep -v "0/0"
              
              echo
              echo "## Recommendations"
              echo "1. Consider reducing replicas for underutilized deployments"
              echo "2. Implement HPA for variable workloads"
              echo "3. Use node autoscaling for cost optimization"
              echo "4. Consider spot instances for non-critical workloads"
              echo "5. Implement resource quotas to prevent over-provisioning"
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cost-analyzer
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cost-analyzer
rules:
- apiGroups: [""]
  resources: ["pods", "nodes", "namespaces"]
  verbs: ["get", "list"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list"]
- apiGroups: ["metrics.k8s.io"]
  resources: ["pods", "nodes"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cost-analyzer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cost-analyzer
subjects:
- kind: ServiceAccount
  name: cost-analyzer
  namespace: kube-system
EOF
```

### Lab 4: Compliance and Governance

1. **Implement compliance monitoring**:

```bash
# CIS Kubernetes Benchmark compliance check
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: compliance-check
  namespace: kube-system
spec:
  template:
    spec:
      restartPolicy: Never
      hostPID: true
      containers:
      - name: kube-bench
        image: aquasec/kube-bench:latest
        command: ["kube-bench"]
        args: ["--version", "1.20"]
        volumeMounts:
        - name: var-lib-etcd
          mountPath: /var/lib/etcd
          readOnly: true
        - name: var-lib-kubelet
          mountPath: /var/lib/kubelet
          readOnly: true
        - name: etc-systemd
          mountPath: /etc/systemd
          readOnly: true
        - name: etc-kubernetes
          mountPath: /etc/kubernetes
          readOnly: true
        - name: usr-bin
          mountPath: /usr/local/mount-from-host/bin
          readOnly: true
      volumes:
      - name: var-lib-etcd
        hostPath:
          path: "/var/lib/etcd"
      - name: var-lib-kubelet
        hostPath:
          path: "/var/lib/kubelet"
      - name: etc-systemd
        hostPath:
          path: "/etc/systemd"
      - name: etc-kubernetes
        hostPath:
          path: "/etc/kubernetes"
      - name: usr-bin
        hostPath:
          path: "/usr/bin"
EOF
```

2. **Implement policy enforcement**:

```bash
# Open Policy Agent (OPA) Gatekeeper constraints
kubectl apply -f - <<EOF
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        openAPIV3Schema:
          type: object
          properties:
            labels:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels
        
        violation[{"msg": msg}] {
          required := input.parameters.labels
          provided := input.review.object.metadata.labels
          missing := required[_]
          not provided[missing]
          msg := sprintf("You must provide labels: %v", [missing])
        }
---
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: must-have-environment
spec:
  match:
    kinds:
      - apiGroups: ["apps"]
        kinds: ["Deployment"]
    namespaces: ["production"]
  parameters:
    labels: ["environment", "owner", "cost-center"]
EOF
```

## 💡 Production Best Practices

### 1. Cluster Management
- **Multi-Master Setup**: Always run multiple control plane nodes
- **ETCD Best Practices**: Regular backups, monitoring, separate storage
- **Node Management**: Regular updates, security patches, monitoring
- **Network**: Secure networking, proper CNI configuration
- **Storage**: Reliable storage classes, backup strategies

### 2. Application Deployment
- **GitOps**: Use Git as single source of truth
- **Progressive Delivery**: Canary, blue-green deployments
- **Health Checks**: Comprehensive health and readiness probes
- **Resource Management**: Proper requests, limits, and quotas
- **Configuration**: External configuration management

### 3. Security
- **RBAC**: Implement least privilege access
- **Network Policies**: Micro-segmentation
- **Image Security**: Scan images, use minimal base images
- **Secrets**: External secret management, rotation
- **Compliance**: Regular audits and compliance checks

### 4. Monitoring and Observability
- **SLI/SLO**: Define service level indicators and objectives
- **Alerting**: Actionable alerts with clear escalation
- **Logging**: Centralized logging with retention policies
- **Tracing**: Distributed tracing for complex applications
- **Dashboards**: Comprehensive monitoring dashboards

### 5. Disaster Recovery
- **Backup Strategy**: Regular, tested backups
- **RTO/RPO**: Define recovery objectives
- **Runbooks**: Detailed recovery procedures
- **Testing**: Regular disaster recovery drills
- **Documentation**: Keep procedures up to date

## 🔧 Troubleshooting Production Issues

### Common Production Problems

#### 1. Performance Issues
**Symptoms**: High latency, timeouts, slow responses
**Investigation**:
```bash
# Check resource utilization
kubectl top nodes
kubectl top pods --all-namespaces --sort-by=cpu

# Analyze application metrics
kubectl get hpa --all-namespaces
kubectl describe hpa <hpa-name> -n <namespace>

# Check for resource constraints
kubectl describe nodes | grep -A 5 "Allocated resources"
```

#### 2. Networking Problems
**Symptoms**: Service unreachable, DNS resolution failures
**Investigation**:
```bash
# Check service endpoints
kubectl get endpoints --all-namespaces
kubectl describe service <service-name> -n <namespace>

# Test DNS resolution
kubectl run dns-test --image=busybox --rm -it -- nslookup kubernetes.default

# Check network policies
kubectl get networkpolicies --all-namespaces
kubectl describe networkpolicy <policy-name> -n <namespace>
```

#### 3. Storage Issues
**Symptoms**: PVC stuck in pending, mount failures
**Investigation**:
```bash
# Check PV and PVC status
kubectl get pv,pvc --all-namespaces
kubectl describe pvc <pvc-name> -n <namespace>

# Check storage classes
kubectl get storageclass
kubectl describe storageclass <class-name>

# Check node storage
kubectl describe nodes | grep -A 10 "Capacity:"
```

### Production Troubleshooting Toolkit

```bash
# Create troubleshooting toolkit
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: troubleshooting-toolkit
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: troubleshooting-toolkit
  template:
    metadata:
      labels:
        name: troubleshooting-toolkit
    spec:
      hostNetwork: true
      hostPID: true
      containers:
      - name: toolkit
        image: nicolaka/netshoot
        command: ["sleep", "infinity"]
        securityContext:
          privileged: true
        volumeMounts:
        - name: host-root
          mountPath: /host
          readOnly: true
      volumes:
      - name: host-root
        hostPath:
          path: /
      tolerations:
      - operator: Exists
EOF
```

## 📝 Assessment Questions

1. **Architecture Design**: Design a production-ready Kubernetes cluster architecture for a financial services company with strict compliance requirements.

2. **Disaster Recovery**: Create a comprehensive disaster recovery plan including RTO/RPO definitions, backup strategies, and recovery procedures.

3. **Performance Optimization**: Analyze a slow-performing application and provide optimization recommendations including resource tuning, scaling strategies, and monitoring improvements.

4. **Security Assessment**: Conduct a security review of a Kubernetes cluster and provide hardening recommendations based on industry best practices.

5. **Cost Optimization**: Develop a cost optimization strategy for a multi-environment Kubernetes setup with recommendations for resource efficiency and cost reduction.

## 🎯 Module Summary

You have mastered:
- ✅ Production-ready cluster configuration and hardening
- ✅ Advanced deployment strategies and patterns
- ✅ Comprehensive disaster recovery and backup strategies
- ✅ Performance optimization and capacity planning
- ✅ Cost optimization and resource management
- ✅ Compliance and governance frameworks
- ✅ Operational excellence and SRE practices
- ✅ Advanced troubleshooting methodologies
- ✅ Production incident response procedures

## 🎉 Course Completion

Congratulations! You have completed the comprehensive Kubernetes learning journey. You now have:

### Technical Skills
- Deep understanding of Kubernetes architecture and components
- Hands-on experience with all major Kubernetes features
- Advanced skills in security, networking, and storage
- Production deployment and operational expertise
- Troubleshooting and performance optimization skills

### Practical Experience
- Built and deployed real-world applications
- Implemented CI/CD pipelines and GitOps workflows
- Created multi-tenant SaaS platforms
- Applied production best practices and security hardening
- Developed disaster recovery and monitoring solutions

### Career Readiness
- Industry-standard knowledge and skills
- Portfolio of practical projects
- Understanding of production challenges and solutions
- Preparation for Kubernetes certifications (CKA, CKAD, CKS)
- Ready for senior Kubernetes and DevOps roles

## 🏆 Next Steps

### Certification Paths
- **CKA (Certified Kubernetes Administrator)**: Focus on cluster administration
- **CKAD (Certified Kubernetes Application Developer)**: Focus on application development
- **CKS (Certified Kubernetes Security Specialist)**: Focus on security practices

### Advanced Topics to Explore
- **Service Mesh**: Istio, Linkerd, Consul Connect
- **GitOps**: ArgoCD, Flux, Tekton
- **Observability**: Jaeger, OpenTelemetry, Grafana
- **Multi-Cluster**: Cluster federation, cross-cluster networking
- **Edge Computing**: K3s, MicroK8s, edge deployments

### Community Involvement
- Contribute to open-source Kubernetes projects
- Join Kubernetes Special Interest Groups (SIGs)
- Attend KubeCon and other Kubernetes conferences
- Share knowledge through blogs and presentations

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [CNCF Landscape](https://landscape.cncf.io/)
- [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- [Production Best Practices](https://kubernetes.io/docs/setup/best-practices/)

---

**🚀 Final Words**: You've completed an intensive journey through Kubernetes. The knowledge and skills you've gained will serve you well in your career. Remember, technology evolves rapidly - keep learning, practicing, and sharing your knowledge with the community!

**Happy Kubernetes-ing! 🐳**
