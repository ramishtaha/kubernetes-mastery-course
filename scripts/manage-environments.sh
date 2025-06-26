#!/bin/bash

# Kubernetes Environment Manager
# This script provides comprehensive environment management for different scenarios

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENTS_DIR="$(dirname "$0")/../environments"
MANIFESTS_DIR="$(dirname "$0")/../manifests"

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
    local missing_tools=()
    
    # Check required tools
    for tool in kubectl helm; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        error "Missing required tools: ${missing_tools[*]}"
        echo "Please install the missing tools and try again."
        exit 1
    fi
    
    # Check cluster connectivity
    if ! kubectl cluster-info &> /dev/null; then
        error "Cannot connect to Kubernetes cluster"
        echo "Please ensure your cluster is running and kubectl is configured."
        exit 1
    fi
    
    info "Prerequisites check passed"
}

# Function to create environment directories
create_environment_structure() {
    log "Creating environment structure..."
    
    mkdir -p "$ENVIRONMENTS_DIR"/{development,staging,production}
    mkdir -p "$ENVIRONMENTS_DIR"/development/{namespaces,configmaps,secrets}
    mkdir -p "$ENVIRONMENTS_DIR"/staging/{namespaces,configmaps,secrets}
    mkdir -p "$ENVIRONMENTS_DIR"/production/{namespaces,configmaps,secrets}
    
    info "Environment structure created"
}

# Function to deploy development environment
deploy_development() {
    log "Deploying development environment..."
    
    # Create development namespace
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: development
  labels:
    environment: development
    tier: dev
EOF

    # Deploy basic development resources
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: development
data:
  environment: "development"
  debug: "true"
  log_level: "debug"
  database_url: "dev-database.development.svc.cluster.local"
  redis_url: "dev-redis.development.svc.cluster.local"

---
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: development
type: Opaque
data:
  database_password: ZGV2LXBhc3N3b3Jk  # dev-password
  api_key: ZGV2LWFwaS1rZXk=  # dev-api-key

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
  namespace: development
  labels:
    app: sample-app
    environment: development
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
        environment: development
    spec:
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 80
        env:
        - name: ENVIRONMENT
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: environment
        - name: DEBUG
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: debug
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"

---
apiVersion: v1
kind: Service
metadata:
  name: sample-app
  namespace: development
  labels:
    app: sample-app
spec:
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: sample-app
  namespace: development
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: dev.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: sample-app
            port:
              number: 80
EOF

    info "Development environment deployed successfully"
}

# Function to deploy staging environment
deploy_staging() {
    log "Deploying staging environment..."
    
    # Create staging namespace
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: staging
  labels:
    environment: staging
    tier: staging

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: staging
data:
  environment: "staging"
  debug: "false"
  log_level: "info"
  database_url: "staging-database.staging.svc.cluster.local"
  redis_url: "staging-redis.staging.svc.cluster.local"

---
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: staging
type: Opaque
data:
  database_password: c3RhZ2luZy1wYXNzd29yZA==  # staging-password
  api_key: c3RhZ2luZy1hcGkta2V5  # staging-api-key

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
  namespace: staging
  labels:
    app: sample-app
    environment: staging
spec:
  replicas: 2
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
        environment: staging
    spec:
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 80
        env:
        - name: ENVIRONMENT
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: environment
        - name: DEBUG
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: debug
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 20

---
apiVersion: v1
kind: Service
metadata:
  name: sample-app
  namespace: staging
  labels:
    app: sample-app
spec:
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: sample-app
  namespace: staging
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: staging.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: sample-app
            port:
              number: 80

---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: sample-app-hpa
  namespace: staging
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: sample-app
  minReplicas: 2
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
EOF

    info "Staging environment deployed successfully"
}

# Function to deploy production environment
deploy_production() {
    log "Deploying production environment..."
    
    # Create production namespace
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: production
    tier: prod

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: production
data:
  environment: "production"
  debug: "false"
  log_level: "warn"
  database_url: "prod-database.production.svc.cluster.local"
  redis_url: "prod-redis.production.svc.cluster.local"

---
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: production
type: Opaque
data:
  database_password: cHJvZC1wYXNzd29yZA==  # prod-password
  api_key: cHJvZC1hcGkta2V5  # prod-api-key

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
  namespace: production
  labels:
    app: sample-app
    environment: production
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
        environment: production
    spec:
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 80
        env:
        - name: ENVIRONMENT
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: environment
        - name: DEBUG
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: debug
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 20
        securityContext:
          runAsNonRoot: true
          runAsUser: 1000
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true

---
apiVersion: v1
kind: Service
metadata:
  name: sample-app
  namespace: production
  labels:
    app: sample-app
spec:
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: sample-app
  namespace: production
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  rules:
  - host: prod.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: sample-app
            port:
              number: 80

---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: sample-app-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: sample-app
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80

---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: sample-app-pdb
  namespace: production
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: sample-app
EOF

    info "Production environment deployed successfully"
}

# Function to deploy monitoring for all environments
deploy_monitoring() {
    log "Deploying monitoring stack..."
    
    # Apply monitoring manifests if they exist
    if [ -f "$MANIFESTS_DIR/monitoring/prometheus-grafana-stack.yaml" ]; then
        kubectl apply -f "$MANIFESTS_DIR/monitoring/prometheus-grafana-stack.yaml"
        info "Monitoring stack deployed"
    else
        warn "Monitoring manifests not found, skipping monitoring deployment"
    fi
}

# Function to switch between environments
switch_environment() {
    local env="$1"
    
    if [[ ! "$env" =~ ^(development|staging|production)$ ]]; then
        error "Invalid environment: $env"
        echo "Available environments: development, staging, production"
        exit 1
    fi
    
    log "Switching to $env environment..."
    
    # Set default namespace
    kubectl config set-context --current --namespace="$env"
    
    info "Current context set to namespace: $env"
    
    # Show current environment status
    show_environment_status "$env"
}

# Function to show environment status
show_environment_status() {
    local env="${1:-all}"
    
    if [ "$env" = "all" ]; then
        log "Showing status for all environments..."
        for environment in development staging production; do
            echo "=== $environment Environment ==="
            kubectl get all -n "$environment" 2>/dev/null || echo "Environment not found"
            echo
        done
    else
        log "Showing status for $env environment..."
        kubectl get all -n "$env"
    fi
}

# Function to clean up environments
cleanup_environment() {
    local env="$1"
    
    if [[ ! "$env" =~ ^(development|staging|production|all)$ ]]; then
        error "Invalid environment: $env"
        echo "Available environments: development, staging, production, all"
        exit 1
    fi
    
    if [ "$env" = "all" ]; then
        warn "This will delete ALL environments!"
        read -p "Are you sure? Type 'YES' to confirm: " confirmation
        if [ "$confirmation" = "YES" ]; then
            for environment in development staging production; do
                log "Cleaning up $environment environment..."
                kubectl delete namespace "$environment" --ignore-not-found=true
            done
        else
            info "Cleanup cancelled"
        fi
    else
        warn "This will delete the $env environment!"
        read -p "Are you sure? Type 'YES' to confirm: " confirmation
        if [ "$confirmation" = "YES" ]; then
            log "Cleaning up $env environment..."
            kubectl delete namespace "$env" --ignore-not-found=true
        else
            info "Cleanup cancelled"
        fi
    fi
}

# Function to show environment comparison
compare_environments() {
    log "Comparing environments..."
    
    echo "=== Environment Comparison ==="
    printf "%-15s %-12s %-12s %-12s\n" "Resource" "Development" "Staging" "Production"
    echo "--------------------------------------------------------"
    
    for env in development staging production; do
        if kubectl get namespace "$env" &>/dev/null; then
            pods=$(kubectl get pods -n "$env" --no-headers 2>/dev/null | wc -l)
            services=$(kubectl get services -n "$env" --no-headers 2>/dev/null | wc -l)
            deployments=$(kubectl get deployments -n "$env" --no-headers 2>/dev/null | wc -l)
            
            if [ "$env" = "development" ]; then
                printf "%-15s %-12s %-12s %-12s\n" "Pods" "$pods" "-" "-"
                printf "%-15s %-12s %-12s %-12s\n" "Services" "$services" "-" "-"
                printf "%-15s %-12s %-12s %-12s\n" "Deployments" "$deployments" "-" "-"
            elif [ "$env" = "staging" ]; then
                dev_pods=$(kubectl get pods -n development --no-headers 2>/dev/null | wc -l)
                printf "%-15s %-12s %-12s %-12s\n" "Pods" "$dev_pods" "$pods" "-"
            elif [ "$env" = "production" ]; then
                dev_pods=$(kubectl get pods -n development --no-headers 2>/dev/null | wc -l)
                stg_pods=$(kubectl get pods -n staging --no-headers 2>/dev/null | wc -l)
                printf "%-15s %-12s %-12s %-12s\n" "Pods" "$dev_pods" "$stg_pods" "$pods"
            fi
        fi
    done
}

# Usage function
usage() {
    echo "Kubernetes Environment Manager"
    echo
    echo "Usage: $0 <command> [options]"
    echo
    echo "Commands:"
    echo "  deploy <env>        Deploy environment (development|staging|production|all)"
    echo "  switch <env>        Switch to environment namespace"
    echo "  status [env]        Show environment status (default: all)"
    echo "  cleanup <env>       Clean up environment (development|staging|production|all)"
    echo "  compare             Compare all environments"
    echo "  monitoring          Deploy monitoring stack"
    echo
    echo "Examples:"
    echo "  $0 deploy all              # Deploy all environments"
    echo "  $0 deploy development      # Deploy development environment only"
    echo "  $0 switch staging          # Switch to staging environment"
    echo "  $0 status                  # Show status of all environments"
    echo "  $0 cleanup development     # Clean up development environment"
    echo "  $0 compare                 # Compare all environments"
}

# Main function
main() {
    local command="${1:-}"
    
    case "$command" in
        "deploy")
            local env="${2:-}"
            check_prerequisites
            create_environment_structure
            
            case "$env" in
                "development")
                    deploy_development
                    ;;
                "staging")
                    deploy_staging
                    ;;
                "production")
                    deploy_production
                    ;;
                "all")
                    deploy_development
                    deploy_staging
                    deploy_production
                    ;;
                *)
                    error "Invalid environment: $env"
                    echo "Available environments: development, staging, production, all"
                    exit 1
                    ;;
            esac
            ;;
        "switch")
            local env="${2:-}"
            check_prerequisites
            switch_environment "$env"
            ;;
        "status")
            local env="${2:-all}"
            check_prerequisites
            show_environment_status "$env"
            ;;
        "cleanup")
            local env="${2:-}"
            check_prerequisites
            cleanup_environment "$env"
            ;;
        "compare")
            check_prerequisites
            compare_environments
            ;;
        "monitoring")
            check_prerequisites
            deploy_monitoring
            ;;
        "help"|"-h"|"--help")
            usage
            ;;
        *)
            error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
