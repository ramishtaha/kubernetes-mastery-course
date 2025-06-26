#!/bin/bash

# Quick Setup Script for Kubernetes Learning Environment
# This script provides quick commands for common tasks

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Display usage
usage() {
    echo "Kubernetes Learning Environment - Quick Setup"
    echo "============================================="
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  status          Show cluster status"
    echo "  dashboard       Install Kubernetes dashboard"
    echo "  metrics         Install metrics server"
    echo "  examples        Deploy example applications"
    echo "  cleanup         Clean up example applications"
    echo "  reset           Reset learning environment"
    echo "  tools           Install useful tools"
    echo "  help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 dashboard"
    echo "  $0 examples"
    echo ""
}

# Check cluster status
check_status() {
    log "Checking Kubernetes cluster status..."
    
    echo "📊 Cluster Info:"
    kubectl cluster-info
    
    echo ""
    echo "🖥️  Nodes:"
    kubectl get nodes -o wide
    
    echo ""
    echo "🏗️  System Pods:"
    kubectl get pods -n kube-system
    
    echo ""
    echo "📊 Resource Usage:"
    kubectl top nodes 2>/dev/null || warn "Metrics server not installed"
    
    echo ""
    echo "🔍 Recent Events:"
    kubectl get events --sort-by='.lastTimestamp' | tail -5
}

# Install Kubernetes Dashboard
install_dashboard() {
    log "Installing Kubernetes Dashboard..."
    
    # Install dashboard
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
    
    # Create admin user
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

    log "Dashboard installed successfully!"
    log "To access the dashboard:"
    log "1. Run: kubectl proxy"
    log "2. Visit: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
    log "3. Get token: kubectl -n kubernetes-dashboard create token admin-user"
}

# Install Metrics Server
install_metrics() {
    log "Installing Metrics Server..."
    
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    
    # Patch metrics server for local development
    kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
        {
            "op": "add",
            "path": "/spec/template/spec/containers/0/args/-",
            "value": "--kubelet-insecure-tls"
        }
    ]'
    
    log "Waiting for metrics server to be ready..."
    kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=120s
    
    log "Metrics Server installed successfully!"
    log "You can now use: kubectl top nodes and kubectl top pods"
}

# Deploy example applications
deploy_examples() {
    log "Deploying example applications..."
    
    # Create namespace
    kubectl create namespace examples --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy nginx example
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-example
  namespace: examples
  labels:
    app: nginx-example
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-example
  template:
    metadata:
      labels:
        app: nginx-example
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "256Mi"

---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: examples
spec:
  selector:
    app: nginx-example
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
  type: NodePort

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
  namespace: examples
  labels:
    app: hello-world
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello-world
  template:
    metadata:
      labels:
        app: hello-world
    spec:
      containers:
      - name: hello
        image: paulbouwer/hello-kubernetes:1.10
        ports:
        - containerPort: 8080
        env:
        - name: MESSAGE
          value: "Hello from Kubernetes Learning Environment!"

---
apiVersion: v1
kind: Service
metadata:
  name: hello-service
  namespace: examples
spec:
  selector:
    app: hello-world
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30081
  type: NodePort
EOF

    log "Waiting for deployments to be ready..."
    kubectl wait --for=condition=available deployment/nginx-example -n examples --timeout=120s
    kubectl wait --for=condition=available deployment/hello-world -n examples --timeout=120s
    
    log "Example applications deployed successfully!"
    log "Access nginx: http://localhost:30080"
    log "Access hello-world: http://localhost:30081"
    
    echo ""
    kubectl get all -n examples
}

# Clean up examples
cleanup_examples() {
    log "Cleaning up example applications..."
    
    kubectl delete namespace examples --ignore-not-found=true
    
    log "Example applications cleaned up!"
}

# Install useful tools
install_tools() {
    log "Installing useful Kubernetes tools..."
    
    # Install helm
    if ! command -v helm &> /dev/null; then
        log "Installing Helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    else
        log "Helm already installed"
    fi
    
    # Install k9s
    if ! command -v k9s &> /dev/null; then
        log "Installing k9s..."
        wget https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz
        tar -xzf k9s_Linux_amd64.tar.gz
        sudo mv k9s /usr/local/bin/
        rm k9s_Linux_amd64.tar.gz
    else
        log "k9s already installed"
    fi
    
    # Install kubectx and kubens
    if ! command -v kubectx &> /dev/null; then
        log "Installing kubectx and kubens..."
        sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
        sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
        sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
    else
        log "kubectx and kubens already installed"
    fi
    
    log "Tools installed successfully!"
    log "Available tools:"
    log "- helm: Package manager for Kubernetes"
    log "- k9s: Terminal UI for Kubernetes"
    log "- kubectx: Switch between contexts"
    log "- kubens: Switch between namespaces"
}

# Reset learning environment
reset_environment() {
    warn "This will reset your learning environment!"
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        log "Resetting learning environment..."
        
        # Delete example applications
        kubectl delete namespace examples --ignore-not-found=true
        
        # Delete dashboard (optional)
        read -p "Remove Kubernetes Dashboard? (yes/no): " remove_dashboard
        if [ "$remove_dashboard" = "yes" ]; then
            kubectl delete namespace kubernetes-dashboard --ignore-not-found=true
        fi
        
        # Delete metrics server (optional)
        read -p "Remove Metrics Server? (yes/no): " remove_metrics
        if [ "$remove_metrics" = "yes" ]; then
            kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml --ignore-not-found=true
        fi
        
        log "Learning environment reset completed!"
    else
        log "Reset cancelled"
    fi
}

# Main script logic
case "${1:-}" in
    status)
        check_status
        ;;
    dashboard)
        install_dashboard
        ;;
    metrics)
        install_metrics
        ;;
    examples)
        deploy_examples
        ;;
    cleanup)
        cleanup_examples
        ;;
    tools)
        install_tools
        ;;
    reset)
        reset_environment
        ;;
    help|--help|-h)
        usage
        ;;
    "")
        usage
        ;;
    *)
        error "Unknown command: $1"
        usage
        ;;
esac
