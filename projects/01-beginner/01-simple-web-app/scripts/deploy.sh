#!/bin/bash
set -e

echo "🚀 Deploying Simple Web App to Kubernetes..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster"
    echo "Please ensure your cluster is running and kubectl is configured"
    exit 1
fi

echo "✅ Kubernetes cluster is accessible"

# Apply manifests in order
echo "📋 Creating ConfigMap..."
kubectl apply -f manifests/configmap.yaml

echo "🚀 Creating Deployment..."
kubectl apply -f manifests/deployment.yaml

echo "🌐 Creating Services..."
kubectl apply -f manifests/service.yaml

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/simple-web-app --timeout=300s

# Show deployment status
echo "📊 Deployment Status:"
kubectl get deployment simple-web-app
echo ""

echo "📦 Pod Status:"
kubectl get pods -l app=simple-web-app
echo ""

echo "🌐 Service Status:"
kubectl get services -l app=simple-web-app
echo ""

# Get access information
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "localhost")
echo "🔗 Access Information:"
echo "   External (NodePort): http://$NODE_IP:30080"
echo "   Port Forward: kubectl port-forward service/simple-web-app-service 8080:80"
echo "   Then access: http://localhost:8080"
echo ""

echo "🎉 Simple Web App deployed successfully!"
echo ""
echo "🧪 To run tests: ./scripts/test.sh"
echo "🧹 To cleanup: ./scripts/cleanup.sh"
