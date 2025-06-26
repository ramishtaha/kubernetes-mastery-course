# Kubernetes Examples Directory

This directory contains practical, real-world examples that demonstrate various Kubernetes concepts and patterns.

## Directory Structure

```
examples/
├── README.md                     # This file
├── basic-workloads/             # Simple Pod, Deployment, Service examples
├── configuration/               # ConfigMap, Secret examples
├── storage-examples/            # Volume and persistence examples
├── networking-examples/         # Service, Ingress examples
├── security-examples/           # RBAC, SecurityContext examples
├── monitoring-examples/         # Metrics and logging examples
├── scaling-examples/            # HPA, VPA examples
├── troubleshooting-examples/    # Common issues and solutions
└── production-patterns/         # Production-ready patterns
```

## Example Categories

### 1. Basic Workloads
Simple examples to get started with core Kubernetes objects.

**Topics Covered:**
- Pod basics
- Deployment patterns
- Service types
- Basic networking

**Use Cases:**
- Learning fundamentals
- Testing concepts
- Development environments

### 2. Configuration Management
Examples of how to manage application configuration in Kubernetes.

**Topics Covered:**
- ConfigMaps for non-sensitive data
- Secrets for sensitive data
- Environment variables
- Volume mounts

**Use Cases:**
- Environment-specific configurations
- Secure credential management
- Dynamic configuration updates

### 3. Storage Examples
Persistent storage patterns and volume management.

**Topics Covered:**
- PersistentVolumes and PersistentVolumeClaims
- StorageClasses
- StatefulSets
- Data backup and recovery

**Use Cases:**
- Database deployments
- File storage
- Data persistence

### 4. Networking Examples
Service discovery, load balancing, and traffic routing.

**Topics Covered:**
- Service types and selectors
- Ingress controllers
- Network policies
- DNS and service discovery

**Use Cases:**
- Application exposure
- Traffic routing
- Security boundaries

### 5. Security Examples
Security best practices and implementations.

**Topics Covered:**
- RBAC (Role-Based Access Control)
- SecurityContexts
- NetworkPolicies
- PodSecurityPolicies

**Use Cases:**
- Access control
- Container security
- Network security

### 6. Monitoring Examples
Observability and monitoring implementations.

**Topics Covered:**
- Metrics collection
- Log aggregation
- Health checks
- Alerting

**Use Cases:**
- Application monitoring
- Infrastructure monitoring
- Troubleshooting

### 7. Scaling Examples
Horizontal and vertical scaling patterns.

**Topics Covered:**
- Horizontal Pod Autoscaling (HPA)
- Vertical Pod Autoscaling (VPA)
- Cluster autoscaling
- Manual scaling

**Use Cases:**
- Performance optimization
- Cost optimization
- Traffic handling

### 8. Troubleshooting Examples
Common issues and their solutions.

**Topics Covered:**
- Pod startup issues
- Network connectivity problems
- Resource constraints
- Storage issues

**Use Cases:**
- Problem diagnosis
- Learning from failures
- Preventive measures

### 9. Production Patterns
Production-ready deployment patterns.

**Topics Covered:**
- Blue-green deployments
- Canary releases
- Circuit breakers
- Disaster recovery

**Use Cases:**
- Production deployments
- Risk mitigation
- High availability

## How to Use These Examples

### 1. Prerequisites
Before running examples, ensure you have:
- A working Kubernetes cluster
- kubectl configured
- Basic understanding of Kubernetes concepts

### 2. Running Examples
Each example includes:
- README with explanation
- YAML manifests
- Step-by-step instructions
- Expected outcomes

### 3. Example Format
```bash
# Navigate to example directory
cd examples/basic-workloads/simple-pod/

# Read the README
cat README.md

# Apply the example
kubectl apply -f .

# Follow instructions to test
# ...

# Clean up
kubectl delete -f .
```

### 4. Learning Path
Recommended order for beginners:
1. Start with **basic-workloads**
2. Move to **configuration**
3. Explore **storage-examples**
4. Learn **networking-examples**
5. Study **security-examples**
6. Practice **troubleshooting-examples**
7. Implement **monitoring-examples**
8. Master **scaling-examples**
9. Apply **production-patterns**

## Example Naming Convention

Examples follow a consistent naming pattern:
- **Directory**: Descriptive name (e.g., `simple-pod`, `configmap-basic`)
- **Files**: Clear purpose (e.g., `pod.yaml`, `service.yaml`)
- **Labels**: Consistent labeling for easy identification

## Testing and Validation

Each example includes:
- **Validation steps**: How to verify it's working
- **Expected output**: What you should see
- **Troubleshooting**: Common issues and fixes
- **Cleanup**: How to remove resources

## Contributing Examples

To add new examples:
1. Follow the directory structure
2. Include comprehensive README
3. Add validation steps
4. Test thoroughly
5. Update this main README

## Quick Reference

### Useful Commands for Examples
```bash
# Apply all files in directory
kubectl apply -f .

# Delete all files in directory
kubectl delete -f .

# Watch resources being created
kubectl get pods -w

# Get all resources with labels
kubectl get all -l app=example

# Describe resource for details
kubectl describe pod example-pod

# Check logs
kubectl logs example-pod

# Port forward for testing
kubectl port-forward pod/example-pod 8080:80
```

### Common Labels Used
All examples use consistent labels:
- `app`: Application name
- `component`: Component type (frontend, backend, database)
- `version`: Version or release
- `environment`: Environment (dev, staging, prod)
- `example`: Example category

## Resources and References

### Official Documentation
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)
- [API Reference](https://kubernetes.io/docs/reference/)

### Best Practices
- [Configuration Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [Monitoring Best Practices](https://kubernetes.io/docs/tasks/debug-application-cluster/)

### Tools
- [Kustomize](https://kustomize.io/) - Configuration management
- [Helm](https://helm.sh/) - Package manager
- [Skaffold](https://skaffold.dev/) - Development workflow

## Support and Troubleshooting

If you encounter issues:
1. Check the example's README
2. Verify prerequisites are met
3. Use our troubleshooting script: `../scripts/troubleshoot.sh`
4. Check the main project's troubleshooting guide
5. Review the FAQ: `../FAQ.md`

---

*These examples are part of the Comprehensive Kubernetes Learning Project. For more information, see the main [README.md](../README.md).*
