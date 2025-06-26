#!/bin/bash

# Kubernetes Cluster Reset Script
# This script provides a complete cluster reset functionality
# Use with caution - this will remove all applications and data

set -euo pipefail

# Colors for output
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
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root for safety reasons"
        exit 1
    fi
}

# Function to confirm destructive action
confirm_reset() {
    warn "This will completely reset your Kubernetes cluster!"
    warn "All applications, data, and configurations will be lost!"
    echo
    read -p "Are you sure you want to continue? Type 'YES' to confirm: " confirmation
    
    if [ "$confirmation" != "YES" ]; then
        info "Reset cancelled by user"
        exit 0
    fi
    
    warn "Last chance! This action cannot be undone!"
    read -p "Type 'RESET' to proceed: " final_confirmation
    
    if [ "$final_confirmation" != "RESET" ]; then
        info "Reset cancelled by user"
        exit 0
    fi
}

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        error "kubectl is not installed or not in PATH"
        exit 1
    fi
}

# Function to check cluster connectivity
check_cluster() {
    if ! kubectl cluster-info &> /dev/null; then
        error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
}

# Function to delete all namespaces except system ones
delete_namespaces() {
    log "Deleting all non-system namespaces..."
    
    # Get all namespaces except system ones
    namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -v -E '^(default|kube-system|kube-public|kube-node-lease)$' || true)
    
    if [ -z "$namespaces" ]; then
        info "No custom namespaces found to delete"
        return
    fi
    
    for ns in $namespaces; do
        info "Deleting namespace: $ns"
        kubectl delete namespace "$ns" --ignore-not-found=true --timeout=60s || warn "Failed to delete namespace $ns"
    done
    
    # Wait for namespace deletion
    log "Waiting for namespace deletion to complete..."
    sleep 10
    
    # Force delete any stuck namespaces
    for ns in $namespaces; do
        if kubectl get namespace "$ns" &> /dev/null; then
            warn "Force deleting stuck namespace: $ns"
            kubectl patch namespace "$ns" -p '{"metadata":{"finalizers":[]}}' --type=merge || true
        fi
    done
}

# Function to clean up resources in default namespace
cleanup_default_namespace() {
    log "Cleaning up default namespace..."
    
    # Delete deployments
    kubectl delete deployments --all -n default --ignore-not-found=true || true
    
    # Delete services (except kubernetes service)
    kubectl delete services --all -n default --ignore-not-found=true || true
    
    # Delete pods
    kubectl delete pods --all -n default --ignore-not-found=true --force --grace-period=0 || true
    
    # Delete configmaps
    kubectl delete configmaps --all -n default --ignore-not-found=true || true
    
    # Delete secrets (except default token)
    kubectl get secrets -n default -o name | grep -v default-token | xargs -r kubectl delete -n default || true
    
    # Delete persistent volume claims
    kubectl delete pvc --all -n default --ignore-not-found=true || true
    
    # Delete ingresses
    kubectl delete ingress --all -n default --ignore-not-found=true || true
}

# Function to clean up persistent volumes
cleanup_persistent_volumes() {
    log "Cleaning up persistent volumes..."
    
    # Delete all PVs that are not bound
    kubectl get pv -o jsonpath='{.items[?(@.status.phase!="Bound")].metadata.name}' | tr ' ' '\n' | while read -r pv; do
        if [ -n "$pv" ]; then
            info "Deleting unbound PV: $pv"
            kubectl delete pv "$pv" --ignore-not-found=true || true
        fi
    done
}

# Function to clean up cluster-wide resources
cleanup_cluster_resources() {
    log "Cleaning up cluster-wide resources..."
    
    # Delete cluster role bindings (keep system ones)
    kubectl get clusterrolebindings -o name | grep -v -E 'system:|cluster-admin|kube-' | xargs -r kubectl delete || true
    
    # Delete cluster roles (keep system ones)
    kubectl get clusterroles -o name | grep -v -E 'system:|cluster-admin|kube-|admin|edit|view' | xargs -r kubectl delete || true
    
    # Delete custom resource definitions (be careful with this)
    warn "Deleting custom resource definitions..."
    kubectl get crd -o name | xargs -r kubectl delete || true
}

# Function to reset kubeadm cluster (if using kubeadm)
reset_kubeadm() {
    log "Attempting to reset kubeadm cluster..."
    
    if command -v kubeadm &> /dev/null; then
        info "kubeadm found, performing cluster reset..."
        sudo kubeadm reset --force || warn "kubeadm reset failed or not applicable"
        
        # Clean up kubectl config
        if [ -f "$HOME/.kube/config" ]; then
            warn "Backing up kubectl config to ~/.kube/config.backup"
            cp "$HOME/.kube/config" "$HOME/.kube/config.backup" || true
            rm -f "$HOME/.kube/config" || true
        fi
        
        # Clean up kubeadm directories
        sudo rm -rf /etc/kubernetes/ || true
        sudo rm -rf /var/lib/etcd/ || true
        sudo rm -rf /var/lib/kubelet/ || true
        sudo rm -rf /etc/cni/net.d/ || true
        
        # Reset iptables
        sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X || true
        
    else
        warn "kubeadm not found, skipping kubeadm reset"
    fi
}

# Function to clean up Docker (if applicable)
cleanup_docker() {
    log "Cleaning up Docker resources..."
    
    if command -v docker &> /dev/null; then
        info "Docker found, cleaning up containers and images..."
        
        # Stop all containers
        docker stop $(docker ps -aq) 2>/dev/null || true
        
        # Remove all containers
        docker rm $(docker ps -aq) 2>/dev/null || true
        
        # Remove all images (be careful!)
        read -p "Do you want to remove all Docker images? (y/N): " remove_images
        if [[ $remove_images =~ ^[Yy]$ ]]; then
            docker rmi $(docker images -q) 2>/dev/null || true
        fi
        
        # Clean up Docker system
        docker system prune -af || true
        
    else
        info "Docker not found, skipping Docker cleanup"
    fi
}

# Function to clean up containerd (if applicable)
cleanup_containerd() {
    log "Cleaning up containerd resources..."
    
    if command -v crictl &> /dev/null; then
        info "crictl found, cleaning up containers and images..."
        
        # Stop all containers
        sudo crictl stop $(sudo crictl ps -q) 2>/dev/null || true
        
        # Remove all containers
        sudo crictl rm $(sudo crictl ps -aq) 2>/dev/null || true
        
        # Remove all images
        read -p "Do you want to remove all containerd images? (y/N): " remove_images
        if [[ $remove_images =~ ^[Yy]$ ]]; then
            sudo crictl rmi $(sudo crictl images -q) 2>/dev/null || true
        fi
        
    else
        info "crictl not found, skipping containerd cleanup"
    fi
}

# Function to restart kubelet (if applicable)
restart_kubelet() {
    log "Restarting kubelet service..."
    
    if systemctl is-active --quiet kubelet; then
        sudo systemctl stop kubelet || true
        sudo systemctl start kubelet || true
        info "Kubelet restarted"
    else
        info "Kubelet service not found or not active"
    fi
}

# Function to display post-reset instructions
show_post_reset_instructions() {
    log "Cluster reset completed!"
    echo
    info "Next steps:"
    echo "1. If you want to recreate the cluster, run: ./install-all.sh"
    echo "2. If using kubeadm, you may need to run: kubeadm init"
    echo "3. Don't forget to configure kubectl: mkdir -p ~/.kube && cp /etc/kubernetes/admin.conf ~/.kube/config"
    echo "4. Install a CNI plugin (e.g., Calico, Flannel)"
    echo "5. Join worker nodes if applicable"
    echo
    warn "Make sure to backup any important data before proceeding!"
}

# Main function
main() {
    log "Starting Kubernetes cluster reset..."
    
    # Checks
    check_root
    check_kubectl
    
    # Confirmation
    confirm_reset
    
    # Check cluster connectivity
    if check_cluster; then
        log "Connected to cluster, proceeding with Kubernetes resource cleanup..."
        
        # Kubernetes cleanup
        delete_namespaces
        cleanup_default_namespace
        cleanup_persistent_volumes
        cleanup_cluster_resources
    else
        warn "Cannot connect to cluster, skipping Kubernetes resource cleanup"
    fi
    
    # System-level cleanup
    reset_kubeadm
    cleanup_docker
    cleanup_containerd
    restart_kubelet
    
    # Final instructions
    show_post_reset_instructions
}

# Script usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -y, --yes      Skip confirmation prompts (dangerous!)"
    echo
    echo "This script will completely reset your Kubernetes cluster."
    echo "Use with extreme caution!"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -y|--yes)
            # Skip confirmations (for automated use)
            confirm_reset() { warn "Auto-confirmation enabled, proceeding with reset..."; }
            shift
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Run main function
main "$@"
