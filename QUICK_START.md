# Quick Deployment Guide

## 🚀 Get Started in 5 Minutes

### Step 1: Prepare Your System
```bash
# Ensure you have a clean Ubuntu 20.04+ system
# Update system packages
sudo apt update && sudo apt upgrade -y

# Clone this repository
git clone https://github.com/yourusername/kubernetes-learning-project.git
cd kubernetes-learning-project
```

### Step 2: Automated Installation
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run complete installation (recommended for beginners)
./scripts/install-all.sh

# This script will:
# ✅ Prepare system (disable swap, configure kernel modules)
# ✅ Install containerd container runtime
# ✅ Install Kubernetes components (kubeadm, kubelet, kubectl)
# ✅ Initialize cluster with kubeadm
# ✅ Install Flannel network plugin
# ✅ Configure kubectl
# ✅ Deploy test application
```

### Step 3: Verify Installation
```bash
# Check cluster status
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces

# Access test application
curl http://localhost:30080
```

### Step 4: Start Learning
```bash
# Begin with prerequisites
cd 00-prerequisites
cat README.md

# Or jump to basic concepts if you're ready
cd 02-kubernetes-basics
cat README.md
```

## 🔧 Alternative: Manual Step-by-Step

If you prefer manual installation or want to understand each step:

```bash
# Step 1: System preparation
./scripts/prepare-system.sh
sudo reboot

# Step 2: Install container runtime
./scripts/install-containerd.sh

# Step 3: Install Kubernetes
./scripts/install-kubernetes.sh

# Step 4: Initialize cluster
./scripts/init-cluster.sh

# Step 5: Install network plugin
./scripts/install-cni.sh

# Step 6: Configure for single-node (optional)
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

## 🎯 Quick Learning Path

### Week 1: Foundation
- [ ] Complete Module 00 (Prerequisites)
- [ ] Complete Module 01 (Installation)
- [ ] Deploy first application

### Week 2: Basics
- [ ] Complete Module 02 (Kubernetes Basics)
- [ ] Master kubectl commands
- [ ] Understand namespaces and labels

### Week 3-4: Core Concepts
- [ ] Complete Module 03 (Workloads)
- [ ] Complete Module 04 (Configuration)
- [ ] Complete Module 05 (Storage)

### Week 5-8: Advanced Topics
- [ ] Complete Modules 06-09
- [ ] Real-world projects
- [ ] Production practices

## 🚨 Troubleshooting

### Common Issues

**Issue**: Pods stuck in Pending
```bash
kubectl describe pod <pod-name>
# Usually: resource constraints or node taints
```

**Issue**: Cannot access services
```bash
kubectl get svc
kubectl describe svc <service-name>
# Check selector labels and port configuration
```

**Issue**: Node NotReady
```bash
sudo systemctl status kubelet
sudo journalctl -u kubelet -f
# Usually: kubelet or network issues
```

### Quick Fixes
```bash
# Restart kubelet
sudo systemctl restart kubelet

# Reset cluster (last resort)
./scripts/reset-cluster.sh

# Reinstall everything
./scripts/install-all.sh
```

## 📚 Resources

- **Documentation**: Each module has comprehensive README
- **Examples**: `/manifests` directory has working examples
- **Scripts**: `/scripts` directory has automation tools
- **Troubleshooting**: `/troubleshooting` has debugging guides

## 🎓 Certification Path

This project prepares you for:
- **CKA** (Certified Kubernetes Administrator)
- **CKAD** (Certified Kubernetes Application Developer)
- **CKS** (Certified Kubernetes Security Specialist)

## 💼 Career Ready Skills

Upon completion, you'll have:
- ✅ Production Kubernetes deployment experience
- ✅ Troubleshooting and debugging skills
- ✅ Security best practices implementation
- ✅ Monitoring and logging setup
- ✅ Real-world project portfolio

---

**Need help?** Check the troubleshooting guide or create an issue on GitHub!
