# Kubernetes Manifests Collection

This directory contains reusable Kubernetes manifest files organized by complexity and use case. These manifests are designed to be production-ready and follow best practices.

## 📁 Directory Structure

```
manifests/
├── basic/                    # Simple, single-resource manifests
├── multi-tier/              # Multi-tier applications
├── security/                # Security-focused manifests
├── storage/                 # Storage configurations
├── networking/              # Networking examples
├── monitoring/              # Monitoring and observability
├── production/              # Production-ready templates
└── examples/                # Complete application examples
```

## 🚀 Quick Start

### Apply Basic Manifests
```bash
# Apply all basic manifests
kubectl apply -f basic/

# Apply specific manifest
kubectl apply -f basic/pod.yaml
```

### Apply Multi-Tier Application
```bash
# Apply complete web application stack
kubectl apply -f multi-tier/web-app/
```

### Security Examples
```bash
# Apply security configurations
kubectl apply -f security/
```

## � Manifest Categories

### Basic Resources
- **Pods**: Simple pod configurations with various features
- **Deployments**: Basic deployment patterns
- **Services**: Different service types and configurations
- **ConfigMaps/Secrets**: Configuration management examples

### Multi-Tier Applications
- **Web Applications**: Frontend, backend, database tiers
- **Microservices**: Complete microservice architectures
- **E-commerce**: Full e-commerce platform example

### Security
- **RBAC**: Role-based access control examples
- **Network Policies**: Traffic control and isolation
- **Pod Security**: Security contexts and constraints
- **Admission Controllers**: Policy enforcement

### Storage
- **Persistent Volumes**: Various storage configurations
- **StatefulSets**: Stateful application patterns
- **Backup Solutions**: Data backup and recovery

### Networking
- **Ingress**: External access configurations
- **Service Mesh**: Service mesh setup examples
- **Load Balancing**: Traffic distribution patterns

### Monitoring
- **Prometheus**: Monitoring stack setup
- **Grafana**: Visualization dashboards
- **Alerting**: Alert rules and notifications
- **Logging**: Log collection and aggregation

### Production
- **High Availability**: HA configurations
- **Auto-scaling**: Horizontal and vertical scaling
- **Disaster Recovery**: Backup and recovery setups
- **Performance**: Optimized configurations

### CI/CD
- **Jenkins**: CI/CD pipeline examples
- **GitLab CI**: GitLab integrated CI/CD
- **ArgoCD**: GitOps continuous delivery

## � Usage Examples

### Deploy a Basic Web Application
```bash
kubectl apply -f basic/web-app/
```

### Set Up Multi-Tier Application
```bash
kubectl apply -f multi-tier/ecommerce/
```

### Configure Monitoring Stack
```bash
kubectl apply -f monitoring/prometheus/
```

### Advanced Networking and Microservices
```bash
kubectl apply -f networking/ingress-microservices.yaml
```

### CI/CD Pipeline Setup
```bash
kubectl apply -f cicd/jenkins-gitlab-argocd.yaml
```

## 🔧 Customization

Before deploying:
1. Review the manifest files
2. Update image tags and configurations
3. Modify resource requests and limits
4. Adjust replicas based on your needs

## 📖 Learning Path

1. **Start with basic/** - Simple pod and service examples
2. **Progress to multi-tier/** - Complex application architectures
3. **Explore security/** - Security contexts and policies
4. **Study storage/** - Persistent volumes and claims
5. **Master networking/** - Ingress and network policies
6. **Implement monitoring/** - Observability stack
7. **Deploy production/** - Production-ready configurations
8. **Set up cicd/** - CI/CD pipelines and automation

---

**Note**: Always review and understand manifests before applying them to production clusters!
