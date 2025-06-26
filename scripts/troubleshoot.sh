#!/bin/bash

# Kubernetes Troubleshooting Helper Script
# This script provides automated troubleshooting for common Kubernetes issues

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
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

debug() {
    echo -e "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')] DEBUG: $1${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check cluster connectivity
    if ! kubectl cluster-info &> /dev/null; then
        error "Cannot connect to Kubernetes cluster"
        echo "Please check:"
        echo "1. Cluster is running"
        echo "2. kubectl is configured correctly"
        echo "3. Network connectivity"
        exit 1
    fi
    
    info "Prerequisites check passed"
}

# Function to gather cluster information
gather_cluster_info() {
    log "Gathering cluster information..."
    
    echo "=== Cluster Information ==="
    kubectl cluster-info
    echo
    
    echo "=== Kubernetes Version ==="
    kubectl version --short || kubectl version
    echo
    
    echo "=== Node Status ==="
    kubectl get nodes -o wide
    echo
    
    echo "=== Node Resources ==="
    kubectl top nodes 2>/dev/null || echo "Metrics server not available"
    echo
}

# Function to check node health
check_node_health() {
    log "Checking node health..."
    
    echo "=== Node Conditions ==="
    kubectl get nodes -o custom-columns=NAME:.metadata.name,STATUS:.status.conditions[-1].type,REASON:.status.conditions[-1].reason,MESSAGE:.status.conditions[-1].message
    echo
    
    echo "=== Node Capacity ==="
    kubectl describe nodes | grep -A 5 "Capacity:\|Allocatable:"
    echo
    
    # Check for NotReady nodes
    not_ready_nodes=$(kubectl get nodes --no-headers | grep NotReady | awk '{print $1}' || true)
    if [ -n "$not_ready_nodes" ]; then
        warn "Found NotReady nodes:"
        echo "$not_ready_nodes"
        echo
        echo "=== Troubleshooting NotReady Nodes ==="
        for node in $not_ready_nodes; do
            echo "--- Node: $node ---"
            kubectl describe node "$node" | tail -20
            echo
        done
    else
        info "All nodes are Ready"
    fi
}

# Function to check system pods
check_system_pods() {
    log "Checking system pods..."
    
    echo "=== System Pod Status ==="
    kubectl get pods -n kube-system -o wide
    echo
    
    # Check for failed pods
    failed_pods=$(kubectl get pods --all-namespaces --field-selector=status.phase=Failed --no-headers | awk '{print $1":"$2}' || true)
    if [ -n "$failed_pods" ]; then
        warn "Found failed pods:"
        echo "$failed_pods"
        echo
        echo "=== Failed Pod Details ==="
        echo "$failed_pods" | while read -r pod_info; do
            namespace=$(echo "$pod_info" | cut -d: -f1)
            pod=$(echo "$pod_info" | cut -d: -f2)
            echo "--- Pod: $namespace/$pod ---"
            kubectl describe pod "$pod" -n "$namespace" | tail -20
            echo
        done
    fi
    
    # Check for pending pods
    pending_pods=$(kubectl get pods --all-namespaces --field-selector=status.phase=Pending --no-headers | awk '{print $1":"$2}' || true)
    if [ -n "$pending_pods" ]; then
        warn "Found pending pods:"
        echo "$pending_pods"
        echo
        echo "=== Pending Pod Details ==="
        echo "$pending_pods" | while read -r pod_info; do
            namespace=$(echo "$pod_info" | cut -d: -f1)
            pod=$(echo "$pod_info" | cut -d: -f2)
            echo "--- Pod: $namespace/$pod ---"
            kubectl describe pod "$pod" -n "$namespace" | grep -A 10 "Events:"
            echo
        done
    fi
}

# Function to check network connectivity
check_network() {
    log "Checking network connectivity..."
    
    echo "=== CNI Plugin Status ==="
    kubectl get pods -n kube-system | grep -E "(calico|flannel|weave|cilium)" || echo "No CNI pods found"
    echo
    
    echo "=== Network Policies ==="
    kubectl get networkpolicies --all-namespaces || echo "No network policies found"
    echo
    
    echo "=== Service Status ==="
    kubectl get services --all-namespaces -o wide
    echo
    
    echo "=== DNS Test ==="
    # Create a test pod for DNS testing
    kubectl run dns-test --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default.svc.cluster.local 2>/dev/null || warn "DNS test failed"
    echo
}

# Function to check resource usage
check_resources() {
    log "Checking resource usage..."
    
    echo "=== Resource Usage by Namespace ==="
    kubectl top pods --all-namespaces 2>/dev/null || echo "Metrics server not available"
    echo
    
    echo "=== Persistent Volumes ==="
    kubectl get pv
    echo
    
    echo "=== Persistent Volume Claims ==="
    kubectl get pvc --all-namespaces
    echo
    
    echo "=== Storage Classes ==="
    kubectl get storageclass
    echo
}

# Function to check common issues
check_common_issues() {
    log "Checking for common issues..."
    
    echo "=== ImagePullBackOff Issues ==="
    kubectl get pods --all-namespaces -o wide | grep ImagePullBackOff || echo "No ImagePullBackOff issues found"
    echo
    
    echo "=== CrashLoopBackOff Issues ==="
    kubectl get pods --all-namespaces -o wide | grep CrashLoopBackOff || echo "No CrashLoopBackOff issues found"
    echo
    
    echo "=== OOMKilled Issues ==="
    kubectl get events --all-namespaces --field-selector reason=OOMKilling || echo "No OOMKilled events found"
    echo
    
    echo "=== Recent Events ==="
    kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -20
    echo
}

# Function to check security
check_security() {
    log "Checking security configuration..."
    
    echo "=== RBAC Configuration ==="
    kubectl get clusterroles | head -10
    echo
    
    echo "=== Security Contexts ==="
    kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{"/"}{.metadata.name}{" - "}{.spec.securityContext}{"\n"}{end}' | head -10
    echo
    
    echo "=== Pod Security Policies ==="
    kubectl get psp 2>/dev/null || echo "Pod Security Policies not available"
    echo
}

# Function to generate diagnostics
generate_diagnostics() {
    log "Generating detailed diagnostics..."
    
    local output_dir="k8s-diagnostics-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$output_dir"
    
    info "Saving diagnostics to: $output_dir"
    
    # Cluster info
    kubectl cluster-info dump > "$output_dir/cluster-info.txt"
    
    # All resources
    kubectl get all --all-namespaces -o wide > "$output_dir/all-resources.txt"
    
    # Node details
    kubectl describe nodes > "$output_dir/nodes.txt"
    
    # Events
    kubectl get events --all-namespaces --sort-by='.lastTimestamp' > "$output_dir/events.txt"
    
    # Logs from system pods
    mkdir -p "$output_dir/logs"
    kubectl get pods -n kube-system --no-headers | awk '{print $1}' | while read -r pod; do
        kubectl logs "$pod" -n kube-system > "$output_dir/logs/$pod.log" 2>/dev/null || true
    done
    
    # Pod descriptions
    kubectl get pods --all-namespaces --no-headers | awk '{print $1":"$2}' | while read -r pod_info; do
        namespace=$(echo "$pod_info" | cut -d: -f1)
        pod=$(echo "$pod_info" | cut -d: -f2)
        kubectl describe pod "$pod" -n "$namespace" > "$output_dir/pod-$namespace-$pod.txt" 2>/dev/null || true
    done
    
    info "Diagnostics saved in directory: $output_dir"
    echo "You can share this directory with support teams for further analysis."
}

# Function to provide recommendations
provide_recommendations() {
    log "Providing recommendations..."
    
    echo "=== General Recommendations ==="
    echo "1. Ensure all nodes have sufficient resources (CPU, Memory, Disk)"
    echo "2. Check that all required ports are open for cluster communication"
    echo "3. Verify that the CNI plugin is properly installed and configured"
    echo "4. Monitor resource usage regularly using metrics server"
    echo "5. Keep Kubernetes and node components updated"
    echo
    
    echo "=== Troubleshooting Commands ==="
    echo "# Check pod logs:"
    echo "kubectl logs <pod-name> -n <namespace>"
    echo
    echo "# Describe resource for events:"
    echo "kubectl describe <resource> <name> -n <namespace>"
    echo
    echo "# Check resource usage:"
    echo "kubectl top nodes"
    echo "kubectl top pods --all-namespaces"
    echo
    echo "# Debug network issues:"
    echo "kubectl run debug --image=busybox --rm -it --restart=Never -- /bin/sh"
    echo
    echo "# Check cluster events:"
    echo "kubectl get events --sort-by='.lastTimestamp'"
    echo
}

# Function to run specific troubleshooting based on issue type
troubleshoot_specific() {
    local issue_type="$1"
    
    case "$issue_type" in
        "pods")
            log "Troubleshooting pod issues..."
            check_system_pods
            kubectl get pods --all-namespaces -o wide
            ;;
        "network")
            log "Troubleshooting network issues..."
            check_network
            ;;
        "nodes")
            log "Troubleshooting node issues..."
            check_node_health
            ;;
        "resources")
            log "Troubleshooting resource issues..."
            check_resources
            ;;
        "security")
            log "Troubleshooting security issues..."
            check_security
            ;;
        *)
            error "Unknown issue type: $issue_type"
            echo "Available types: pods, network, nodes, resources, security"
            exit 1
            ;;
    esac
}

# Function to run interactive troubleshooting
interactive_troubleshooting() {
    while true; do
        echo
        echo "=== Interactive Troubleshooting Menu ==="
        echo "1. Full cluster health check"
        echo "2. Check specific issue type"
        echo "3. Generate diagnostics"
        echo "4. View recommendations"
        echo "5. Exit"
        echo
        read -p "Select an option (1-5): " choice
        
        case "$choice" in
            1)
                main_check
                ;;
            2)
                echo "Available issue types: pods, network, nodes, resources, security"
                read -p "Enter issue type: " issue_type
                troubleshoot_specific "$issue_type"
                ;;
            3)
                generate_diagnostics
                ;;
            4)
                provide_recommendations
                ;;
            5)
                info "Exiting troubleshooting tool"
                exit 0
                ;;
            *)
                warn "Invalid option. Please select 1-5."
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# Main troubleshooting function
main_check() {
    log "Starting comprehensive Kubernetes troubleshooting..."
    
    check_prerequisites
    gather_cluster_info
    check_node_health
    check_system_pods
    check_network
    check_resources
    check_common_issues
    check_security
    provide_recommendations
    
    log "Troubleshooting check completed!"
}

# Usage function
usage() {
    echo "Kubernetes Troubleshooting Helper"
    echo
    echo "Usage: $0 [OPTIONS] [COMMAND]"
    echo
    echo "Commands:"
    echo "  check           Run full health check (default)"
    echo "  pods            Troubleshoot pod issues"
    echo "  network         Troubleshoot network issues"
    echo "  nodes           Troubleshoot node issues"
    echo "  resources       Troubleshoot resource issues"
    echo "  security        Troubleshoot security issues"
    echo "  diagnostics     Generate diagnostics package"
    echo "  interactive     Run interactive troubleshooting"
    echo
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -v, --verbose   Enable verbose output"
    echo
    echo "Examples:"
    echo "  $0                    # Run full health check"
    echo "  $0 pods              # Check pod issues only"
    echo "  $0 diagnostics       # Generate diagnostics"
    echo "  $0 interactive       # Interactive mode"
}

# Parse command line arguments
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        check|pods|network|nodes|resources|security|diagnostics|interactive)
            COMMAND="$1"
            shift
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Set default command
COMMAND="${COMMAND:-check}"

# Enable debug output if verbose
if [ "$VERBOSE" = true ]; then
    set -x
fi

# Execute the requested command
case "$COMMAND" in
    "check")
        main_check
        ;;
    "pods")
        check_prerequisites
        troubleshoot_specific "pods"
        ;;
    "network")
        check_prerequisites
        troubleshoot_specific "network"
        ;;
    "nodes")
        check_prerequisites
        troubleshoot_specific "nodes"
        ;;
    "resources")
        check_prerequisites
        troubleshoot_specific "resources"
        ;;
    "security")
        check_prerequisites
        troubleshoot_specific "security"
        ;;
    "diagnostics")
        check_prerequisites
        generate_diagnostics
        ;;
    "interactive")
        check_prerequisites
        interactive_troubleshooting
        ;;
    *)
        error "Unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac
