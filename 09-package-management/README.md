# Module 9: Package Management

## 📚 Learning Objectives

By the end of this module, you will understand:
- Package management concepts in Kubernetes
- Helm: the package manager for Kubernetes
- Creating and managing Helm charts
- Kustomize for configuration management
- Template engines and configuration strategies
- Best practices for application deployment
- Managing application lifecycles with packages

## 🎯 Prerequisites

- Completed Module 8: Monitoring and Logging
- Understanding of YAML and templating concepts
- Basic knowledge of application deployment patterns

## 📖 Theory: Package Management in Kubernetes

### Why Package Management?

Kubernetes applications often consist of multiple resources:
- Deployments, Services, ConfigMaps, Secrets
- RBAC configurations
- Ingress rules, Network Policies
- Monitoring and logging configurations

Package managers help by:
- **Templating**: Reusable configurations with parameters
- **Versioning**: Track and rollback application versions
- **Dependencies**: Manage complex application dependencies
- **Lifecycle**: Install, upgrade, and uninstall applications

### Helm Overview

Helm is the most popular Kubernetes package manager:

#### Key Concepts
- **Chart**: A Helm package containing Kubernetes manifests
- **Release**: An instance of a chart deployed to a cluster
- **Repository**: A collection of charts
- **Values**: Configuration parameters for charts

#### Helm Architecture
- **Helm Client**: CLI tool for managing charts and releases
- **Charts**: Template-based Kubernetes manifests
- **Repositories**: Centralized chart storage

### Kustomize Overview

Kustomize is a template-free configuration management tool:
- **Base**: Common configurations
- **Overlays**: Environment-specific customizations
- **Patches**: Targeted modifications
- **Built into kubectl**: Native Kubernetes support

## 🧪 Hands-on Labs

### Lab 1: Helm Installation and Basic Usage

1. **Install Helm**:

```bash
# Download and install Helm (Linux/macOS)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# For Windows (using Chocolatey)
# choco install kubernetes-helm

# Verify installation
helm version
```

2. **Add popular Helm repositories**:

```bash
# Add stable repository
helm repo add stable https://charts.helm.sh/stable

# Add bitnami repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Add ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Update repositories
helm repo update

# List repositories
helm repo list

# Search for charts
helm search repo nginx
helm search repo mysql
```

3. **Deploy an application using Helm**:

```bash
# Install WordPress using Bitnami chart
helm install my-wordpress bitnami/wordpress \
  --set wordpressUsername=admin \
  --set wordpressPassword=password123 \
  --set mariadb.auth.rootPassword=secretpassword \
  --set service.type=NodePort

# Check release status
helm status my-wordpress

# List all releases
helm list

# Get release values
helm get values my-wordpress
```

4. **Manage the release**:

```bash
# Upgrade the release with new values
helm upgrade my-wordpress bitnami/wordpress \
  --set wordpressUsername=admin \
  --set wordpressPassword=newpassword123 \
  --set mariadb.auth.rootPassword=secretpassword \
  --set service.type=NodePort \
  --set replicaCount=2

# Check revision history
helm history my-wordpress

# Rollback to previous version
helm rollback my-wordpress 1

# Uninstall the release
helm uninstall my-wordpress
```

### Lab 2: Creating Your First Helm Chart

1. **Create a new chart**:

```bash
# Create a new chart
helm create my-app

# Explore the chart structure
ls -la my-app/
cat my-app/Chart.yaml
cat my-app/values.yaml
ls -la my-app/templates/
```

2. **Customize the chart**:

```bash
# Edit Chart.yaml
cat > my-app/Chart.yaml <<EOF
apiVersion: v2
name: my-app
description: A simple web application Helm chart
type: application
version: 0.1.0
appVersion: "1.0.0"
EOF

# Edit values.yaml
cat > my-app/values.yaml <<EOF
replicaCount: 2

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.20"

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 100
  targetCPUUtilizationPercentage: 80

nodeSelector: {}
tolerations: []
affinity: {}

env:
  - name: ENV
    value: "production"
EOF
```

3. **Create custom templates**:

```bash
# Create a ConfigMap template
cat > my-app/templates/configmap.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "my-app.fullname" . }}-config
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
data:
  app.properties: |
    environment={{ .Values.env | first | default "development" }}
    replicas={{ .Values.replicaCount }}
    image={{ .Values.image.repository }}:{{ .Values.image.tag }}
EOF

# Update deployment template to use the ConfigMap
cat > my-app/templates/deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-app.fullname" . }}
  labels:
    {{- include "my-app.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "my-app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "my-app.selectorLabels" . | nindent 8 }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
          env:
            {{- toYaml .Values.env | nindent 12 }}
          volumeMounts:
            - name: config
              mountPath: /etc/config
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
      volumes:
        - name: config
          configMap:
            name: {{ include "my-app.fullname" . }}-config
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
EOF
```

4. **Test and deploy your chart**:

```bash
# Validate chart syntax
helm lint my-app

# Test template rendering
helm template my-app my-app/

# Test installation (dry run)
helm install my-app-test my-app --dry-run --debug

# Install the chart
helm install my-app-release my-app

# Check deployment
kubectl get all -l app.kubernetes.io/instance=my-app-release

# Check ConfigMap
kubectl get configmap -l app.kubernetes.io/instance=my-app-release
kubectl describe configmap my-app-release-config
```

### Lab 3: Advanced Helm Features

1. **Chart dependencies**:

```bash
# Create a new chart with dependencies
helm create webapp-with-db

# Add dependency to Chart.yaml
cat > webapp-with-db/Chart.yaml <<EOF
apiVersion: v2
name: webapp-with-db
description: Web application with database dependency
type: application
version: 0.1.0
appVersion: "1.0.0"

dependencies:
  - name: mysql
    version: 9.4.10
    repository: https://charts.bitnami.com/bitnami
    condition: mysql.enabled
EOF

# Update values.yaml to configure the dependency
cat > webapp-with-db/values.yaml <<EOF
replicaCount: 1

image:
  repository: nginx
  tag: "1.20"

service:
  type: ClusterIP
  port: 80

mysql:
  enabled: true
  auth:
    rootPassword: "rootpassword"
    database: "myapp"
    username: "myuser"
    password: "mypassword"
  primary:
    persistence:
      enabled: false
EOF

# Download dependencies
helm dependency update webapp-with-db

# Install chart with dependencies
helm install webapp-db webapp-with-db
```

2. **Using Helm hooks**:

```bash
# Create a pre-install job
cat > webapp-with-db/templates/pre-install-job.yaml <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "webapp-with-db.fullname" . }}-pre-install
  labels:
    {{- include "webapp-with-db.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": pre-install
    "helm.sh/hook-weight": "-5"
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: pre-install
        image: busybox
        command:
        - /bin/sh
        - -c
        - |
          echo "Pre-install hook: Preparing database..."
          sleep 10
          echo "Pre-install hook completed!"
EOF

# Create a post-install job
cat > webapp-with-db/templates/post-install-job.yaml <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "webapp-with-db.fullname" . }}-post-install
  labels:
    {{- include "webapp-with-db.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": post-install
    "helm.sh/hook-weight": "1"
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: post-install
        image: busybox
        command:
        - /bin/sh
        - -c
        - |
          echo "Post-install hook: Configuring application..."
          sleep 5
          echo "Application is ready!"
EOF

# Reinstall to see hooks in action
helm uninstall webapp-db
helm install webapp-db webapp-with-db
```

### Lab 4: Introduction to Kustomize

1. **Create base configuration**:

```bash
# Create directory structure
mkdir -p kustomize-example/{base,overlays/{development,production}}

# Create base kustomization
cat > kustomize-example/base/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml

commonLabels:
  app: my-kustomize-app
EOF

# Create base deployment
cat > kustomize-example/base/deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web
        image: nginx:1.20
        ports:
        - containerPort: 80
        env:
        - name: ENV
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: environment
EOF

# Create base service
cat > kustomize-example/base/service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

# Create base configmap
cat > kustomize-example/base/configmap.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  environment: "base"
  debug: "false"
EOF
```

2. **Create development overlay**:

```bash
# Development kustomization
cat > kustomize-example/overlays/development/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
  - ../../base

patchesStrategicMerge:
  - deployment-patch.yaml

configMapGenerator:
  - name: app-config
    behavior: merge
    literals:
      - environment=development
      - debug=true

namePrefix: dev-
namespace: development
EOF

# Development deployment patch
cat > kustomize-example/overlays/development/deployment-patch.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 2
  template:
    spec:
      containers:
      - name: web
        image: nginx:1.21-alpine
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
EOF
```

3. **Create production overlay**:

```bash
# Production kustomization
cat > kustomize-example/overlays/production/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
  - ../../base

patchesStrategicMerge:
  - deployment-patch.yaml
  - service-patch.yaml

configMapGenerator:
  - name: app-config
    behavior: merge
    literals:
      - environment=production
      - debug=false

namePrefix: prod-
namespace: production
EOF

# Production deployment patch
cat > kustomize-example/overlays/production/deployment-patch.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: web
        image: nginx:1.20
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
EOF

# Production service patch
cat > kustomize-example/overlays/production/service-patch.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: LoadBalancer
EOF
```

4. **Deploy using Kustomize**:

```bash
# Create namespaces
kubectl create namespace development
kubectl create namespace production

# Preview development build
kubectl kustomize kustomize-example/overlays/development

# Deploy development
kubectl apply -k kustomize-example/overlays/development

# Preview production build
kubectl kustomize kustomize-example/overlays/production

# Deploy production
kubectl apply -k kustomize-example/overlays/production

# Check deployments
kubectl get all -n development
kubectl get all -n production

# Compare ConfigMaps
kubectl get configmap -n development dev-app-config -o yaml
kubectl get configmap -n production prod-app-config -o yaml
```

### Lab 5: Helm vs Kustomize Comparison

1. **Convert Helm chart to Kustomize**:

```bash
# Generate manifests from Helm chart
helm template my-app my-app/ > helm-generated.yaml

# Create Kustomize version
mkdir -p helm-to-kustomize/{base,environments/{dev,prod}}

# Split the generated YAML into separate files
# (In practice, you'd use tools or scripts for this)
# For demo, we'll create a simple structure

cat > helm-to-kustomize/base/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml

commonLabels:
  app: helm-to-kustomize
EOF
```

2. **Performance and complexity comparison**:

```bash
# Time Helm deployment
time helm install perf-test-helm my-app

# Time Kustomize deployment
time kubectl apply -k kustomize-example/overlays/development

# Check resource consumption
kubectl top pods -n development
kubectl top pods -l app.kubernetes.io/instance=perf-test-helm
```

## 💡 Best Practices

### 1. Helm Best Practices
- Use semantic versioning for charts
- Implement proper chart testing
- Document chart values and usage
- Use chart repositories for sharing
- Implement security scanning for charts

### 2. Kustomize Best Practices
- Keep base configurations simple and reusable
- Use meaningful overlay names
- Implement proper directory structure
- Use generators for dynamic content
- Document customization patterns

### 3. Package Management Strategy
- Choose the right tool for your use case
- Implement proper CI/CD integration
- Use version control for configurations
- Implement automated testing
- Plan for rollback strategies

### 4. Security Considerations
- Scan container images in packages
- Implement RBAC for package management
- Use sealed secrets or external secret management
- Validate configurations before deployment
- Audit package installations

## 🔧 Troubleshooting Package Management

### Common Problems and Solutions

#### 1. Helm Installation Failures

**Problem**: Helm chart installation fails
**Diagnosis**:
```bash
helm install <release> <chart> --dry-run --debug
helm lint <chart>
kubectl describe pod <pod-name>
```

**Solutions**:
- Check chart syntax and values
- Verify resource quotas and limits
- Check RBAC permissions
- Validate image availability

#### 2. Kustomize Build Errors

**Problem**: Kustomize fails to build manifests
**Diagnosis**:
```bash
kubectl kustomize <path> --enable-helm
kustomize build <path>
```

**Solutions**:
- Check kustomization.yaml syntax
- Verify resource paths
- Check patch compatibility
- Validate base configurations

#### 3. Template Rendering Issues

**Problem**: Templates don't render correctly
**Diagnosis**:
```bash
helm template <release> <chart> --debug
kubectl kustomize <path> --enable-alpha-plugins
```

**Solutions**:
- Check template syntax
- Verify variable scoping
- Test with different values
- Use debugging outputs

### Package Management Commands

```bash
# Helm troubleshooting
helm status <release>
helm get values <release>
helm history <release>
helm rollback <release> <revision>

# Kustomize troubleshooting
kubectl kustomize <path>
kubectl diff -k <path>
kubectl apply -k <path> --dry-run=client

# General debugging
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl describe <resource> <name>
```

## 📝 Assessment Questions

1. **Multiple Choice**: What is the main difference between Helm and Kustomize?
   - a) Helm uses templates, Kustomize uses patches
   - b) Helm is for production, Kustomize is for development
   - c) Helm requires a server, Kustomize doesn't
   - d) Helm is older, Kustomize is newer

2. **Multiple Choice**: What file defines dependencies in a Helm chart?
   - a) values.yaml
   - b) Chart.yaml
   - c) requirements.yaml
   - d) dependencies.yaml

3. **Practical**: Create a Helm chart for a web application with a database dependency that can be deployed in different environments with different configurations.

4. **Scenario**: Design a package management strategy for a microservices application with 10+ services that need to be deployed across development, staging, and production environments.

## 🎯 Module Summary

You have learned:
- ✅ Package management concepts and benefits
- ✅ Helm installation, usage, and chart creation
- ✅ Advanced Helm features (dependencies, hooks, repositories)
- ✅ Kustomize for template-free configuration management
- ✅ Comparison between Helm and Kustomize
- ✅ Best practices for package management
- ✅ Troubleshooting package deployment issues
- ✅ Integration with CI/CD pipelines

## 🔄 Next Steps

Ready for the next module? Continue to:
**[Module 10: Advanced Concepts](../10-advanced-concepts/README.md)**

## 📚 Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Kustomize Documentation](https://kustomize.io/)
- [Helm Chart Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Kubernetes Package Management Patterns](https://kubernetes.io/docs/concepts/configuration/)

---

**📦 Package Management Tip**: Choose your packaging strategy based on your team's needs, complexity requirements, and operational preferences. Both Helm and Kustomize have their place in the Kubernetes ecosystem!
