#!/bin/bash

# Complete Kubernetes Installation Script
# This script automates the entire Kubernetes installation process

set -e  # Exit on any error

echo "🚀 Starting Complete Kubernetes Installation"
echo "=============================================="

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    error "Please don't run this script as root"
fi

# Check if sudo is available
if ! sudo -n true 2>/dev/null; then
    error "This script requires sudo privileges"
fi

# Phase 1: System Preparation
log "Phase 1: System Preparation"
log "============================"

# Check Ubuntu version
if ! grep -q "Ubuntu" /etc/os-release; then
    error "This script is for Ubuntu systems only"
fi

UBUNTU_VERSION=$(lsb_release -rs)
log "Ubuntu version: $UBUNTU_VERSION"

# Check system resources
CPU_CORES=$(nproc)
MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
DISK_GB=$(df -BG / | awk 'NR==2{print int($4)}')

log "System resources: ${CPU_CORES} cores, ${MEMORY_GB}GB RAM, ${DISK_GB}GB free disk"

if [ "$CPU_CORES" -lt 2 ]; then
    warn "Less than 2 CPU cores detected. This may cause performance issues."
fi

if [ "$MEMORY_GB" -lt 2 ]; then
    error "At least 2GB RAM required for Kubernetes"
fi

if [ "$DISK_GB" -lt 20 ]; then
    error "At least 20GB free disk space required"
fi

# Update system
log "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
log "Installing required packages..."
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common bc

# Disable swap
log "Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load kernel modules
log "Loading required kernel modules..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Configure sysctl
log "Configuring sysctl parameters..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# Phase 2: Container Runtime Installation
log "Phase 2: Container Runtime Installation"
log "======================================="

# Add Docker repository
log "Adding Docker repository..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update

# Install containerd
log "Installing containerd..."
sudo apt install -y containerd.io

# Configure containerd
log "Configuring containerd..."
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Enable SystemdCgroup
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Restart containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

# Verify containerd
if sudo systemctl is-active --quiet containerd; then
    log "containerd is running successfully"
else
    error "containerd failed to start"
fi

# Phase 3: Kubernetes Components Installation
log "Phase 3: Kubernetes Components Installation"
log "==========================================="

# Add Kubernetes repository
log "Adding Kubernetes repository..."
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

sudo apt update

# Install Kubernetes components
log "Installing kubeadm, kubelet, and kubectl..."
sudo apt install -y kubelet kubeadm kubectl

# Hold packages
sudo apt-mark hold kubelet kubeadm kubectl

# Enable kubelet
sudo systemctl enable kubelet

# Display versions
log "Installed Kubernetes versions:"
kubeadm version --short
kubelet --version
kubectl version --client --short

# Phase 4: Cluster Initialization
log "Phase 4: Cluster Initialization"
log "==============================="

# Get node IP
NODE_IP=$(ip route get 8.8.8.8 | head -1 | awk '{print $7}')
log "Node IP: $NODE_IP"

# Initialize cluster
log "Initializing Kubernetes cluster (this may take several minutes)..."
sudo kubeadm init \
  --apiserver-advertise-address=$NODE_IP \
  --pod-network-cidr=10.244.0.0/16 \
  --service-cidr=10.96.0.0/12 \
  --node-name=$(hostname) \
  --ignore-preflight-errors=NumCPU

if [ $? -ne 0 ]; then
    error "Cluster initialization failed"
fi

# Set up kubectl
log "Setting up kubectl for current user..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Phase 5: Network Plugin Installation
log "Phase 5: Network Plugin Installation"
log "===================================="

# Install Flannel
log "Installing Flannel CNI plugin..."
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Wait for Flannel to be ready
log "Waiting for Flannel pods to be ready..."
kubectl wait --for=condition=ready pod -l app=flannel -n kube-flannel --timeout=300s

# Remove taint for single-node setup
log "Configuring node for single-node setup..."
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

# Phase 6: Setup kubectl autocompletion
log "Phase 6: kubectl Configuration"
log "=============================="

# Add kubectl completion
log "Setting up kubectl autocompletion..."
echo 'source <(kubectl completion bash)' >>~/.bashrc
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -F __start_kubectl k' >>~/.bashrc

# Phase 7: Verification
log "Phase 7: Installation Verification"
log "=================================="

# Wait for nodes to be ready
log "Waiting for node to be ready..."
kubectl wait --for=condition=ready nodes --all --timeout=300s

# Check cluster status
log "Cluster status:"
kubectl cluster-info

log "Node status:"
kubectl get nodes -o wide

log "System pods status:"
kubectl get pods -n kube-system

# Deploy test application
log "Deploying test application..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-test
  labels:
    app: nginx-test
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-test
  template:
    metadata:
      labels:
        app: nginx-test
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80

---
apiVersion: v1
kind: Service
metadata:
  name: nginx-test-service
spec:
  selector:
    app: nginx-test
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30080
  type: NodePort
EOF

# Wait for test application
log "Waiting for test application to be ready..."
kubectl wait --for=condition=ready pod -l app=nginx-test --timeout=180s

# Test application
log "Testing application accessibility..."
if curl -s http://localhost:30080 > /dev/null; then
    log "✅ Test application is accessible at http://localhost:30080"
else
    warn "Test application may not be fully ready yet"
fi

# Create join command for future use
log "Generating join command for worker nodes..."
kubeadm token create --print-join-command > /tmp/kubeadm-join-command.txt
log "Join command saved to /tmp/kubeadm-join-command.txt"

# Phase 8: Post-installation Summary
log "Phase 8: Installation Summary"
log "============================="

echo ""
echo "🎉 Kubernetes Installation Completed Successfully!"
echo "=================================================="
echo ""
echo "📋 Cluster Information:"
echo "   Node IP: $NODE_IP"
echo "   Cluster Endpoint: https://$NODE_IP:6443"
echo "   Pod Network: 10.244.0.0/16"
echo "   Service Network: 10.96.0.0/12"
echo ""
echo "🔧 Installed Components:"
echo "   • kubeadm: $(kubeadm version --short | grep 'kubeadm version')"
echo "   • kubelet: $(kubelet --version)"
echo "   • kubectl: $(kubectl version --client --short)"
echo "   • containerd: $(containerd --version | head -1)"
echo "   • Flannel CNI"
echo ""
echo "🚀 Quick Start Commands:"
echo "   kubectl get nodes"
echo "   kubectl get pods --all-namespaces"
echo "   kubectl cluster-info"
echo ""
echo "🌐 Test Application:"
echo "   Access nginx at: http://$NODE_IP:30080"
echo ""
echo "📖 Next Steps:"
echo "   1. Source your bashrc: source ~/.bashrc"
echo "   2. Explore kubectl: kubectl --help"
echo "   3. Deploy your applications: kubectl apply -f your-app.yaml"
echo "   4. Continue with Module 02: Kubernetes Basics"
echo ""
echo "🔗 Useful Commands:"
echo "   kubectl get all                    # List all resources"
echo "   kubectl get events --sort-by='.lastTimestamp'  # Recent events"
echo "   kubectl logs -f <pod-name>        # Follow pod logs"
echo "   kubectl describe node $(hostname) # Node details"
echo ""
echo "📚 Documentation:"
echo "   https://kubernetes.io/docs/"
echo ""

# Save installation info
cat > ~/k8s-installation-info.txt <<EOF
Kubernetes Installation Completed: $(date)
=========================================

Node IP: $NODE_IP
Cluster Endpoint: https://$NODE_IP:6443
Pod Network CIDR: 10.244.0.0/16
Service Network CIDR: 10.96.0.0/12

Installed Versions:
- kubeadm: $(kubeadm version --short | grep 'kubeadm version')
- kubelet: $(kubelet --version)
- kubectl: $(kubectl version --client --short)
- containerd: $(containerd --version | head -1)

Test Application: http://$NODE_IP:30080

Join Command (for worker nodes):
$(cat /tmp/kubeadm-join-command.txt)

Configuration Files:
- kubectl config: ~/.kube/config
- containerd config: /etc/containerd/config.toml
- kubelet config: /var/lib/kubelet/config.yaml

Useful Commands:
- kubectl get nodes
- kubectl get pods --all-namespaces
- kubectl cluster-info
- kubectl get events --sort-by='.lastTimestamp'

EOF

log "Installation summary saved to ~/k8s-installation-info.txt"
log "🎊 Installation completed successfully! Welcome to Kubernetes!"
