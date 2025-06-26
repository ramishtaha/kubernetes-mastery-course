# Project 01: Simple Web App

🎯 **Deploy Your First Web Application to Kubernetes**

This project will teach you the fundamentals of deploying applications to Kubernetes. You'll create a simple web application using NGINX and learn about Pods, Services, Deployments, and basic networking.

## 📋 Project Overview

**Difficulty:** ⭐☆☆☆☆ (Beginner)  
**Time Estimate:** 2-3 hours  
**Prerequisites:** Completed modules 00-04

### What You'll Build
- A simple web application with custom HTML content
- Kubernetes Deployment for high availability
- Service for stable networking
- Multiple replicas for load distribution
- External access configuration

### What You'll Learn
- Basic Kubernetes objects (Pod, Deployment, Service)
- Container networking in Kubernetes
- How to expose applications externally
- Scaling applications horizontally
- Basic troubleshooting techniques

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│              Internet                    │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│            NodePort Service              │
│         (Port 30080 → 80)               │
└─────────────────┬───────────────────────┘
                  │
       ┌──────────▼───────────┐
       │    Load Balancer     │
       └──────────┬───────────┘
                  │
    ┌─────────────┼─────────────┐
    │             │             │
┌───▼───┐    ┌───▼───┐    ┌───▼───┐
│ Pod 1 │    │ Pod 2 │    │ Pod 3 │
│NGINX  │    │NGINX  │    │NGINX  │
│:80    │    │:80    │    │:80    │
└───────┘    └───────┘    └───────┘
```

## 🚀 Getting Started

### Step 1: Create Project Directory
```bash
mkdir -p simple-web-app/{manifests,scripts,content}
cd simple-web-app
```

### Step 2: Create Custom HTML Content
Create a custom HTML page that we'll serve:

```bash
cat > content/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My First Kubernetes App</title>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
        }
        .container {
            text-align: center;
            background: rgba(255, 255, 255, 0.1);
            padding: 40px;
            border-radius: 20px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
        }
        h1 {
            font-size: 3em;
            margin-bottom: 20px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.5);
        }
        p {
            font-size: 1.2em;
            margin-bottom: 30px;
        }
        .info {
            background: rgba(255, 255, 255, 0.2);
            padding: 20px;
            border-radius: 10px;
            margin-top: 20px;
        }
        .status {
            color: #4CAF50;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Welcome to Kubernetes!</h1>
        <p>Congratulations! You've successfully deployed your first application to Kubernetes.</p>
        
        <div class="info">
            <p><strong>Pod Name:</strong> <span id="hostname">Loading...</span></p>
            <p><strong>Status:</strong> <span class="status">Running in Kubernetes Cluster</span></p>
            <p><strong>Project:</strong> Simple Web App</p>
            <p><strong>Level:</strong> Beginner</p>
        </div>
        
        <p>This application is running in a Kubernetes Pod and being served by NGINX.</p>
        <p>Try refreshing the page to see if you're load-balanced to different pods!</p>
    </div>

    <script>
        // Display hostname/pod name
        fetch('/api/hostname')
            .then(response => response.text())
            .then(data => {
                document.getElementById('hostname').textContent = data;
            })
            .catch(error => {
                document.getElementById('hostname').textContent = window.location.hostname;
            });
    </script>
</body>
</html>
EOF
```

### Step 3: Create a ConfigMap for the HTML Content
```bash
cat > manifests/configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: web-content
  namespace: default
  labels:
    app: simple-web-app
    project: beginner-01
data:
  index.html: |
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>My First Kubernetes App</title>
        <style>
            body {
                font-family: 'Arial', sans-serif;
                margin: 0;
                padding: 0;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                display: flex;
                justify-content: center;
                align-items: center;
                min-height: 100vh;
            }
            .container {
                text-align: center;
                background: rgba(255, 255, 255, 0.1);
                padding: 40px;
                border-radius: 20px;
                backdrop-filter: blur(10px);
                box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
            }
            h1 {
                font-size: 3em;
                margin-bottom: 20px;
                text-shadow: 2px 2px 4px rgba(0,0,0,0.5);
            }
            p {
                font-size: 1.2em;
                margin-bottom: 30px;
            }
            .info {
                background: rgba(255, 255, 255, 0.2);
                padding: 20px;
                border-radius: 10px;
                margin-top: 20px;
            }
            .status {
                color: #4CAF50;
                font-weight: bold;
            }
            .pod-info {
                font-family: monospace;
                background: rgba(0, 0, 0, 0.3);
                padding: 10px;
                border-radius: 5px;
                margin: 10px 0;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 Welcome to Kubernetes!</h1>
            <p>Congratulations! You've successfully deployed your first application to Kubernetes.</p>
            
            <div class="info">
                <div class="pod-info">
                    <p><strong>Pod Hostname:</strong> <span id="hostname">Loading...</span></p>
                    <p><strong>Server:</strong> NGINX running in Kubernetes</p>
                </div>
                <p><strong>Status:</strong> <span class="status">✅ Running in Kubernetes Cluster</span></p>
                <p><strong>Project:</strong> Simple Web App (Beginner Level)</p>
                <p><strong>Load Balancing:</strong> Active</p>
            </div>
            
            <p>This application is running in a Kubernetes Pod and being served by NGINX.</p>
            <p><strong>Try refreshing the page to see different pod hostnames!</strong></p>
            
            <div style="margin-top: 30px; font-size: 0.9em; opacity: 0.8;">
                <p>🎯 Learning achieved: Pods, Deployments, Services, ConfigMaps</p>
            </div>
        </div>

        <script>
            // Display the actual pod hostname
            document.getElementById('hostname').textContent = window.location.hostname;
            
            // Add some interactivity - show pod info
            setInterval(() => {
                const now = new Date().toLocaleTimeString();
                console.log('Pod still running at:', now);
            }, 10000);
        </script>
    </body>
    </html>
EOF
```

## 📋 Kubernetes Manifests

### Step 4: Create the Deployment
```bash
cat > manifests/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: simple-web-app
  namespace: default
  labels:
    app: simple-web-app
    project: beginner-01
    tier: frontend
spec:
  # Start with 3 replicas for load balancing
  replicas: 3
  selector:
    matchLabels:
      app: simple-web-app
  template:
    metadata:
      labels:
        app: simple-web-app
        project: beginner-01
        tier: frontend
    spec:
      containers:
      - name: web-server
        image: nginx:1.21-alpine
        ports:
        - containerPort: 80
          name: http
        # Resource limits for learning purposes
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
        # Health checks
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        # Mount our custom HTML content
        volumeMounts:
        - name: web-content
          mountPath: /usr/share/nginx/html
          readOnly: true
        # Environment variables for learning
        env:
        - name: NGINX_PORT
          value: "80"
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
      volumes:
      - name: web-content
        configMap:
          name: web-content
          items:
          - key: index.html
            path: index.html
      # Restart policy
      restartPolicy: Always
EOF
```

### Step 5: Create the Service
```bash
cat > manifests/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: simple-web-app-service
  namespace: default
  labels:
    app: simple-web-app
    project: beginner-01
spec:
  selector:
    app: simple-web-app
  ports:
  - name: http
    port: 80
    targetPort: 80
    # NodePort for external access (for learning)
    nodePort: 30080
  type: NodePort
---
# Also create a ClusterIP service for internal access
apiVersion: v1
kind: Service
metadata:
  name: simple-web-app-internal
  namespace: default
  labels:
    app: simple-web-app
    project: beginner-01
    service-type: internal
spec:
  selector:
    app: simple-web-app
  ports:
  - name: http
    port: 80
    targetPort: 80
  type: ClusterIP
EOF
```

## 🚀 Deployment Instructions

### Step 6: Deploy the Application
```bash
# Apply all manifests
kubectl apply -f manifests/

# Wait for deployment to be ready
kubectl rollout status deployment/simple-web-app

# Check if pods are running
kubectl get pods -l app=simple-web-app
```

### Step 7: Verify the Deployment
```bash
# Check all resources
kubectl get all -l app=simple-web-app

# Get detailed information
kubectl describe deployment simple-web-app
kubectl describe service simple-web-app-service

# Check endpoints
kubectl get endpoints simple-web-app-service
```

## 🔍 Testing and Validation

### Step 8: Access Your Application

#### Option 1: Using NodePort (External Access)
```bash
# Get node IP
kubectl get nodes -o wide

# Access via browser: http://<NODE_IP>:30080
# Or use curl
curl http://<NODE_IP>:30080
```

#### Option 2: Using Port Forward (Local Development)
```bash
# Forward local port to service
kubectl port-forward service/simple-web-app-service 8080:80

# Access via browser: http://localhost:8080
```

#### Option 3: From Inside the Cluster
```bash
# Run a test pod
kubectl run test-pod --image=busybox --rm -it --restart=Never -- \
  wget -qO- simple-web-app-internal

# Or test DNS resolution
kubectl run test-pod --image=busybox --rm -it --restart=Never -- \
  nslookup simple-web-app-service
```

### Step 9: Test Load Balancing
```bash
# Make multiple requests to see different pod names
for i in {1..10}; do
  echo "Request $i:"
  curl -s http://<NODE_IP>:30080 | grep -o 'Pod.*Loading'
  sleep 1
done
```

## 📊 Monitoring and Scaling

### Step 10: Scale Your Application
```bash
# Scale up to 5 replicas
kubectl scale deployment simple-web-app --replicas=5

# Watch the scaling process
kubectl get pods -l app=simple-web-app -w

# Scale down to 2 replicas
kubectl scale deployment simple-web-app --replicas=2
```

### Step 11: Monitor Resource Usage
```bash
# Check resource usage (if metrics server is installed)
kubectl top pods -l app=simple-web-app

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 🐛 Troubleshooting

### Common Issues and Solutions

#### Pods Not Starting
```bash
# Check pod status
kubectl get pods -l app=simple-web-app

# Describe problematic pod
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>
```

#### Service Not Accessible
```bash
# Verify service exists
kubectl get services

# Check endpoints
kubectl get endpoints simple-web-app-service

# Test internal connectivity
kubectl run debug --image=busybox --rm -it --restart=Never -- \
  wget -qO- simple-web-app-internal
```

#### ConfigMap Issues
```bash
# Verify ConfigMap exists
kubectl get configmap web-content

# Check ConfigMap content
kubectl describe configmap web-content

# Recreate if needed
kubectl delete configmap web-content
kubectl apply -f manifests/configmap.yaml
```

## 🧪 Testing Scripts

### Step 12: Create Automated Tests
```bash
cat > scripts/test.sh << 'EOF'
#!/bin/bash
set -e

echo "🧪 Testing Simple Web App Deployment..."

# Check if deployment exists and is ready
echo "📋 Checking deployment status..."
if ! kubectl get deployment simple-web-app &>/dev/null; then
    echo "❌ Deployment not found!"
    exit 1
fi

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/simple-web-app --timeout=300s

# Check if all pods are running
echo "🔍 Checking pod status..."
RUNNING_PODS=$(kubectl get pods -l app=simple-web-app --field-selector=status.phase=Running --no-headers | wc -l)
DESIRED_REPLICAS=$(kubectl get deployment simple-web-app -o jsonpath='{.spec.replicas}')

if [ "$RUNNING_PODS" -eq "$DESIRED_REPLICAS" ]; then
    echo "✅ All $DESIRED_REPLICAS pods are running"
else
    echo "❌ Only $RUNNING_PODS out of $DESIRED_REPLICAS pods are running"
    kubectl get pods -l app=simple-web-app
    exit 1
fi

# Test service connectivity
echo "🌐 Testing service connectivity..."
if kubectl run test-connectivity --image=busybox --rm -it --restart=Never --timeout=30s -- \
   wget -qO- simple-web-app-internal | grep -q "Welcome to Kubernetes"; then
    echo "✅ Service connectivity test passed"
else
    echo "❌ Service connectivity test failed"
    exit 1
fi

# Test external access (if NodePort is accessible)
echo "🔗 Testing external access..."
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
if curl -s --connect-timeout 10 http://$NODE_IP:30080 | grep -q "Welcome to Kubernetes"; then
    echo "✅ External access test passed"
else
    echo "⚠️  External access test failed (this might be expected in some environments)"
fi

# Test scaling
echo "📈 Testing scaling functionality..."
kubectl scale deployment simple-web-app --replicas=1
kubectl rollout status deployment/simple-web-app --timeout=60s
kubectl scale deployment simple-web-app --replicas=3
kubectl rollout status deployment/simple-web-app --timeout=60s

echo "🎉 All tests passed! Your simple web app is working correctly."
EOF

chmod +x scripts/test.sh
```

## 🧹 Cleanup

### Step 13: Clean Up Resources
```bash
cat > scripts/cleanup.sh << 'EOF'
#!/bin/bash

echo "🧹 Cleaning up Simple Web App resources..."

# Delete all resources
kubectl delete -f manifests/

# Verify cleanup
echo "📋 Verifying cleanup..."
if kubectl get all -l app=simple-web-app --no-headers 2>/dev/null | grep -q .; then
    echo "⚠️  Some resources might still be terminating..."
    kubectl get all -l app=simple-web-app
else
    echo "✅ All resources cleaned up successfully"
fi

echo "🎉 Cleanup completed!"
EOF

chmod +x scripts/cleanup.sh
```

## 📚 Learning Summary

### What You've Accomplished
- ✅ Created your first Kubernetes Deployment
- ✅ Configured a Service for networking
- ✅ Used ConfigMaps for configuration management
- ✅ Implemented health checks and resource limits
- ✅ Learned basic scaling operations
- ✅ Practiced troubleshooting techniques

### Key Concepts Learned
1. **Pods**: The smallest deployable units in Kubernetes
2. **Deployments**: Manage replica sets and provide declarative updates
3. **Services**: Provide stable networking for pod groups
4. **ConfigMaps**: Store non-confidential configuration data
5. **Labels and Selectors**: Organize and select resources
6. **Resource Limits**: Control resource consumption
7. **Health Checks**: Ensure application reliability

### Best Practices Applied
- Used meaningful labels for organization
- Implemented health checks (liveness and readiness probes)
- Set resource requests and limits
- Used ConfigMaps for configuration
- Followed naming conventions
- Created modular manifest files

## 🚀 Next Steps

### Immediate Next Steps
1. **Experiment**: Try modifying the HTML content and redeploy
2. **Scale**: Practice scaling up and down
3. **Monitor**: Watch how Kubernetes manages your pods
4. **Break Things**: Intentionally cause failures to learn troubleshooting

### Extensions and Challenges
1. **Add CSS/JS**: Create a more interactive web application
2. **Custom Image**: Build your own Docker image with custom content
3. **Multiple Environments**: Deploy to different namespaces
4. **Ingress**: Replace NodePort with Ingress for better routing
5. **Monitoring**: Add Prometheus metrics to your application

### Move to Next Project
Ready for the next challenge? Continue with [Project 02: Database App](../02-database-app/) to learn about persistent storage and databases in Kubernetes.

---

**🎉 Congratulations! You've successfully completed your first Kubernetes project!**

*This project is part of the Comprehensive Kubernetes Learning Project. For more information, see the main [README.md](../../../README.md).*
