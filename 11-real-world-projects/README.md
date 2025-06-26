# Module 11: Real-World Projects

## 📚 Learning Objectives

By the end of this module, you will have:
- Built complete, production-ready applications on Kubernetes
- Implemented microservices architectures with best practices
- Created CI/CD pipelines for Kubernetes applications
- Deployed monitoring, logging, and security solutions
- Gained hands-on experience with real-world scenarios
- Developed troubleshooting skills for complex systems

## 🎯 Prerequisites

- Completed Module 10: Advanced Concepts
- Strong understanding of all previous modules
- Familiarity with application development and architecture
- Basic knowledge of CI/CD concepts

## 📖 Project Overview

This module contains three comprehensive real-world projects that integrate all Kubernetes concepts learned in previous modules. Each project builds upon the previous one, increasing in complexity and scope.

## 🚀 Project 1: E-Commerce Platform

### Project Description
Build a complete e-commerce platform with microservices architecture, including frontend, backend services, databases, caching, and monitoring.

### Architecture Components
- **Frontend**: React application (static files served by Nginx)
- **API Gateway**: NGINX Ingress Controller
- **User Service**: User authentication and management
- **Product Service**: Product catalog and inventory
- **Order Service**: Order processing and management
- **Payment Service**: Payment processing simulation
- **Database**: PostgreSQL for persistent data
- **Cache**: Redis for session and data caching
- **Monitoring**: Prometheus and Grafana
- **Logging**: ELK Stack

### Implementation

#### 1. Setup Project Namespace and Base Configuration

```bash
# Create project namespace
kubectl create namespace ecommerce

# Create necessary ConfigMaps
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: ecommerce
data:
  DATABASE_HOST: "postgres-service"
  DATABASE_PORT: "5432"
  DATABASE_NAME: "ecommerce"
  REDIS_HOST: "redis-service"
  REDIS_PORT: "6379"
  NODE_ENV: "production"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: ecommerce
data:
  default.conf: |
    server {
        listen 80;
        server_name localhost;
        root /usr/share/nginx/html;
        index index.html;
        
        location / {
            try_files \$uri \$uri/ /index.html;
        }
        
        location /api/ {
            proxy_pass http://api-gateway-service/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
        }
        
        location /health {
            access_log off;
            return 200 "healthy\n";
        }
    }
EOF
```

#### 2. Deploy Database Layer

```bash
# PostgreSQL with persistent storage
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: ecommerce
type: Opaque
data:
  username: cG9zdGdyZXM=  # postgres
  password: cGFzc3dvcmQxMjM=  # password123
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: ecommerce
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: ecommerce
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
        tier: database
    spec:
      containers:
      - name: postgres
        image: postgres:13
        env:
        - name: POSTGRES_DB
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: DATABASE_NAME
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: username
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
        livenessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - postgres
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - postgres
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
  namespace: ecommerce
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
EOF
```

```bash
# Redis for caching
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: ecommerce
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
        tier: cache
    spec:
      containers:
      - name: redis
        image: redis:6-alpine
        ports:
        - containerPort: 6379
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
        livenessProbe:
          tcpSocket:
            port: 6379
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          tcpSocket:
            port: 6379
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
  namespace: ecommerce
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
  type: ClusterIP
EOF
```

#### 3. Deploy Microservices

```bash
# User Service
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: ecommerce
spec:
  replicas: 2
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
        tier: backend
    spec:
      containers:
      - name: user-service
        image: nginx:alpine  # Placeholder - would be your actual service image
        ports:
        - containerPort: 80
        env:
        - name: SERVICE_NAME
          value: "user-service"
        envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: postgres-secret
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 300m
            memory: 256Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: ecommerce
  labels:
    app: user-service
spec:
  selector:
    app: user-service
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
---
# Product Service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service
  namespace: ecommerce
spec:
  replicas: 3
  selector:
    matchLabels:
      app: product-service
  template:
    metadata:
      labels:
        app: product-service
        tier: backend
    spec:
      containers:
      - name: product-service
        image: nginx:alpine  # Placeholder
        ports:
        - containerPort: 80
        env:
        - name: SERVICE_NAME
          value: "product-service"
        envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: postgres-secret
        resources:
          requests:
            cpu: 150m
            memory: 128Mi
          limits:
            cpu: 400m
            memory: 256Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: product-service
  namespace: ecommerce
spec:
  selector:
    app: product-service
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
---
# Order Service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
  namespace: ecommerce
spec:
  replicas: 2
  selector:
    matchLabels:
      app: order-service
  template:
    metadata:
      labels:
        app: order-service
        tier: backend
    spec:
      containers:
      - name: order-service
        image: nginx:alpine  # Placeholder
        ports:
        - containerPort: 80
        env:
        - name: SERVICE_NAME
          value: "order-service"
        envFrom:
        - configMapRef:
            name: app-config
        - secretRef:
            name: postgres-secret
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 300m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: order-service
  namespace: ecommerce
spec:
  selector:
    app: order-service
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF
```

#### 4. Deploy API Gateway and Frontend

```bash
# API Gateway (NGINX)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: ecommerce
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-gateway
  template:
    metadata:
      labels:
        app: api-gateway
        tier: gateway
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d/
        resources:
          requests:
            cpu: 100m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 128Mi
      volumes:
      - name: nginx-config
        configMap:
          name: api-gateway-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-gateway-config
  namespace: ecommerce
data:
  default.conf: |
    upstream user-service {
        server user-service:80;
    }
    upstream product-service {
        server product-service:80;
    }
    upstream order-service {
        server order-service:80;
    }
    
    server {
        listen 80;
        
        location /users/ {
            proxy_pass http://user-service/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
        }
        
        location /products/ {
            proxy_pass http://product-service/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
        }
        
        location /orders/ {
            proxy_pass http://order-service/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
        }
        
        location /health {
            access_log off;
            return 200 "API Gateway healthy\n";
        }
    }
---
apiVersion: v1
kind: Service
metadata:
  name: api-gateway-service
  namespace: ecommerce
spec:
  selector:
    app: api-gateway
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF
```

```bash
# Frontend Application
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: ecommerce
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d/
        - name: static-content
          mountPath: /usr/share/nginx/html
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 100m
            memory: 128Mi
      volumes:
      - name: nginx-config
        configMap:
          name: nginx-config
      - name: static-content
        configMap:
          name: frontend-content
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-content
  namespace: ecommerce
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>E-Commerce Platform</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; }
            .header { color: #333; text-align: center; }
            .nav { background: #f0f0f0; padding: 10px; margin: 20px 0; }
            .content { margin: 20px 0; }
            .footer { text-align: center; margin-top: 40px; color: #666; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🛒 E-Commerce Platform</h1>
            <p>Kubernetes-powered microservices application</p>
        </div>
        
        <div class="nav">
            <a href="#products">Products</a> |
            <a href="#orders">Orders</a> |
            <a href="#profile">Profile</a>
        </div>
        
        <div class="content">
            <h2>Welcome to our platform!</h2>
            <p>This is a demonstration e-commerce application running on Kubernetes.</p>
            
            <h3>Architecture:</h3>
            <ul>
                <li>Frontend: Nginx serving static content</li>
                <li>API Gateway: NGINX routing to microservices</li>
                <li>User Service: User management</li>
                <li>Product Service: Product catalog</li>
                <li>Order Service: Order processing</li>
                <li>Database: PostgreSQL</li>
                <li>Cache: Redis</li>
            </ul>
        </div>
        
        <div class="footer">
            <p>Powered by Kubernetes | Built for learning</p>
        </div>
    </body>
    </html>
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: ecommerce
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF
```

#### 5. Setup Ingress and External Access

```bash
# Create Ingress for external access
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ecommerce-ingress
  namespace: ecommerce
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: ecommerce.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-gateway-service
            port:
              number: 80
EOF
```

#### 6. Add Monitoring and Health Checks

```bash
# ServiceMonitor for Prometheus (if using Prometheus Operator)
kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: ecommerce-monitoring
  namespace: ecommerce
spec:
  selector:
    matchLabels:
      tier: backend
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
EOF
```

#### 7. Implement Horizontal Pod Autoscaler

```bash
# HPA for Product Service (most likely to need scaling)
kubectl apply -f - <<EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: product-service-hpa
  namespace: ecommerce
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: product-service
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
EOF
```

#### 8. Test the Application

```bash
# Check all deployments
kubectl get all -n ecommerce

# Check ingress
kubectl get ingress -n ecommerce

# Test internal connectivity
kubectl run test-pod --image=busybox --rm -it -n ecommerce -- sh
# Inside pod: wget -qO- http://frontend-service
# Inside pod: wget -qO- http://api-gateway-service/health

# Get ingress IP and test external access
INGRESS_IP=$(kubectl get ingress -n ecommerce ecommerce-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Access the application at: http://$INGRESS_IP"

# Add to /etc/hosts if using hostname
echo "$INGRESS_IP ecommerce.local" | sudo tee -a /etc/hosts
```

## 🚀 Project 2: CI/CD Pipeline for Kubernetes

### Project Description
Build a complete CI/CD pipeline that automatically builds, tests, and deploys applications to Kubernetes using GitOps principles.

### Architecture Components
- **Source Control**: Git repository simulation
- **CI Pipeline**: Jenkins or GitHub Actions simulation
- **Container Registry**: Local Docker registry
- **GitOps Controller**: ArgoCD or Flux simulation
- **Staging Environment**: Kubernetes namespace
- **Production Environment**: Kubernetes namespace
- **Security Scanning**: Container and dependency scanning
- **Testing**: Automated testing framework

### Implementation

#### 1. Setup CI/CD Infrastructure

```bash
# Create namespaces
kubectl create namespace cicd
kubectl create namespace staging
kubectl create namespace production

# Create Docker registry
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: docker-registry
  namespace: cicd
spec:
  replicas: 1
  selector:
    matchLabels:
      app: docker-registry
  template:
    metadata:
      labels:
        app: docker-registry
    spec:
      containers:
      - name: registry
        image: registry:2
        ports:
        - containerPort: 5000
        env:
        - name: REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY
          value: /var/lib/registry
        volumeMounts:
        - name: registry-storage
          mountPath: /var/lib/registry
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
      volumes:
      - name: registry-storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: docker-registry
  namespace: cicd
spec:
  selector:
    app: docker-registry
  ports:
  - port: 5000
    targetPort: 5000
  type: ClusterIP
EOF
```

#### 2. Create Sample Application with Multiple Environments

```bash
# Staging Environment
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: staging
data:
  ENV: "staging"
  DEBUG: "true"
  DATABASE_URL: "postgres://staging-db:5432/app"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
  namespace: staging
  labels:
    app: sample-app
    version: "v1.0.0"
spec:
  replicas: 2
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
        version: "v1.0.0"
    spec:
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 80
        envFrom:
        - configMapRef:
            name: app-config
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 100m
            memory: 128Mi
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: sample-app-service
  namespace: staging
spec:
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF
```

```bash
# Production Environment
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: production
data:
  ENV: "production"
  DEBUG: "false"
  DATABASE_URL: "postgres://prod-db:5432/app"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
  namespace: production
  labels:
    app: sample-app
    version: "v1.0.0"
spec:
  replicas: 4
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
        version: "v1.0.0"
    spec:
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 80
        envFrom:
        - configMapRef:
            name: app-config
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: sample-app-service
  namespace: production
spec:
  selector:
    app: sample-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
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
  minReplicas: 4
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
EOF
```

#### 3. Simulate CI/CD Pipeline with Jobs

```bash
# CI Pipeline Job Template
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: ci-pipeline-$(date +%s)
  namespace: cicd
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: ci-pipeline
        image: alpine/git
        command:
        - /bin/sh
        - -c
        - |
          echo "=== CI Pipeline Started ==="
          echo "1. Cloning repository..."
          sleep 2
          
          echo "2. Running unit tests..."
          sleep 3
          
          echo "3. Running integration tests..."
          sleep 2
          
          echo "4. Security scanning..."
          sleep 2
          
          echo "5. Building container image..."
          sleep 3
          
          echo "6. Pushing to registry..."
          sleep 2
          
          echo "7. Updating deployment manifests..."
          sleep 1
          
          echo "=== CI Pipeline Completed Successfully ==="
      backoffLimit: 3
EOF
```

#### 4. Create Deployment Pipeline

```bash
# CD Pipeline Job
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: cd-pipeline-staging-$(date +%s)
  namespace: cicd
spec:
  template:
    spec:
      restartPolicy: Never
      serviceAccountName: cd-pipeline-sa
      containers:
      - name: cd-pipeline
        image: bitnami/kubectl
        command:
        - /bin/bash
        - -c
        - |
          echo "=== CD Pipeline Started ==="
          echo "1. Validating Kubernetes manifests..."
          sleep 1
          
          echo "2. Applying to staging environment..."
          kubectl patch deployment sample-app -n staging -p='{"spec":{"template":{"metadata":{"labels":{"updated":"'$(date +%s)'"}}}}}' || true
          
          echo "3. Waiting for rollout..."
          kubectl rollout status deployment/sample-app -n staging --timeout=300s
          
          echo "4. Running smoke tests..."
          sleep 2
          
          echo "5. Staging deployment completed successfully!"
          
          echo "=== Ready for Production Deployment ==="
      backoffLimit: 3
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cd-pipeline-sa
  namespace: cicd
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cd-pipeline-role
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "patch", "update"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cd-pipeline-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cd-pipeline-role
subjects:
- kind: ServiceAccount
  name: cd-pipeline-sa
  namespace: cicd
EOF
```

#### 5. Implement Blue-Green Deployment

```bash
# Blue-Green Deployment Controller
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: blue-green-script
  namespace: cicd
data:
  deploy.sh: |
    #!/bin/bash
    NAMESPACE=\${1:-production}
    NEW_VERSION=\${2:-v1.1.0}
    
    echo "Starting Blue-Green Deployment to \$NAMESPACE"
    echo "New version: \$NEW_VERSION"
    
    # Check current version
    CURRENT_VERSION=\$(kubectl get deployment sample-app -n \$NAMESPACE -o jsonpath='{.metadata.labels.version}')
    echo "Current version: \$CURRENT_VERSION"
    
    # Deploy green version
    echo "Deploying green version..."
    kubectl create deployment sample-app-green -n \$NAMESPACE \\
      --image=nginx:alpine \\
      --replicas=4 \\
      --dry-run=client -o yaml | \\
      kubectl label --local -f - version=\$NEW_VERSION -o yaml | \\
      kubectl apply -f -
    
    # Wait for green deployment
    kubectl rollout status deployment/sample-app-green -n \$NAMESPACE --timeout=300s
    
    # Run health checks
    echo "Running health checks on green deployment..."
    sleep 10
    
    # Switch traffic to green
    echo "Switching traffic to green deployment..."
    kubectl patch service sample-app-service -n \$NAMESPACE -p '{"spec":{"selector":{"app":"sample-app-green"}}}'
    
    # Clean up blue deployment after successful switch
    sleep 30
    echo "Cleaning up blue deployment..."
    kubectl delete deployment sample-app -n \$NAMESPACE || true
    
    # Rename green to primary
    kubectl patch deployment sample-app-green -n \$NAMESPACE -p '{"metadata":{"name":"sample-app"}}'
    
    echo "Blue-Green deployment completed successfully!"
---
apiVersion: batch/v1
kind: Job
metadata:
  name: blue-green-deployment-$(date +%s)
  namespace: cicd
spec:
  template:
    spec:
      restartPolicy: Never
      serviceAccountName: cd-pipeline-sa
      containers:
      - name: blue-green-deploy
        image: bitnami/kubectl
        command: ["/bin/bash"]
        args: ["/scripts/deploy.sh", "production", "v1.1.0"]
        volumeMounts:
        - name: script-volume
          mountPath: /scripts
      volumes:
      - name: script-volume
        configMap:
          name: blue-green-script
          defaultMode: 0755
      backoffLimit: 1
EOF
```

## 🚀 Project 3: Multi-Tenant SaaS Platform

### Project Description
Build a complete multi-tenant Software-as-a-Service platform with tenant isolation, resource quotas, monitoring, and automated provisioning.

### Architecture Components
- **Tenant Management Service**: API for managing tenants
- **Isolation**: Namespace-based tenant isolation
- **Resource Management**: Resource quotas and limits
- **Networking**: Network policies for tenant isolation
- **Data Isolation**: Tenant-specific databases
- **Monitoring**: Per-tenant monitoring and alerting
- **Backup and Recovery**: Automated backup solutions
- **Auto-scaling**: Tenant-specific scaling policies

### Implementation

#### 1. Create Tenant Management System

```bash
# Create multi-tenant namespace
kubectl create namespace multi-tenant

# Tenant CRD
kubectl apply -f - <<EOF
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: tenants.saas.example.com
spec:
  group: saas.example.com
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              name:
                type: string
              plan:
                type: string
                enum: ["basic", "premium", "enterprise"]
              resources:
                type: object
                properties:
                  cpu:
                    type: string
                  memory:
                    type: string
                  storage:
                    type: string
              features:
                type: array
                items:
                  type: string
            required:
            - name
            - plan
          status:
            type: object
            properties:
              phase:
                type: string
                enum: ["Pending", "Active", "Suspended", "Terminated"]
              namespace:
                type: string
              createdAt:
                type: string
                format: date-time
    additionalPrinterColumns:
    - name: Plan
      type: string
      jsonPath: .spec.plan
    - name: Status
      type: string
      jsonPath: .status.phase
    - name: Namespace
      type: string
      jsonPath: .status.namespace
    - name: Age
      type: date
      jsonPath: .metadata.creationTimestamp
  scope: Cluster
  names:
    plural: tenants
    singular: tenant
    kind: Tenant
    shortNames:
    - tn
EOF
```

#### 2. Create Tenant Operator

```bash
# Tenant Operator RBAC
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tenant-operator
  namespace: multi-tenant
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: tenant-operator
rules:
- apiGroups: ["saas.example.com"]
  resources: ["tenants"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["namespaces", "resourcequotas", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["networking.k8s.io"]
  resources: ["networkpolicies"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: ["rbac.authorization.k8s.io"]
  resources: ["roles", "rolebindings"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tenant-operator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: tenant-operator
subjects:
- kind: ServiceAccount
  name: tenant-operator
  namespace: multi-tenant
EOF
```

```bash
# Tenant Operator Deployment
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tenant-operator
  namespace: multi-tenant
spec:
  replicas: 1
  selector:
    matchLabels:
      app: tenant-operator
  template:
    metadata:
      labels:
        app: tenant-operator
    spec:
      serviceAccountName: tenant-operator
      containers:
      - name: operator
        image: bitnami/kubectl
        command:
        - /bin/bash
        - -c
        - |
          while true; do
            echo "Checking tenant resources..."
            
            kubectl get tenants -o json | jq -r '.items[] | select(.status.phase != "Active") | "\(.metadata.name) \(.spec.plan) \(.spec.name)"' | while read tenant_cr plan name; do
              if [ ! -z "\$tenant_cr" ]; then
                echo "Processing tenant: \$tenant_cr (plan: \$plan)"
                
                # Create namespace
                NAMESPACE="tenant-\$name"
                kubectl create namespace \$NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
                
                # Create resource quota based on plan
                case \$plan in
                  "basic")
                    CPU_LIMIT="2"
                    MEMORY_LIMIT="4Gi"
                    STORAGE_LIMIT="10Gi"
                    POD_LIMIT="10"
                    ;;
                  "premium")
                    CPU_LIMIT="8"
                    MEMORY_LIMIT="16Gi"
                    STORAGE_LIMIT="50Gi"
                    POD_LIMIT="50"
                    ;;
                  "enterprise")
                    CPU_LIMIT="32"
                    MEMORY_LIMIT="64Gi"
                    STORAGE_LIMIT="200Gi"
                    POD_LIMIT="200"
                    ;;
                esac
                
                kubectl apply -f - <<QUOTA
          apiVersion: v1
          kind: ResourceQuota
          metadata:
            name: tenant-quota
            namespace: \$NAMESPACE
          spec:
            hard:
              requests.cpu: \$CPU_LIMIT
              requests.memory: \$MEMORY_LIMIT
              persistentvolumeclaims: "5"
              pods: \$POD_LIMIT
              services: "10"
          QUOTA
                
                # Create network policy for isolation
                kubectl apply -f - <<NETPOL
          apiVersion: networking.k8s.io/v1
          kind: NetworkPolicy
          metadata:
            name: tenant-isolation
            namespace: \$NAMESPACE
          spec:
            podSelector: {}
            policyTypes:
            - Ingress
            - Egress
            ingress:
            - from:
              - namespaceSelector:
                  matchLabels:
                    name: \$NAMESPACE
            egress:
            - to:
              - namespaceSelector:
                  matchLabels:
                    name: \$NAMESPACE
            - to: []
              ports:
              - protocol: TCP
                port: 53
              - protocol: UDP
                port: 53
          NETPOL
                
                # Label namespace
                kubectl label namespace \$NAMESPACE name=\$NAMESPACE tenant=\$name plan=\$plan --overwrite
                
                # Deploy tenant application
                kubectl apply -f - <<DEPLOY
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: tenant-app
            namespace: \$NAMESPACE
          spec:
            replicas: 2
            selector:
              matchLabels:
                app: tenant-app
            template:
              metadata:
                labels:
                  app: tenant-app
                  tenant: \$name
              spec:
                containers:
                - name: app
                  image: nginx:alpine
                  ports:
                  - containerPort: 80
                  env:
                  - name: TENANT_NAME
                    value: \$name
                  - name: TENANT_PLAN
                    value: \$plan
                  resources:
                    requests:
                      cpu: 100m
                      memory: 128Mi
                    limits:
                      cpu: 500m
                      memory: 512Mi
          ---
          apiVersion: v1
          kind: Service
          metadata:
            name: tenant-app-service
            namespace: \$NAMESPACE
          spec:
            selector:
              app: tenant-app
            ports:
            - port: 80
              targetPort: 80
          DEPLOY
                
                # Update tenant status
                kubectl patch tenant \$tenant_cr --type='merge' --subresource='status' -p="{
                  \"status\": {
                    \"phase\": \"Active\",
                    \"namespace\": \"\$NAMESPACE\",
                    \"createdAt\": \"\$(date -u +\"%Y-%m-%dT%H:%M:%SZ\")\"
                  }
                }" || true
                
                echo "Tenant \$tenant_cr provisioned successfully"
              fi
            done
            
            sleep 30
          done
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
EOF
```

#### 3. Create Sample Tenants

```bash
# Create sample tenants
kubectl apply -f - <<EOF
apiVersion: saas.example.com/v1
kind: Tenant
metadata:
  name: acme-corp
spec:
  name: acme-corp
  plan: enterprise
  resources:
    cpu: "16"
    memory: "32Gi"
    storage: "100Gi"
  features:
    - "advanced-analytics"
    - "custom-integrations"
    - "priority-support"
---
apiVersion: saas.example.com/v1
kind: Tenant
metadata:
  name: startup-inc
spec:
  name: startup-inc
  plan: basic
  resources:
    cpu: "1"
    memory: "2Gi"
    storage: "5Gi"
  features:
    - "basic-analytics"
---
apiVersion: saas.example.com/v1
kind: Tenant
metadata:
  name: midsize-co
spec:
  name: midsize-co
  plan: premium
  resources:
    cpu: "4"
    memory: "8Gi"
    storage: "25Gi"
  features:
    - "advanced-analytics"
    - "api-access"
EOF
```

#### 4. Monitor Tenant Resources

```bash
# Wait for tenants to be provisioned
sleep 120

# Check tenant status
kubectl get tenants

# Check created namespaces
kubectl get namespaces | grep tenant-

# Check resource quotas
kubectl get resourcequota --all-namespaces | grep tenant-

# Check tenant applications
kubectl get pods --all-namespaces | grep tenant-

# Test tenant isolation
echo "Testing tenant isolation..."
kubectl run network-test --image=busybox --rm -it -n tenant-acme-corp -- sh
# Inside pod: nslookup tenant-app-service.tenant-startup-inc.svc.cluster.local (should fail)
```

#### 5. Implement Tenant Monitoring

```bash
# Create monitoring for tenants
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: tenant-monitoring
  namespace: multi-tenant
data:
  monitor.sh: |
    #!/bin/bash
    echo "=== Tenant Monitoring Report ==="
    echo "Generated at: \$(date)"
    echo
    
    echo "Active Tenants:"
    kubectl get tenants --no-headers | while read name plan status namespace age; do
      echo "- \$name (\$plan): \$status"
      
      if [ "\$status" = "Active" ]; then
        echo "  Namespace: \$namespace"
        echo "  Resource Usage:"
        kubectl top pods -n \$namespace 2>/dev/null | tail -n +2 | awk '{cpu+=\$2; mem+=\$3} END {print "    CPU: " cpu "m, Memory: " mem "Mi"}' || echo "    Metrics not available"
        echo "  Pod Count: \$(kubectl get pods -n \$namespace --no-headers | wc -l)"
        echo
      fi
    done
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: tenant-monitoring
  namespace: multi-tenant
spec:
  schedule: "*/5 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: tenant-operator
          containers:
          - name: monitor
            image: bitnami/kubectl
            command: ["/bin/bash"]
            args: ["/scripts/monitor.sh"]
            volumeMounts:
            - name: script-volume
              mountPath: /scripts
          volumes:
          - name: script-volume
            configMap:
              name: tenant-monitoring
              defaultMode: 0755
          restartPolicy: OnFailure
EOF
```

## 💡 Project Best Practices

### 1. Security
- Implement proper RBAC for all components
- Use network policies for isolation
- Scan container images for vulnerabilities
- Rotate secrets regularly
- Implement admission controllers for policy enforcement

### 2. Reliability
- Design for high availability
- Implement proper health checks and monitoring
- Use resource limits and quotas
- Plan for disaster recovery
- Test failure scenarios regularly

### 3. Scalability
- Use horizontal pod autoscaling
- Implement cluster autoscaling
- Design stateless applications
- Use appropriate storage solutions
- Monitor and optimize resource usage

### 4. Maintainability
- Use GitOps for deployments
- Implement proper logging and monitoring
- Document architectures and processes
- Use standardized configurations
- Automate operational tasks

## 📝 Project Assessment

### Project 1 Assessment
1. **Architecture Review**: Evaluate the microservices design and communication patterns
2. **Performance Testing**: Load test the application and measure response times
3. **Security Analysis**: Review RBAC, network policies, and secret management
4. **Scalability Testing**: Test horizontal scaling under load
5. **Monitoring Setup**: Implement comprehensive monitoring and alerting

### Project 2 Assessment
1. **Pipeline Efficiency**: Measure build and deployment times
2. **Rollback Testing**: Test blue-green deployment rollback scenarios
3. **Security Integration**: Add security scanning to the pipeline
4. **Multi-Environment**: Deploy to multiple environments with proper promotion
5. **Automation Level**: Evaluate the level of automation achieved

### Project 3 Assessment
1. **Tenant Isolation**: Verify complete isolation between tenants
2. **Resource Management**: Test resource quota enforcement
3. **Operator Functionality**: Evaluate custom operator performance
4. **Monitoring Coverage**: Ensure comprehensive per-tenant monitoring
5. **Scaling Scenarios**: Test tenant onboarding and scaling

## 🎯 Module Summary

You have completed:
- ✅ Built a complete e-commerce platform with microservices
- ✅ Implemented a full CI/CD pipeline with GitOps
- ✅ Created a multi-tenant SaaS platform with custom operators
- ✅ Applied security, monitoring, and scaling best practices
- ✅ Gained experience with real-world Kubernetes challenges
- ✅ Integrated all Kubernetes concepts from previous modules
- ✅ Developed production-ready deployment strategies

## 🔄 Next Steps

Ready for the final module? Continue to:
**[Module 12: Production Practices](../12-production-practices/README.md)**

## 📚 Additional Resources

- [Kubernetes Production Best Practices](https://kubernetes.io/docs/setup/best-practices/)
- [Microservices Patterns](https://microservices.io/patterns/)
- [GitOps Guide](https://www.gitops.tech/)
- [Multi-Tenancy in Kubernetes](https://kubernetes.io/docs/concepts/security/multi-tenancy/)

---

**🏗️ Real-World Tip**: These projects simulate real production scenarios. Practice them multiple times, experiment with different approaches, and adapt them to your specific use cases!
