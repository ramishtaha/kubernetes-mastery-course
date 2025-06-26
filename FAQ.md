# Frequently Asked Questions (FAQ)

This document provides answers to commonly asked questions during your Kubernetes learning journey.

## Table of Contents

- [General Questions](#general-questions)
- [Installation & Setup](#installation--setup)
- [Basic Operations](#basic-operations)
- [Networking](#networking)
- [Storage](#storage)
- [Security](#security)
- [Troubleshooting](#troubleshooting)
- [Production & Best Practices](#production--best-practices)

## General Questions

### Q: What is Kubernetes and why should I learn it?
**A:** Kubernetes (K8s) is an open-source container orchestration platform that automates the deployment, scaling, and management of containerized applications. Learning Kubernetes is essential because:
- It's the industry standard for container orchestration
- Enables microservices architecture
- Provides automated scaling and self-healing
- Essential for modern DevOps and cloud-native development
- High demand skill in the job market

### Q: What are the prerequisites for learning Kubernetes?
**A:** To effectively learn Kubernetes, you should have:
- Basic Linux command-line knowledge
- Understanding of containers and Docker
- Familiarity with YAML syntax
- Basic networking concepts (IP addresses, ports, DNS)
- Understanding of distributed systems concepts

### Q: How long does it take to learn Kubernetes?
**A:** Learning timelines vary, but typically:
- **Basic concepts**: 2-4 weeks
- **Intermediate skills**: 2-3 months
- **Advanced proficiency**: 6-12 months
- **Production expertise**: 1-2 years

### Q: Should I use minikube, kind, or a full cluster for learning?
**A:** Depends on your goals:
- **minikube**: Great for local development and basic learning
- **kind**: Excellent for testing and CI/CD
- **Full cluster**: Best for production-like experience (recommended for this course)
- **Cloud clusters**: Good for learning cloud-specific features

## Installation & Setup

### Q: What are the minimum system requirements?
**A:** For a basic single-node cluster:
- **CPU**: 2 cores minimum, 4 cores recommended
- **RAM**: 2GB minimum, 4GB recommended
- **Disk**: 20GB minimum, 50GB recommended
- **OS**: Ubuntu 20.04/22.04 LTS (recommended)

### Q: Why does the installation fail with "kubectl: command not found"?
**A:** This usually means:
1. kubectl is not installed: Run `./scripts/install-all.sh`
2. kubectl is not in PATH: Add `/usr/local/bin` to your PATH
3. Installation incomplete: Check installation logs

### Q: How do I verify my installation is successful?
**A:** Run these commands:
```bash
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces
```

### Q: Can I install Kubernetes on Windows or macOS?
**A:** Yes, but:
- **Windows**: Use WSL2 with Ubuntu or Docker Desktop
- **macOS**: Use Docker Desktop or Rancher Desktop
- **Best experience**: Native Linux installation

### Q: What's the difference between kubeadm, kubespray, and kops?
**A:**
- **kubeadm**: Official tool, good for learning and production
- **kubespray**: Ansible-based, highly customizable
- **kops**: AWS-focused, production-ready
- **Our course uses**: kubeadm for educational value

## Basic Operations

### Q: What's the difference between Deployment and Pod?
**A:**
- **Pod**: Single instance of running container(s), ephemeral
- **Deployment**: Manages multiple Pod replicas, provides updates and rollbacks
- **Use Deployment** for almost all applications

### Q: How do I access my application running in the cluster?
**A:** Several methods:
1. **Port forwarding**: `kubectl port-forward pod/my-pod 8080:80`
2. **NodePort service**: Exposes on node IP
3. **LoadBalancer service**: Uses cloud load balancer
4. **Ingress**: HTTP/HTTPS routing (recommended)

### Q: What's the difference between ConfigMap and Secret?
**A:**
- **ConfigMap**: Non-sensitive configuration data
- **Secret**: Sensitive data (passwords, tokens, keys)
- **Secrets are base64 encoded** (not encrypted!)
- **Use external secret management** for production

### Q: How do I update my application?
**A:** For Deployments:
```bash
# Update image
kubectl set image deployment/my-app container=new-image:tag

# Apply new manifest
kubectl apply -f updated-manifest.yaml

# Edit directly (not recommended for production)
kubectl edit deployment my-app
```

### Q: What happens when a Pod crashes?
**A:** Kubernetes will:
1. Restart the Pod (if restart policy allows)
2. Create a new Pod if the restart fails repeatedly
3. The Deployment ensures desired replicas are maintained
4. Use liveness and readiness probes for better detection

## Networking

### Q: How does networking work in Kubernetes?
**A:** Kubernetes networking is based on:
- **Cluster networking**: All Pods can communicate
- **Services**: Stable IP and DNS for Pod groups
- **Ingress**: HTTP/HTTPS routing to services
- **Network policies**: Security rules between Pods

### Q: What's the difference between ClusterIP, NodePort, and LoadBalancer services?
**A:**
- **ClusterIP**: Internal cluster access only (default)
- **NodePort**: Access via node IP and port (30000-32767)
- **LoadBalancer**: Cloud provider load balancer
- **ExternalName**: Maps to external DNS name

### Q: How do I troubleshoot network connectivity issues?
**A:** Use these tools:
```bash
# Test Pod to Pod connectivity
kubectl run test-pod --image=busybox --rm -it -- ping pod-ip

# Check DNS resolution
kubectl run test-pod --image=busybox --rm -it -- nslookup service-name

# Check service endpoints
kubectl get endpoints service-name

# Use troubleshooting script
./scripts/troubleshoot.sh network
```

### Q: What is an Ingress Controller and do I need one?
**A:** An Ingress Controller:
- Implements Ingress resources
- Provides HTTP/HTTPS routing
- **Yes, you need one** for web applications
- **Common options**: NGINX, Traefik, HAProxy

## Storage

### Q: What's the difference between volumes, PV, and PVC?
**A:**
- **Volume**: Storage attached to a Pod (ephemeral with Pod)
- **PersistentVolume (PV)**: Cluster-wide storage resource
- **PersistentVolumeClaim (PVC)**: Request for storage by Pod

### Q: How do I persist data in Kubernetes?
**A:** Use PersistentVolumes:
1. Create StorageClass (or use default)
2. Create PersistentVolumeClaim
3. Mount PVC in Pod/Deployment
4. Data persists beyond Pod lifecycle

### Q: What happens to my data when a Pod is deleted?
**A:** Depends on storage type:
- **emptyDir**: Deleted with Pod
- **hostPath**: Persists on node
- **PersistentVolume**: Persists according to reclaim policy
- **Cloud volumes**: Usually persist

### Q: How do I backup my data?
**A:** Several approaches:
- **Application-level**: Database dumps, file copies
- **Volume snapshots**: Cloud provider features
- **Backup tools**: Velero, Stash
- **Manual**: Copy data from running Pods

## Security

### Q: How does RBAC work in Kubernetes?
**A:** RBAC (Role-Based Access Control):
- **Users/ServiceAccounts**: Who
- **Roles/ClusterRoles**: What permissions
- **RoleBindings/ClusterRoleBindings**: Who has what permissions
- **Principle of least privilege**: Give minimum required permissions

### Q: What are Security Contexts?
**A:** Security Contexts define:
- User ID and Group ID for processes
- Capabilities (Linux capabilities)
- SELinux options
- Read-only root filesystem
- Privilege escalation settings

### Q: How do I secure secrets in Kubernetes?
**A:** Best practices:
- Use external secret management (Vault, AWS Secrets Manager)
- Enable encryption at rest
- Use RBAC to limit secret access
- Rotate secrets regularly
- Avoid putting secrets in images or code

### Q: What are Pod Security Policies?
**A:** Pod Security Policies (deprecated in 1.25):
- Controlled security-sensitive Pod settings
- **Replaced by**: Pod Security Standards
- **Use**: Pod Security Admission controller
- **Enforce**: Restricted, Baseline, or Privileged policies

## Troubleshooting

### Q: My Pod is stuck in Pending state. What should I do?
**A:** Common causes:
1. **Insufficient resources**: Check node resources
2. **PVC not bound**: Check storage availability
3. **Node selector**: Ensure matching nodes exist
4. **Taints/tolerations**: Check node taints
5. **Use our script**: `./scripts/troubleshoot.sh pods`

### Q: My Pod keeps crashing (CrashLoopBackOff). How do I debug?
**A:** Debug steps:
```bash
# Check Pod logs
kubectl logs pod-name --previous

# Describe Pod for events
kubectl describe pod pod-name

# Check resource limits
kubectl top pod pod-name

# Debug with shell (if possible)
kubectl exec -it pod-name -- /bin/sh
```

### Q: How do I access logs from multiple Pods?
**A:**
```bash
# All Pods in deployment
kubectl logs deployment/my-app

# All Pods with label
kubectl logs -l app=my-app

# Tail logs from all Pods
kubectl logs -f -l app=my-app --all-containers=true
```

### Q: My service is not accessible. How do I troubleshoot?
**A:** Check these:
```bash
# Service exists and has endpoints
kubectl get service my-service
kubectl get endpoints my-service

# Pod labels match service selector
kubectl describe service my-service

# Port configuration
kubectl get pods -o wide

# Network policies
kubectl get networkpolicy
```

### Q: How do I debug DNS issues?
**A:**
```bash
# Check CoreDNS Pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Test DNS resolution
kubectl run test --image=busybox --rm -it -- nslookup kubernetes.default

# Check DNS configuration
kubectl get configmap coredns -n kube-system -o yaml
```

## Production & Best Practices

### Q: How do I make my applications production-ready?
**A:** Essential practices:
- Set resource requests and limits
- Configure health checks (readiness/liveness probes)
- Use multiple replicas
- Configure Pod Disruption Budgets
- Implement monitoring and logging
- Use security contexts
- Plan for updates and rollbacks

### Q: How do I handle application updates with zero downtime?
**A:** Use rolling updates:
```bash
# Set update strategy
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0

# Update deployment
kubectl set image deployment/my-app container=new-image:tag

# Monitor rollout
kubectl rollout status deployment/my-app
```

### Q: How do I scale my applications?
**A:** Multiple scaling options:
```bash
# Manual scaling
kubectl scale deployment my-app --replicas=5

# Horizontal Pod Autoscaler
kubectl autoscale deployment my-app --min=2 --max=10 --cpu-percent=70

# Vertical Pod Autoscaler
# Requires VPA installation
```

### Q: What monitoring should I set up?
**A:** Essential monitoring:
- **Cluster metrics**: Node resources, Pod status
- **Application metrics**: Custom business metrics
- **Infrastructure**: Network, storage, compute
- **Logs**: Application and system logs
- **Alerts**: Proactive issue detection
- **Use our stack**: `kubectl apply -f manifests/monitoring/`

### Q: How do I backup my cluster?
**A:** Backup strategies:
- **etcd backup**: Critical for cluster state
- **Application data**: PV snapshots
- **Configuration**: Store manifests in Git
- **Tools**: Velero for cluster backup
- **Test restores**: Regularly verify backups work

### Q: How do I handle cluster upgrades?
**A:** Upgrade process:
1. **Plan**: Review release notes
2. **Test**: Upgrade non-production first
3. **Backup**: Backup etcd and important data
4. **Upgrade**: Control plane first, then nodes
5. **Verify**: Test applications after upgrade
6. **Rollback plan**: Be prepared to rollback

### Q: What are the most common production issues?
**A:** Common issues:
1. **Resource exhaustion**: Out of CPU/memory
2. **Storage full**: Disk space issues
3. **Network policies**: Blocking required traffic
4. **Image pull errors**: Registry issues
5. **Configuration errors**: Wrong environment variables
6. **DNS issues**: CoreDNS problems
7. **Certificate expiration**: TLS cert issues

### Q: How do I get help when I'm stuck?
**A:** Resources for help:
1. **Official docs**: kubernetes.io
2. **Community**: Kubernetes Slack, Stack Overflow
3. **Our troubleshooting**: `./scripts/troubleshoot.sh`
4. **Logs and diagnostics**: `./scripts/troubleshoot.sh diagnostics`
5. **GitHub issues**: For specific tools
6. **Local user groups**: Kubernetes meetups

---

## Additional Resources

### Documentation
- [Official Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kubernetes API Reference](https://kubernetes.io/docs/reference/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

### Learning Platforms
- [Kubernetes Academy](https://kubernetes.academy/)
- [CNCF Training](https://training.cncf.io/)
- [Hands-on Labs](https://labs.play-with-k8s.com/)

### Tools and Extensions
- [K9s](https://k9scli.io/) - Terminal UI for Kubernetes
- [Lens](https://k8slens.dev/) - Desktop IDE for Kubernetes
- [kubectx/kubens](https://github.com/ahmetb/kubectx) - Context and namespace switching

### Certification
- [Certified Kubernetes Administrator (CKA)](https://training.linuxfoundation.org/certification/certified-kubernetes-administrator-cka/)
- [Certified Kubernetes Application Developer (CKAD)](https://training.linuxfoundation.org/certification/certified-kubernetes-application-developer-ckad/)
- [Certified Kubernetes Security Specialist (CKS)](https://training.linuxfoundation.org/certification/certified-kubernetes-security-specialist/)

---

*This FAQ is part of the Comprehensive Kubernetes Learning Project. For more information, see the main [README.md](../README.md).*
