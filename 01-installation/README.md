# Module 01: Kubernetes Installation and Setup

This comprehensive module will guide you through installing Kubernetes on Ubuntu Server using kubeadm, the recommended production-ready approach.

## 📚 Learning Objectives

By the end of this module, you will:
- Understand Kubernetes architecture and components
- Install and configure a complete Kubernetes cluster
- Set up kubectl for cluster management
- Deploy your first application on Kubernetes
- Troubleshoot common installation issues

## 📋 Module Outline

1. [Kubernetes Architecture Overview](#1-kubernetes-architecture-overview)
2. [Installation Methods Comparison](#2-installation-methods-comparison)
3. [System Preparation](#3-system-preparation)
4. [Container Runtime Installation](#4-container-runtime-installation)
5. [Kubernetes Components Installation](#5-kubernetes-components-installation)
6. [Cluster Initialization](#6-cluster-initialization)
7. [Network Plugin Setup](#7-network-plugin-setup)
8. [Worker Node Configuration](#8-worker-node-configuration)
9. [kubectl Configuration](#9-kubectl-configuration)
10. [First Application Deployment](#10-first-application-deployment)
11. [Troubleshooting Guide](#11-troubleshooting-guide)
12. [Assessment](#12-assessment)

---

## 1. Kubernetes Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                       │
├─────────────────────┬───────────────────────────────────────┤
│    Control Plane    │              Worker Nodes             │
│                     │                                       │
│  ┌─────────────┐   │  ┌──────────┐  ┌──────────┐           │
│  │ API Server  │   │  │  Node 1  │  │  Node 2  │    ...    │
│  └─────────────┘   │  │          │  │          │           │
│  ┌─────────────┐   │  │ ┌──────┐ │  │ ┌──────┐ │           │
│  │    etcd     │   │  │ │kubelet│ │  │ │kubelet│ │           │
│  └─────────────┘   │  │ └──────┘ │  │ └──────┘ │           │
│  ┌─────────────┐   │  │ ┌──────┐ │  │ ┌──────┐ │           │
│  │ Scheduler   │   │  │ │kube- │ │  │ │kube- │ │           │
│  └─────────────┘   │  │ │proxy │ │  │ │proxy │ │           │
│  ┌─────────────┐   │  │ └──────┘ │  │ └──────┘ │           │
│  │Controller   │   │  │ ┌──────┐ │  │ ┌──────┐ │           │
│  │Manager      │   │  │ │ Pods │ │  │ │ Pods │ │           │
│  └─────────────┘   │  │ └──────┘ │  │ └──────┘ │           │
│                     │  └──────────┘  └──────────┘           │
└─────────────────────┴───────────────────────────────────────┘
```

### Control Plane Components

#### 1. API Server (kube-apiserver)
- **Purpose**: Central management component that exposes the Kubernetes API
- **Functions**:
  - Validates and processes REST requests
  - Updates etcd with cluster state
  - Serves as the communication hub for all components
- **Port**: 6443 (HTTPS)

#### 2. etcd
- **Purpose**: Distributed key-value store for all cluster data
- **Functions**:
  - Stores cluster configuration
  - Maintains current state of all objects
  - Provides consistency and reliability
- **Port**: 2379 (client), 2380 (peer)

#### 3. Scheduler (kube-scheduler)
- **Purpose**: Assigns pods to nodes based on resource requirements
- **Functions**:
  - Watches for newly created pods with no assigned node
  - Considers resource requirements, constraints, and policies
  - Makes optimal placement decisions
- **Port**: 10251

#### 4. Controller Manager (kube-controller-manager)
- **Purpose**: Runs controller processes
- **Functions**:
  - Node Controller: Monitors node health
  - Replication Controller: Maintains desired number of pods
  - Endpoint Controller: Updates Endpoints objects
  - Service Account & Token Controllers: Create default accounts and API tokens
- **Port**: 10252

### Worker Node Components

#### 1. kubelet
- **Purpose**: Primary node agent that communicates with the API server
- **Functions**:
  - Manages pod lifecycle
  - Mounts volumes
  - Downloads secrets
  - Reports node and pod status
- **Port**: 10250

#### 2. kube-proxy
- **Purpose**: Network proxy that implements Kubernetes Service concept
- **Functions**:
  - Maintains network rules for Services
  - Enables communication between Services and external traffic
  - Load balances traffic across pod replicas
- **Configuration**: Usually runs as DaemonSet

#### 3. Container Runtime
- **Purpose**: Software responsible for running containers
- **Options**:
  - containerd (recommended)
  - CRI-O
  - Docker Engine (deprecated)

### Add-on Components

#### 1. DNS (CoreDNS)
- Provides DNS services for the cluster
- Enables service discovery

#### 2. Network Plugin (CNI)
- Implements the cluster networking model
- Popular options: Calico, Flannel, Weave Net

#### 3. Metrics Server
- Collects resource metrics from nodes and pods
- Enables horizontal pod autoscaling

---

## 2. Installation Methods Comparison

### kubeadm (Recommended for Production)
- **Pros**: Production-ready, highly configurable, follows best practices
- **Cons**: Requires more setup steps
- **Best for**: Production clusters, learning production concepts

### Minikube
- **Pros**: Easy single-node setup, good for development
- **Cons**: Single-node only, not production-ready
- **Best for**: Local development, testing

### Kind (Kubernetes in Docker)
- **Pros**: Fast setup, multi-node simulation
- **Cons**: Docker-based, not production-ready
- **Best for**: CI/CD, testing

### Managed Services
- **Examples**: EKS (AWS), GKE (Google), AKS (Azure)
- **Pros**: Fully managed, automated updates
- **Cons**: Vendor lock-in, limited customization

### Our Choice: kubeadm

We'll use kubeadm because it:
- Teaches production installation practices
- Provides full control over cluster configuration
- Is the standard tool for production clusters
- Offers the most comprehensive learning experience

---

## 3. System Preparation

### Minimum System Requirements

| Component | Control Plane | Worker Node |
|-----------|---------------|-------------|
| CPU | 2 cores | 1 core |
| RAM | 2 GB | 1 GB |
| Storage | 20 GB | 10 GB |
| Network | Internet connectivity required |

### Pre-installation Checklist

Create and run this preparation script:

```bash
#!/bin/bash
# save as: prepare-system.sh

echo "=== Kubernetes System Preparation ==="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please don't run this script as root"
    exit 1
fi

echo "✅ Checking system requirements..."

# Check Ubuntu version
if ! grep -q "Ubuntu" /etc/os-release; then
    echo "❌ This script is for Ubuntu systems"
    exit 1
fi

UBUNTU_VERSION=$(lsb_release -rs)
if (( $(echo "$UBUNTU_VERSION < 18.04" | bc -l) )); then
    echo "❌ Ubuntu 18.04 or newer required"
    exit 1
fi

echo "✅ Ubuntu $UBUNTU_VERSION detected"

# Check system resources
CPU_CORES=$(nproc)
MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
DISK_GB=$(df -BG / | awk 'NR==2{print int($4)}')

echo "📊 System Resources:"
echo "   CPU Cores: $CPU_CORES"
echo "   Memory: ${MEMORY_GB}GB"
echo "   Free Disk: ${DISK_GB}GB"

if [ "$CPU_CORES" -lt 2 ]; then
    echo "⚠️  Warning: Less than 2 CPU cores detected"
fi

if [ "$MEMORY_GB" -lt 2 ]; then
    echo "❌ Error: At least 2GB RAM required"
    exit 1
fi

if [ "$DISK_GB" -lt 20 ]; then
    echo "❌ Error: At least 20GB free disk space required"
    exit 1
fi

echo "✅ System requirements check passed"

# Update system packages
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "📦 Installing required packages..."
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Disable swap
echo "💾 Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load required kernel modules
echo "🔧 Loading kernel modules..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Configure sysctl parameters
echo "⚙️  Configuring sysctl parameters..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# Configure firewall (if ufw is active)
if command_exists ufw && sudo ufw status | grep -q "Status: active"; then
    echo "🔥 Configuring firewall..."
    
    # Control plane ports
    sudo ufw allow 6443/tcp    # API server
    sudo ufw allow 2379:2380/tcp  # etcd
    sudo ufw allow 10250/tcp   # kubelet
    sudo ufw allow 10251/tcp   # kube-scheduler
    sudo ufw allow 10252/tcp   # kube-controller-manager
    
    # Worker node ports
    sudo ufw allow 10250/tcp   # kubelet
    sudo ufw allow 30000:32767/tcp  # NodePort services
    
    echo "✅ Firewall configured for Kubernetes"
else
    echo "ℹ️  UFW not active, skipping firewall configuration"
fi

# Set hostname (if needed)
CURRENT_HOSTNAME=$(hostname)
echo "🏷️  Current hostname: $CURRENT_HOSTNAME"
echo "   If you want to change it, run: sudo hostnamectl set-hostname new-hostname"

# Check network configuration
echo "🌐 Network configuration:"
ip route get 8.8.8.8 | head -1

echo ""
echo "✅ System preparation completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Reboot the system: sudo reboot"
echo "2. After reboot, proceed with container runtime installation"
echo ""
```

Make the script executable and run it:

```bash
chmod +x prepare-system.sh
./prepare-system.sh
```

After running the script, reboot your system:

```bash
sudo reboot
```

---

## 4. Container Runtime Installation

Kubernetes requires a container runtime. We'll install containerd, which is the recommended choice.

### Install containerd

Create and run this script:

```bash
#!/bin/bash
# save as: install-containerd.sh

echo "=== Installing containerd ==="

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index
sudo apt update

# Install containerd
sudo apt install -y containerd.io

# Configure containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Enable SystemdCgroup (required for kubeadm)
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Restart and enable containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

# Verify installation
sudo systemctl status containerd --no-pager

echo "✅ containerd installation completed"

# Test containerd
echo "🧪 Testing containerd..."
sudo ctr --version
sudo ctr images pull docker.io/library/hello-world:latest
sudo ctr run --rm docker.io/library/hello-world:latest test

echo "✅ containerd is working correctly"
```

Run the script:

```bash
chmod +x install-containerd.sh
./install-containerd.sh
```

### Verify containerd Installation

```bash
# Check containerd status
sudo systemctl status containerd

# Test container execution
sudo ctr images list
sudo ctr namespaces list
```

---

## 5. Kubernetes Components Installation

### Install kubeadm, kubelet, and kubectl

```bash
#!/bin/bash
# save as: install-kubernetes.sh

echo "=== Installing Kubernetes Components ==="

# Add Kubernetes GPG key
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

# Add Kubernetes repository
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

# Update package index
sudo apt update

# Install Kubernetes components
sudo apt install -y kubelet kubeadm kubectl

# Hold packages to prevent automatic updates
sudo apt-mark hold kubelet kubeadm kubectl

# Enable kubelet service
sudo systemctl enable kubelet

echo "✅ Kubernetes components installed successfully"

# Display versions
echo "📋 Installed versions:"
kubeadm version
kubelet --version
kubectl version --client

echo ""
echo "📋 Component descriptions:"
echo "• kubeadm: Tool for bootstrapping Kubernetes clusters"
echo "• kubelet: Node agent that manages pods and containers"
echo "• kubectl: Command-line tool for interacting with clusters"
```

Run the installation script:

```bash
chmod +x install-kubernetes.sh
./install-kubernetes.sh
```

### Verify Installation

```bash
# Check if components are installed
which kubeadm kubelet kubectl

# Check versions
kubeadm version
kubelet --version
kubectl version --client

# Check kubelet status (should be inactive until cluster is initialized)
sudo systemctl status kubelet
```

---

## 6. Cluster Initialization

### Initialize the Control Plane

For this tutorial, we'll create a single-node cluster that can also run workloads.

```bash
#!/bin/bash
# save as: init-cluster.sh

echo "=== Initializing Kubernetes Cluster ==="

# Get the IP address of the primary network interface
NODE_IP=$(ip route get 8.8.8.8 | head -1 | awk '{print $7}')
echo "🌐 Node IP detected: $NODE_IP"

# Initialize the cluster
echo "🚀 Initializing cluster (this may take a few minutes)..."
sudo kubeadm init \
  --apiserver-advertise-address=$NODE_IP \
  --pod-network-cidr=10.244.0.0/16 \
  --service-cidr=10.96.0.0/12 \
  --node-name=$(hostname) \
  --ignore-preflight-errors=NumCPU

# Check if initialization was successful
if [ $? -eq 0 ]; then
    echo "✅ Cluster initialization successful!"
    
    # Set up kubectl for the current user
    echo "⚙️  Setting up kubectl..."
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    
    echo "✅ kubectl configured for current user"
    
    # Verify cluster status
    echo "🔍 Checking cluster status..."
    kubectl cluster-info
    kubectl get nodes
    
    echo ""
    echo "📋 Next steps:"
    echo "1. Install a network plugin (CNI)"
    echo "2. Remove taint from control plane to allow scheduling (for single-node setup)"
    echo "3. Deploy your first application"
    
else
    echo "❌ Cluster initialization failed!"
    echo "Check the logs above for error details"
    exit 1
fi
```

Run the initialization script:

```bash
chmod +x init-cluster.sh
./init-cluster.sh
```

### Save Join Command (for multi-node clusters)

The `kubeadm init` output includes a join command. Save it:

```bash
# Example join command (yours will be different):
kubeadm join <control-plane-ip>:6443 --token <token> \
    --discovery-token-ca-cert-hash sha256:<hash>

# Save to file for later use
echo "kubeadm join ..." > join-command.txt
```

To regenerate the join command later:

```bash
# Get new token
kubeadm token create --print-join-command
```

---

## 7. Network Plugin Setup

Kubernetes requires a Container Network Interface (CNI) plugin. We'll install Flannel for simplicity.

### Install Flannel CNI

```bash
#!/bin/bash
# save as: install-cni.sh

echo "=== Installing Flannel CNI ==="

# Apply Flannel manifest
echo "📥 Downloading and applying Flannel..."
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Wait for Flannel pods to be ready
echo "⏳ Waiting for Flannel pods to be ready..."
kubectl wait --for=condition=ready pod -l app=flannel -n kube-flannel --timeout=300s

# Check if all system pods are running
echo "🔍 Checking system pods status..."
kubectl get pods -n kube-system

# Check if nodes are ready
echo "🔍 Checking node status..."
kubectl get nodes

echo "✅ Network plugin installation completed"
```

Run the CNI installation:

```bash
chmod +x install-cni.sh
./install-cni.sh
```

### Verify Network Setup

```bash
# Check that all system pods are running
kubectl get pods -n kube-system

# Check that nodes are in Ready state
kubectl get nodes

# Test DNS resolution
kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup kubernetes
```

---

## 8. Worker Node Configuration

### For Single-Node Setup (Learning Environment)

Remove the taint from the control plane node to allow scheduling workloads:

```bash
# Remove NoSchedule taint from control plane
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# Verify the taint is removed
kubectl describe nodes | grep Taints
```

### For Multi-Node Setup

If you have additional nodes to add as workers:

1. **Prepare each worker node** by running the system preparation script from Step 3
2. **Install container runtime** (Step 4) and Kubernetes components (Step 5)
3. **Join the cluster** using the saved join command:

```bash
# On worker node, run the join command from Step 6
sudo kubeadm join <control-plane-ip>:6443 --token <token> \
    --discovery-token-ca-cert-hash sha256:<hash>
```

4. **Verify the node joined** (run on control plane):

```bash
kubectl get nodes
```

---

## 9. kubectl Configuration

### Set up kubectl Autocompletion

```bash
# Add kubectl completion to bash
echo 'source <(kubectl completion bash)' >>~/.bashrc

# Add alias for kubectl
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -F __start_kubectl k' >>~/.bashrc

# Reload bash configuration
source ~/.bashrc
```

### Configure kubectl Contexts

```bash
# View current context
kubectl config current-context

# View all contexts
kubectl config get-contexts

# Set default namespace (optional)
kubectl config set-context --current --namespace=default
```

### Useful kubectl Aliases

Add these to your `~/.bashrc`:

```bash
# kubectl aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete'
alias klog='kubectl logs'
alias kexec='kubectl exec -it'
alias kdesc='kubectl describe'
```

---

## 10. First Application Deployment

Let's deploy a simple web application to verify everything works.

### Deploy nginx

```bash
# Create nginx deployment
kubectl create deployment nginx --image=nginx:latest

# Expose nginx as a service
kubectl expose deployment nginx --port=80 --type=NodePort

# Check deployment status
kubectl get deployments
kubectl get pods
kubectl get services
```

### Create a More Complex Application

Create a file called `first-app.yaml`:

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-kubernetes
  labels:
    app: hello-kubernetes
spec:
  replicas: 3
  selector:
    matchLabels:
      app: hello-kubernetes
  template:
    metadata:
      labels:
        app: hello-kubernetes
    spec:
      containers:
      - name: hello-kubernetes
        image: paulbouwer/hello-kubernetes:1.10
        ports:
        - containerPort: 8080
        env:
        - name: MESSAGE
          value: "Hello from Kubernetes!"

---
apiVersion: v1
kind: Service
metadata:
  name: hello-kubernetes-service
spec:
  selector:
    app: hello-kubernetes
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
      nodePort: 30080
  type: NodePort
```

Deploy the application:

```bash
# Apply the manifest
kubectl apply -f first-app.yaml

# Check deployment status
kubectl get all

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=hello-kubernetes --timeout=60s

# Test the application
curl http://localhost:30080
```

### Access the Application

```bash
# Get node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# Get service port
SERVICE_PORT=$(kubectl get service hello-kubernetes-service -o jsonpath='{.spec.ports[0].nodePort}')

echo "Application accessible at: http://$NODE_IP:$SERVICE_PORT"

# Test with curl
curl http://$NODE_IP:$SERVICE_PORT
```

---

## 11. Troubleshooting Guide

### Common Issues and Solutions

#### 1. Pods Stuck in Pending State

**Symptoms**: Pods remain in Pending status
**Diagnosis**:
```bash
kubectl describe pod <pod-name>
kubectl get events --sort-by='.lastTimestamp'
```

**Common Causes**:
- Insufficient resources
- Node not ready
- Missing network plugin
- Taints preventing scheduling

**Solutions**:
```bash
# Check node resources
kubectl top nodes
kubectl describe nodes

# Remove taints (single-node setup)
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# Check network plugin
kubectl get pods -n kube-system
```

#### 2. kubelet Not Starting

**Symptoms**: kubelet service fails to start
**Diagnosis**:
```bash
sudo systemctl status kubelet
sudo journalctl -u kubelet -f
```

**Common Causes**:
- Swap not disabled
- Container runtime not running
- Configuration issues

**Solutions**:
```bash
# Disable swap
sudo swapoff -a

# Restart container runtime
sudo systemctl restart containerd

# Reset kubelet configuration
sudo kubeadm reset
```

#### 3. API Server Not Responding

**Symptoms**: kubectl commands timeout
**Diagnosis**:
```bash
kubectl cluster-info
curl -k https://localhost:6443/version
```

**Solutions**:
```bash
# Check API server pod
sudo crictl ps | grep apiserver

# Check certificates
sudo kubeadm certs check-expiration

# Restart control plane components
sudo systemctl restart kubelet
```

#### 4. Network Issues

**Symptoms**: Pods can't communicate
**Diagnosis**:
```bash
kubectl get pods -n kube-system
kubectl logs -n kube-system -l app=flannel
```

**Solutions**:
```bash
# Reinstall network plugin
kubectl delete -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

### Diagnostic Commands

```bash
# Cluster health overview
kubectl get componentstatuses
kubectl get nodes -o wide
kubectl get pods --all-namespaces

# Detailed node information
kubectl describe nodes

# Event monitoring
kubectl get events --watch

# Log collection
kubectl logs -n kube-system <pod-name>
sudo journalctl -u kubelet -f
sudo journalctl -u containerd -f

# Resource usage
kubectl top nodes
kubectl top pods --all-namespaces
```

### Complete Reset (if needed)

```bash
#!/bin/bash
# save as: reset-cluster.sh

echo "⚠️  This will completely reset the Kubernetes cluster!"
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" = "yes" ]; then
    # Reset kubeadm
    sudo kubeadm reset -f
    
    # Clean up kubectl config
    rm -rf ~/.kube
    
    # Remove kubernetes packages (optional)
    # sudo apt remove -y kubeadm kubectl kubelet
    # sudo apt autoremove -y
    
    # Clean up iptables rules
    sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
    
    # Reset network interfaces
    sudo ip link delete cni0 2>/dev/null || true
    sudo ip link delete flannel.1 2>/dev/null || true
    
    echo "✅ Cluster reset completed"
    echo "You can now run the initialization again"
else
    echo "Reset cancelled"
fi
```

---

## 12. Assessment

### Knowledge Check Questions

1. **Architecture**: What are the main components of the Kubernetes control plane?

2. **Installation**: Why is swap disabled during Kubernetes installation?

3. **Networking**: What is the purpose of a CNI plugin in Kubernetes?

4. **Troubleshooting**: How would you diagnose a pod that's stuck in Pending state?

5. **Security**: What information does the kubeadm join command contain?

### Practical Exercises

#### Exercise 1: Multi-Container Pod
Create a pod with two containers:
- nginx web server
- busybox sidecar for logging

#### Exercise 2: Resource Monitoring
Set up monitoring for your cluster:
- Deploy metrics-server
- Monitor resource usage
- Set up basic alerting

#### Exercise 3: Backup and Recovery
- Create etcd backup
- Simulate cluster failure
- Restore from backup

### Hands-on Labs

#### Lab 1: Service Discovery
Deploy multiple applications and test service discovery:

```yaml
# Database pod
apiVersion: v1
kind: Pod
metadata:
  name: database
  labels:
    app: database
spec:
  containers:
  - name: mysql
    image: mysql:8.0
    env:
    - name: MYSQL_ROOT_PASSWORD
      value: "password"
    - name: MYSQL_DATABASE
      value: "testdb"

---
# Database service
apiVersion: v1
kind: Service
metadata:
  name: database-service
spec:
  selector:
    app: database
  ports:
  - port: 3306
    targetPort: 3306

---
# Application pod
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  containers:
  - name: app
    image: busybox
    command: ['sleep', '3600']
```

Test connectivity:
```bash
kubectl apply -f service-discovery.yaml
kubectl exec -it app -- nslookup database-service
```

#### Lab 2: Storage Configuration
Set up persistent storage:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /tmp/k8s-data
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - <your-node-name>
```

### Assessment Rubric

| Skill Area | Beginner | Intermediate | Advanced |
|------------|----------|--------------|----------|
| **Architecture** | Knows components | Understands interactions | Can troubleshoot |
| **Installation** | Can follow guide | Can customize setup | Can automate |
| **Networking** | Basic connectivity | Service configuration | Advanced policies |
| **Troubleshooting** | Basic commands | Log analysis | Root cause analysis |

---

## 📚 Additional Resources

### Official Documentation
- [Kubernetes Installation Guide](https://kubernetes.io/docs/setup/)
- [kubeadm Reference](https://kubernetes.io/docs/reference/setup-tools/kubeadm/)
- [Container Runtime Interface](https://kubernetes.io/docs/concepts/architecture/cri/)

### Networking
- [Flannel Documentation](https://github.com/flannel-io/flannel)
- [Calico Documentation](https://docs.projectcalico.org/)
- [Kubernetes Networking Concepts](https://kubernetes.io/docs/concepts/cluster-administration/networking/)

### Troubleshooting
- [Kubernetes Troubleshooting Guide](https://kubernetes.io/docs/tasks/debug-application-cluster/)
- [Common Issues and Solutions](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/troubleshooting-kubeadm/)

---

## ✅ Module Completion Checklist

- [ ] Understand Kubernetes architecture
- [ ] Complete system preparation
- [ ] Install container runtime (containerd)
- [ ] Install Kubernetes components (kubeadm, kubelet, kubectl)
- [ ] Initialize cluster successfully
- [ ] Configure network plugin (Flannel)
- [ ] Set up kubectl with autocompletion
- [ ] Deploy and access first application
- [ ] Complete troubleshooting exercises
- [ ] Pass assessment with 80% or higher

---

**Next Module**: [02-kubernetes-basics](../02-kubernetes-basics/README.md) - Kubernetes Fundamental Concepts

**Estimated Time**: 5-7 days  
**Difficulty**: Intermediate  
**Prerequisites**: Module 00 completed
