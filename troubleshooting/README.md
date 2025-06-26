# Kubernetes Troubleshooting Guide

This comprehensive guide helps you diagnose and resolve common Kubernetes issues during your learning journey.

## 📋 Quick Diagnostic Commands

```bash
# Cluster Health Overview
kubectl get nodes                          # Check node status
kubectl get pods --all-namespaces         # Check all pods
kubectl get events --sort-by='.lastTimestamp' | tail -20  # Recent events
kubectl cluster-info                       # Cluster endpoints
kubectl top nodes                          # Resource usage

# Component Status
kubectl get componentstatuses             # Control plane health
kubectl get pods -n kube-system          # System pods
```

## 🚨 Common Issues and Solutions

### 1. Pod Issues

#### Pod Stuck in Pending State
**Symptoms**: Pod remains in Pending status indefinitely

**Diagnosis**:
```bash
kubectl describe pod <pod-name>
kubectl get events --field-selector involvedObject.name=<pod-name>
```

**Common Causes & Solutions**:

1. **Insufficient Resources**
   ```bash
   # Check node resources
   kubectl top nodes
   kubectl describe nodes
   
   # Solution: Reduce resource requests or add more nodes
   ```

2. **No Available Nodes**
   ```bash
   # Check node readiness
   kubectl get nodes
   
   # Solution: Ensure nodes are Ready and not cordoned
   kubectl uncordon <node-name>
   ```

3. **Taints Preventing Scheduling**
   ```bash
   # Check node taints
   kubectl describe node <node-name> | grep Taints
   
   # Solution: Remove taints or add tolerations
   kubectl taint nodes <node-name> <taint-key>-
   ```

4. **Missing Persistent Volume**
   ```bash
   # Check PVCs
   kubectl get pvc
   
   # Solution: Create PV or configure dynamic provisioning
   ```

#### Pod Stuck in ContainerCreating State
**Symptoms**: Pod shows ContainerCreating for extended time

**Diagnosis**:
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name> -c <container-name>
```

**Common Causes & Solutions**:

1. **Image Pull Issues**
   ```bash
   # Check image pull policy and registry access
   # Solution: Verify image name, tag, and registry credentials
   ```

2. **Volume Mount Issues**
   ```bash
   # Check volume mounts and storage
   kubectl get pv,pvc
   # Solution: Ensure volumes exist and are accessible
   ```

3. **Network Plugin Issues**
   ```bash
   # Check CNI pods
   kubectl get pods -n kube-system | grep -E "(calico|flannel|weave)"
   # Solution: Restart network plugin pods
   ```

#### Pod CrashLoopBackOff
**Symptoms**: Pod continuously crashes and restarts

**Diagnosis**:
```bash
kubectl logs <pod-name> --previous
kubectl describe pod <pod-name>
kubectl get events --field-selector involvedObject.name=<pod-name>
```

**Common Causes & Solutions**:

1. **Application Errors**
   ```bash
   # Check application logs
   kubectl logs <pod-name> -f
   # Solution: Fix application configuration or code
   ```

2. **Resource Limits**
   ```bash
   # Check resource usage
   kubectl top pod <pod-name>
   # Solution: Increase memory/CPU limits
   ```

3. **Health Check Failures**
   ```bash
   # Check liveness/readiness probes
   kubectl describe pod <pod-name>
   # Solution: Adjust probe configuration
   ```

### 2. Service Issues

#### Service Not Accessible
**Symptoms**: Cannot reach service endpoints

**Diagnosis**:
```bash
kubectl get svc
kubectl describe svc <service-name>
kubectl get endpoints <service-name>
```

**Common Causes & Solutions**:

1. **Incorrect Selector**
   ```bash
   # Check if service selector matches pod labels
   kubectl get pods --show-labels
   # Solution: Update service selector or pod labels
   ```

2. **Port Configuration**
   ```bash
   # Verify port mappings
   kubectl describe svc <service-name>
   # Solution: Check targetPort matches container port
   ```

3. **Network Policy Blocking Traffic**
   ```bash
   # Check network policies
   kubectl get networkpolicies
   # Solution: Update or remove restrictive policies
   ```

### 3. Deployment Issues

#### Deployment Not Rolling Out
**Symptoms**: Deployment stuck in progress

**Diagnosis**:
```bash
kubectl rollout status deployment/<deployment-name>
kubectl describe deployment <deployment-name>
kubectl get rs  # Check ReplicaSets
```

**Common Causes & Solutions**:

1. **Image Pull Failures**
   ```bash
   # Check pod events
   kubectl describe pods -l app=<app-label>
   # Solution: Verify image exists and is accessible
   ```

2. **Resource Constraints**
   ```bash
   # Check resource quotas
   kubectl describe resourcequota -n <namespace>
   # Solution: Increase quotas or reduce resource requests
   ```

3. **Readiness Probe Failures**
   ```bash
   # Check pod readiness
   kubectl get pods -l app=<app-label>
   # Solution: Fix application or adjust probe settings
   ```

### 4. Node Issues

#### Node NotReady State
**Symptoms**: Node shows NotReady status

**Diagnosis**:
```bash
kubectl describe node <node-name>
kubectl get events --field-selector involvedObject.name=<node-name>
```

**Common Causes & Solutions**:

1. **kubelet Issues**
   ```bash
   # Check kubelet on the node
   sudo systemctl status kubelet
   sudo journalctl -u kubelet -f
   # Solution: Restart kubelet service
   sudo systemctl restart kubelet
   ```

2. **Network Issues**
   ```bash
   # Test network connectivity
   ping <api-server-ip>
   # Solution: Fix network configuration
   ```

3. **Disk/Memory Pressure**
   ```bash
   # Check node resources
   df -h
   free -h
   # Solution: Clean up disk space or add resources
   ```

### 5. DNS Issues

#### Service Discovery Not Working
**Symptoms**: Pods cannot resolve service names

**Diagnosis**:
```bash
# Test DNS resolution from a pod
kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup kubernetes
kubectl get pods -n kube-system | grep coredns
```

**Common Causes & Solutions**:

1. **CoreDNS Not Running**
   ```bash
   kubectl get pods -n kube-system -l k8s-app=kube-dns
   # Solution: Check CoreDNS deployment and logs
   kubectl logs -n kube-system -l k8s-app=kube-dns
   ```

2. **DNS Configuration Issues**
   ```bash
   kubectl get configmap coredns -n kube-system -o yaml
   # Solution: Verify CoreDNS configuration
   ```

## 🔧 Diagnostic Tools and Commands

### System-Level Diagnostics

```bash
# Node Information
kubectl get nodes -o wide
kubectl describe node <node-name>
kubectl top nodes

# Cluster Information
kubectl cluster-info
kubectl cluster-info dump > cluster-dump.yaml

# API Server Health
kubectl get --raw /healthz
kubectl get --raw /version

# Component Status
kubectl get componentstatuses
```

### Application-Level Diagnostics

```bash
# Pod Diagnostics
kubectl get pods -o wide
kubectl describe pod <pod-name>
kubectl logs <pod-name> --previous
kubectl logs <pod-name> -f
kubectl logs <pod-name> -c <container-name>

# Service Diagnostics
kubectl get svc
kubectl describe svc <service-name>
kubectl get endpoints

# Deployment Diagnostics
kubectl get deployments
kubectl describe deployment <deployment-name>
kubectl rollout status deployment/<deployment-name>
kubectl rollout history deployment/<deployment-name>

# ReplicaSet Diagnostics
kubectl get rs
kubectl describe rs <rs-name>
```

### Network Diagnostics

```bash
# Network Policy
kubectl get networkpolicies
kubectl describe networkpolicy <policy-name>

# Ingress
kubectl get ingress
kubectl describe ingress <ingress-name>

# DNS Testing
kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup <service-name>
kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup <service-name>.<namespace>.svc.cluster.local
```

### Resource and Performance Diagnostics

```bash
# Resource Usage
kubectl top nodes
kubectl top pods
kubectl top pods --all-namespaces

# Resource Quotas
kubectl get resourcequota --all-namespaces
kubectl describe resourcequota <quota-name> -n <namespace>

# Limit Ranges
kubectl get limitrange --all-namespaces
kubectl describe limitrange <limitrange-name> -n <namespace>
```

## 📊 Monitoring and Alerting

### Event Monitoring

```bash
# Watch events in real-time
kubectl get events --watch

# Sort events by timestamp
kubectl get events --sort-by='.lastTimestamp'

# Filter events by type
kubectl get events --field-selector type=Warning

# Events for specific object
kubectl get events --field-selector involvedObject.name=<object-name>
```

### Log Aggregation

```bash
# Collect logs from multiple pods
kubectl logs -l app=<app-name> --all-containers=true

# Follow logs from multiple pods
kubectl logs -f -l app=<app-name> --all-containers=true

# Get logs from previous container instance
kubectl logs <pod-name> --previous
```

## 🚨 Emergency Procedures

### Complete Cluster Reset

```bash
#!/bin/bash
# Use only as last resort for learning environments

echo "⚠️  WARNING: This will destroy your cluster!"
read -p "Type 'DELETE' to confirm: " confirm

if [ "$confirm" = "DELETE" ]; then
    # Reset kubeadm
    sudo kubeadm reset -f
    
    # Clean up config
    rm -rf ~/.kube
    
    # Clean up iptables
    sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
    
    # Remove CNI interfaces
    sudo ip link delete cni0 2>/dev/null || true
    sudo ip link delete flannel.1 2>/dev/null || true
    
    echo "✅ Cluster reset completed"
fi
```

### Component Restart Procedures

```bash
# Restart kubelet
sudo systemctl restart kubelet

# Restart container runtime
sudo systemctl restart containerd

# Delete and recreate problematic pods
kubectl delete pod <pod-name>

# Rollback deployment
kubectl rollout undo deployment/<deployment-name>

# Drain and uncordon node
kubectl drain <node-name> --ignore-daemonsets
kubectl uncordon <node-name>
```

## 📚 Useful Resources

### Official Documentation
- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug-application-cluster/)
- [Debugging Pods](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-pods-replication-controllers/)
- [Debugging Services](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-service/)

### Community Tools
- [kubectl-debug](https://github.com/aylei/kubectl-debug)
- [stern](https://github.com/wercker/stern) - Multi pod log tailing
- [k9s](https://github.com/derailed/k9s) - Terminal UI for Kubernetes

### Debugging Images
```bash
# Useful debugging images
kubectl run debug-pod --image=busybox --rm -it --restart=Never -- sh
kubectl run debug-pod --image=nicolaka/netshoot --rm -it --restart=Never -- bash
kubectl run debug-pod --image=alpine --rm -it --restart=Never -- sh
```

---

## 🔍 Quick Reference Card

| Issue | Command | Expected Output |
|-------|---------|----------------|
| Check node status | `kubectl get nodes` | All nodes Ready |
| Check pod status | `kubectl get pods` | All pods Running |
| Check system pods | `kubectl get pods -n kube-system` | All system pods Running |
| Check recent events | `kubectl get events --sort-by='.lastTimestamp' \| tail -10` | Recent cluster events |
| Check resource usage | `kubectl top nodes` | Node resource consumption |
| Test DNS | `kubectl run test --image=busybox --rm -it -- nslookup kubernetes` | Successful resolution |

Remember: When troubleshooting, always start with the basic diagnostic commands and work your way down to more specific issues!
