# Module 04: Configuration Management with ConfigMaps and Secrets

This module covers how to manage application configuration in Kubernetes using ConfigMaps and Secrets, environment variables, and configuration best practices.

## 📚 Learning Objectives

By the end of this module, you will:
- Manage application configuration with ConfigMaps
- Secure sensitive data using Secrets
- Implement various configuration injection methods
- Apply configuration best practices
- Handle configuration updates and hot-reloading
- Manage multi-environment configurations

## 📋 Module Outline

1. [ConfigMaps Fundamentals](#1-configmaps-fundamentals)
2. [Secrets Management](#2-secrets-management)
3. [Environment Variables](#3-environment-variables)
4. [Volume Mounts for Configuration](#4-volume-mounts-for-configuration)
5. [Configuration Patterns](#5-configuration-patterns)
6. [Multi-Environment Configuration](#6-multi-environment-configuration)
7. [Configuration Updates](#7-configuration-updates)
8. [Hands-on Labs](#8-hands-on-labs)
9. [Assessment](#9-assessment)

---

## 1. ConfigMaps Fundamentals

### What are ConfigMaps?

ConfigMaps store non-confidential configuration data in key-value pairs:
- **Application settings** (database URLs, API endpoints)
- **Configuration files** (nginx.conf, application.properties)
- **Feature flags** (enable/disable features)
- **Environment-specific settings**

### Creating ConfigMaps

#### 1. Imperative Creation

```bash
# From literal values
kubectl create configmap app-config \
  --from-literal=database_url="postgresql://localhost:5432/myapp" \
  --from-literal=log_level="info" \
  --from-literal=max_connections="100"

# From files
echo "server.port=8080" > application.properties
echo "spring.datasource.url=jdbc:postgresql://localhost/myapp" >> application.properties
kubectl create configmap app-properties --from-file=application.properties

# From directory
mkdir config
echo "upstream backend { server backend:8080; }" > config/nginx.conf
echo "user nginx;" >> config/nginx.conf
kubectl create configmap nginx-config --from-file=config/

# From env file
echo "DATABASE_URL=postgresql://localhost:5432/myapp" > .env
echo "LOG_LEVEL=debug" >> .env
kubectl create configmap env-config --from-env-file=.env
```

#### 2. Declarative YAML

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: default
data:
  # Simple key-value pairs
  database_url: "postgresql://localhost:5432/myapp"
  log_level: "info"
  max_connections: "100"
  
  # Configuration file
  application.yml: |
    server:
      port: 8080
    spring:
      datasource:
        url: jdbc:postgresql://localhost/myapp
        username: user
    logging:
      level:
        com.mycompany: DEBUG
  
  # Another configuration file
  nginx.conf: |
    events {
        worker_connections 1024;
    }
    
    http {
        upstream backend {
            server backend-service:8080;
        }
        
        server {
            listen 80;
            location / {
                proxy_pass http://backend;
            }
        }
    }
```

### ConfigMap Structure

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: example-config
  namespace: production
  labels:
    app: web-app
    environment: production
data:
  # Text data (UTF-8)
  key1: value1
  key2: value2
  
  # File content
  config.json: |
    {
      "database": {
        "host": "db-server",
        "port": 5432
      }
    }

binaryData:
  # Binary data (base64 encoded)
  cert.p12: LS0tLS1CRUdJTi...
```

---

## 2. Secrets Management

### What are Secrets?

Secrets store sensitive information:
- **Passwords** and **API keys**
- **TLS certificates**
- **OAuth tokens**
- **SSH keys**
- **Database credentials**

### Secret Types

| Type | Description | Use Case |
|------|-------------|----------|
| `Opaque` | Arbitrary user data | Passwords, API keys |
| `kubernetes.io/service-account-token` | Service account token | Pod authentication |
| `kubernetes.io/dockercfg` | Docker registry auth | Image pulling |
| `kubernetes.io/tls` | TLS certificates | HTTPS/TLS termination |
| `kubernetes.io/ssh-auth` | SSH authentication | Git operations |

### Creating Secrets

#### 1. Opaque Secrets

```bash
# From literal values
kubectl create secret generic db-credentials \
  --from-literal=username="admin" \
  --from-literal=password="super-secret-password"

# From files
echo -n "admin" > username.txt
echo -n "super-secret-password" > password.txt
kubectl create secret generic db-credentials \
  --from-file=username.txt \
  --from-file=password.txt

# Base64 encoding (manual)
echo -n "admin" | base64  # YWRtaW4=
echo -n "super-secret-password" | base64  # c3VwZXItc2VjcmV0LXBhc3N3b3Jk
```

#### 2. TLS Secrets

```bash
# Create TLS secret from certificate files
kubectl create secret tls my-tls-secret \
  --cert=server.crt \
  --key=server.key
```

#### 3. Docker Registry Secrets

```bash
# Docker registry authentication
kubectl create secret docker-registry my-registry-secret \
  --docker-server=myregistry.com \
  --docker-username=myuser \
  --docker-password=mypassword \
  --docker-email=myemail@example.com
```

### Secret YAML Examples

#### Opaque Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
data:
  username: YWRtaW4=  # base64 encoded "admin"
  password: c3VwZXItc2VjcmV0LXBhc3N3b3Jk  # base64 encoded "super-secret-password"
```

#### TLS Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1CRUdJTi...  # base64 encoded certificate
  tls.key: LS0tLS1CRUdJTi...  # base64 encoded private key
```

#### Docker Registry Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: registry-secret
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: eyJhdXRocy...  # base64 encoded docker config
```

---

## 3. Environment Variables

### Using ConfigMaps as Environment Variables

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app
    image: nginx:latest
    env:
    # Single value from ConfigMap
    - name: DATABASE_URL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database_url
    
    # Single value from Secret
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: password
    
    # All keys from ConfigMap
    envFrom:
    - configMapRef:
        name: app-config
    
    # All keys from Secret
    envFrom:
    - secretRef:
        name: db-credentials
```

### Environment Variable Patterns

#### 1. Mixed Configuration

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web
        image: myapp:latest
        env:
        # Direct values
        - name: APP_NAME
          value: "My Web Application"
        
        # From ConfigMap
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: log_level
        
        # From Secret
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: api-secrets
              key: api_key
        
        # Pod information
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        
        # Resource information
        - name: MEMORY_LIMIT
          valueFrom:
            resourceFieldRef:
              resource: limits.memory
```

#### 2. Prefix Environment Variables

```yaml
envFrom:
- configMapRef:
    name: app-config
  prefix: "APP_"
- secretRef:
    name: db-secrets
  prefix: "DB_"
```

---

## 4. Volume Mounts for Configuration

### ConfigMap as Volume Mount

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  containers:
  - name: nginx
    image: nginx:latest
    volumeMounts:
    # Mount entire ConfigMap
    - name: config-volume
      mountPath: /etc/nginx/conf.d
    
    # Mount specific key
    - name: app-config-volume
      mountPath: /app/config
      subPath: application.yml
  
  volumes:
  # Entire ConfigMap as volume
  - name: config-volume
    configMap:
      name: nginx-config
  
  # Specific keys with custom filenames
  - name: app-config-volume
    configMap:
      name: app-config
      items:
      - key: application.yml
        path: app.yml
      - key: logging.conf
        path: log.conf
```

### Secret as Volume Mount

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-secrets
spec:
  containers:
  - name: app
    image: myapp:latest
    volumeMounts:
    # TLS certificates
    - name: tls-certs
      mountPath: /etc/ssl/certs
      readOnly: true
    
    # Database credentials
    - name: db-creds
      mountPath: /etc/secrets
      readOnly: true
  
  volumes:
  - name: tls-certs
    secret:
      secretName: tls-secret
      defaultMode: 0400  # Read-only for owner
  
  - name: db-creds
    secret:
      secretName: db-credentials
      items:
      - key: username
        path: db-user
      - key: password
        path: db-pass
        mode: 0600
```

### Advanced Volume Configuration

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: advanced-config
spec:
  containers:
  - name: app
    image: myapp:latest
    volumeMounts:
    - name: config-files
      mountPath: /app/config
  
  volumes:
  - name: config-files
    projected:
      sources:
      # Include ConfigMap
      - configMap:
          name: app-config
          items:
          - key: application.yml
            path: app.yml
      
      # Include Secret
      - secret:
          name: db-credentials
          items:
          - key: username
            path: secrets/db-user
          - key: password
            path: secrets/db-pass
      
      # Include downward API
      - downwardAPI:
          items:
          - path: "labels"
            fieldRef:
              fieldPath: metadata.labels
          - path: "annotations"
            fieldRef:
              fieldPath: metadata.annotations
```

---

## 5. Configuration Patterns

### 1. Layered Configuration

```yaml
# Base configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: base-config
data:
  app.properties: |
    # Base application properties
    server.port=8080
    logging.level.root=INFO
    management.endpoints.web.exposure.include=health,info

---
# Environment-specific override
apiVersion: v1
kind: ConfigMap
metadata:
  name: production-config
data:
  app.properties: |
    # Production overrides
    logging.level.root=WARN
    logging.level.com.mycompany=ERROR
    management.endpoints.web.exposure.include=health
```

### 2. Configuration Template Pattern

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-template
data:
  config.template: |
    database:
      host: ${DATABASE_HOST}
      port: ${DATABASE_PORT}
      name: ${DATABASE_NAME}
    
    redis:
      host: ${REDIS_HOST}
      port: ${REDIS_PORT}
    
    logging:
      level: ${LOG_LEVEL}

---
# Init container to process template
apiVersion: v1
kind: Pod
metadata:
  name: templated-app
spec:
  initContainers:
  - name: config-processor
    image: busybox
    command:
    - sh
    - -c
    - |
      envsubst < /template/config.template > /config/config.yml
    env:
    - name: DATABASE_HOST
      value: "postgres-service"
    - name: DATABASE_PORT
      value: "5432"
    - name: LOG_LEVEL
      value: "info"
    volumeMounts:
    - name: template-volume
      mountPath: /template
    - name: config-volume
      mountPath: /config
  
  containers:
  - name: app
    image: myapp:latest
    volumeMounts:
    - name: config-volume
      mountPath: /app/config
  
  volumes:
  - name: template-volume
    configMap:
      name: app-template
  - name: config-volume
    emptyDir: {}
```

### 3. Feature Flag Pattern

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: feature-flags
data:
  flags.json: |
    {
      "features": {
        "new_ui": {
          "enabled": true,
          "rollout_percentage": 50
        },
        "experimental_api": {
          "enabled": false,
          "allowed_users": ["admin", "beta_tester"]
        },
        "payment_v2": {
          "enabled": true,
          "regions": ["us-east", "eu-west"]
        }
      }
    }
```

---

## 6. Multi-Environment Configuration

### Environment-Based Structure

```
config/
├── base/
│   ├── configmap.yaml
│   └── secret.yaml
├── development/
│   ├── configmap.yaml
│   └── kustomization.yaml
├── staging/
│   ├── configmap.yaml
│   └── kustomization.yaml
└── production/
    ├── configmap.yaml
    └── kustomization.yaml
```

### Base Configuration

```yaml
# base/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  application.yml: |
    server:
      port: 8080
    
    spring:
      profiles:
        active: default
    
    logging:
      level:
        root: INFO

---
# base/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  api-key: ZGVmYXVsdC1rZXk=  # default-key
```

### Environment Overrides

```yaml
# production/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  application.yml: |
    server:
      port: 8080
    
    spring:
      profiles:
        active: production
    
    logging:
      level:
        root: WARN
        com.mycompany: ERROR
    
    management:
      endpoints:
        web:
          exposure:
            include: health,metrics

---
# production/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  api-key: cHJvZHVjdGlvbi1hcGkta2V5  # production-api-key
  db-password: cHJvZC1kYi1wYXNzd29yZA==  # prod-db-password
```

### Kustomization for Environments

```yaml
# production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: production

resources:
- ../base

patchesStrategicMerge:
- configmap.yaml
- secret.yaml

commonLabels:
  environment: production
  version: v1.2.3

replicas:
- name: web-app
  count: 5
```

---

## 7. Configuration Updates

### Rolling Updates with Configuration Changes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  template:
    metadata:
      annotations:
        # Force pod restart when ConfigMap changes
        config.hash: "${CONFIG_HASH}"
    spec:
      containers:
      - name: app
        image: myapp:latest
        env:
        - name: CONFIG_HASH
          value: "${CONFIG_HASH}"
```

### ConfigMap Update Strategies

#### 1. Immutable ConfigMaps

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config-v1  # Version in name
immutable: true
data:
  config.yml: |
    version: "1.0"
    database:
      host: "db-server"
```

#### 2. ConfigMap with Checksum Annotation

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  annotations:
    config.checksum: "sha256:abc123..."
data:
  application.yml: |
    # Configuration content
```

### Hot Reload Patterns

#### 1. Sidecar Pattern for Config Reload

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-config-reload
spec:
  containers:
  # Main application
  - name: app
    image: myapp:latest
    volumeMounts:
    - name: config
      mountPath: /app/config
  
  # Config reload sidecar
  - name: config-reloader
    image: configmap-reload:latest
    args:
    - --volume-dir=/config
    - --webhook-url=http://localhost:8080/reload
    volumeMounts:
    - name: config
      mountPath: /config
  
  volumes:
  - name: config
    configMap:
      name: app-config
```

#### 2. Init Container for Config Processing

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: processed-config-app
spec:
  initContainers:
  - name: config-processor
    image: yq:latest
    command:
    - sh
    - -c
    - |
      # Process and validate configuration
      yq eval '.database.host = env(DATABASE_HOST)' /source/config.yml > /processed/config.yml
      yq eval '.redis.host = env(REDIS_HOST)' -i /processed/config.yml
    env:
    - name: DATABASE_HOST
      value: "production-db"
    - name: REDIS_HOST
      value: "production-redis"
    volumeMounts:
    - name: source-config
      mountPath: /source
    - name: processed-config
      mountPath: /processed
  
  containers:
  - name: app
    image: myapp:latest
    volumeMounts:
    - name: processed-config
      mountPath: /app/config
  
  volumes:
  - name: source-config
    configMap:
      name: app-config-template
  - name: processed-config
    emptyDir: {}
```

---

## 8. Hands-on Labs

### Lab 1: Basic Configuration Management

**Objective**: Create and use ConfigMaps and Secrets

```bash
# Create ConfigMap from literal values
kubectl create configmap app-settings \
  --from-literal=database_host="postgres-service" \
  --from-literal=database_port="5432" \
  --from-literal=log_level="info"

# Create Secret for database credentials
kubectl create secret generic db-credentials \
  --from-literal=username="appuser" \
  --from-literal=password="secretpassword"

# Create application using the configuration
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: config-demo-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: config-demo
  template:
    metadata:
      labels:
        app: config-demo
    spec:
      containers:
      - name: app
        image: busybox
        command: ['sleep', '3600']
        env:
        # From ConfigMap
        - name: DATABASE_HOST
          valueFrom:
            configMapKeyRef:
              name: app-settings
              key: database_host
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: app-settings
              key: log_level
        # From Secret
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
EOF

# Test the configuration
kubectl exec -it deployment/config-demo-app -- env | grep -E "(DATABASE|LOG|DB_)"

# Clean up
kubectl delete deployment config-demo-app
kubectl delete configmap app-settings
kubectl delete secret db-credentials
```

### Lab 2: Configuration Files as Volumes

**Objective**: Mount configuration files into containers

```bash
# Create configuration files
mkdir -p config-files

cat > config-files/nginx.conf <<EOF
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server backend-service:8080;
    }
    
    server {
        listen 80;
        location / {
            proxy_pass http://backend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
        }
    }
}
EOF

cat > config-files/app.properties <<EOF
server.port=8080
spring.datasource.url=jdbc:postgresql://postgres:5432/myapp
logging.level.com.mycompany=DEBUG
EOF

# Create ConfigMap from files
kubectl create configmap app-config-files --from-file=config-files/

# Create application with mounted config files
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-with-config
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-config
  template:
    metadata:
      labels:
        app: nginx-config
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
        - name: app-config
          mountPath: /app/config
      volumes:
      - name: nginx-config
        configMap:
          name: app-config-files
          items:
          - key: nginx.conf
            path: nginx.conf
      - name: app-config
        configMap:
          name: app-config-files
          items:
          - key: app.properties
            path: application.properties
EOF

# Verify configuration files are mounted
kubectl exec -it deployment/nginx-with-config -- cat /etc/nginx/nginx.conf
kubectl exec -it deployment/nginx-with-config -- cat /app/config/application.properties

# Clean up
kubectl delete deployment nginx-with-config
kubectl delete configmap app-config-files
rm -rf config-files
```

### Lab 3: Multi-Environment Configuration

**Objective**: Implement environment-specific configurations

```bash
# Create base configuration
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: base-config
  labels:
    env: base
data:
  app.properties: |
    server.port=8080
    logging.level.root=INFO
    management.endpoints.web.exposure.include=health,info
    database.pool.size=10

---
apiVersion: v1
kind: Secret
metadata:
  name: base-secrets
  labels:
    env: base
type: Opaque
data:
  api-key: YmFzZS1hcGkta2V5  # base-api-key
EOF

# Create development environment configuration
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: dev-config
  labels:
    env: development
data:
  app.properties: |
    server.port=8080
    logging.level.root=DEBUG
    logging.level.com.mycompany=TRACE
    management.endpoints.web.exposure.include=*
    database.pool.size=5
    spring.profiles.active=development

---
apiVersion: v1
kind: Secret
metadata:
  name: dev-secrets
  labels:
    env: development
type: Opaque
data:
  api-key: ZGV2LWFwaS1rZXk=  # dev-api-key
  db-password: ZGV2LXBhc3N3b3Jk  # dev-password
EOF

# Create production environment configuration
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: prod-config
  labels:
    env: production
data:
  app.properties: |
    server.port=8080
    logging.level.root=WARN
    logging.level.com.mycompany=ERROR
    management.endpoints.web.exposure.include=health,metrics
    database.pool.size=20
    spring.profiles.active=production

---
apiVersion: v1
kind: Secret
metadata:
  name: prod-secrets
  labels:
    env: production
type: Opaque
data:
  api-key: cHJvZC1hcGkta2V5  # prod-api-key
  db-password: cHJvZC1zdXBlci1zZWN1cmUtcGFzc3dvcmQ=  # prod-super-secure-password
EOF

# Deploy application for development environment
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-development
  labels:
    env: development
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
      env: development
  template:
    metadata:
      labels:
        app: myapp
        env: development
    spec:
      containers:
      - name: app
        image: busybox
        command: ['sleep', '3600']
        volumeMounts:
        - name: config
          mountPath: /app/config
        env:
        - name: ENVIRONMENT
          value: "development"
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: dev-secrets
              key: api-key
      volumes:
      - name: config
        configMap:
          name: dev-config
EOF

# Verify environment-specific configuration
kubectl exec -it deployment/app-development -- cat /app/config/app.properties
kubectl exec -it deployment/app-development -- env | grep API_KEY

# Clean up
kubectl delete deployment app-development
kubectl delete configmap base-config dev-config prod-config
kubectl delete secret base-secrets dev-secrets prod-secrets
```

### Lab 4: Configuration Update and Reload

**Objective**: Update configurations and handle reload

```bash
# Create initial configuration
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: dynamic-config
data:
  config.json: |
    {
      "version": "1.0",
      "feature_flags": {
        "new_ui": false,
        "beta_features": false
      },
      "settings": {
        "max_users": 100,
        "timeout": 30
      }
    }
EOF

# Create deployment with configuration
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dynamic-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: dynamic-app
  template:
    metadata:
      labels:
        app: dynamic-app
      annotations:
        config.version: "1.0"
    spec:
      containers:
      - name: app
        image: nginx:latest
        volumeMounts:
        - name: config
          mountPath: /app/config
        - name: html
          mountPath: /usr/share/nginx/html
        command: ['sh', '-c']
        args:
        - |
          while true; do
            echo "<h1>Config Version: \$(cat /app/config/config.json | grep version | cut -d':' -f2 | tr -d ' ,"')</h1>" > /usr/share/nginx/html/index.html
            echo "<pre>\$(cat /app/config/config.json)</pre>" >> /usr/share/nginx/html/index.html
            sleep 30
          done &
          nginx -g "daemon off;"
      volumes:
      - name: config
        configMap:
          name: dynamic-config
      - name: html
        emptyDir: {}
EOF

# Expose the service
kubectl expose deployment dynamic-app --port=80 --target-port=80 --type=NodePort

# Check initial configuration
kubectl port-forward service/dynamic-app 8080:80 &
sleep 2
curl http://localhost:8080

# Update configuration
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: dynamic-config
data:
  config.json: |
    {
      "version": "2.0",
      "feature_flags": {
        "new_ui": true,
        "beta_features": true,
        "experimental_api": true
      },
      "settings": {
        "max_users": 500,
        "timeout": 60,
        "cache_ttl": 3600
      }
    }
EOF

# Wait for configuration to be updated (may take up to 60 seconds)
echo "Waiting for configuration update..."
sleep 90

# Check updated configuration
curl http://localhost:8080

# Force pod restart to immediately pick up changes
kubectl patch deployment dynamic-app -p '{"spec":{"template":{"metadata":{"annotations":{"config.version":"2.0"}}}}}'

# Wait for rollout to complete
kubectl rollout status deployment/dynamic-app

# Verify new configuration
curl http://localhost:8080

# Clean up
pkill -f "kubectl port-forward"
kubectl delete deployment dynamic-app
kubectl delete service dynamic-app
kubectl delete configmap dynamic-config
```

---

## 9. Assessment

### Knowledge Check Questions

1. **ConfigMaps vs Secrets**: When would you use a ConfigMap versus a Secret?

2. **Configuration Methods**: What are the different ways to inject configuration into a pod?

3. **Volume Mounts**: What are the advantages of using volume mounts versus environment variables for configuration?

4. **Updates**: How can you ensure pods are restarted when configuration changes?

5. **Security**: What are the security considerations when using Secrets?

### Practical Exercises

#### Exercise 1: Complete Application Configuration
Configure a three-tier application (frontend, backend, database) with:
- Environment-specific configurations
- Secure database credentials
- Application feature flags
- Proper separation of concerns

#### Exercise 2: Configuration Management Pipeline
Implement a configuration management system:
- Base configurations with environment overlays
- Validation of configuration changes
- Automated deployment with configuration updates
- Rollback capabilities

#### Exercise 3: Security Best Practices
Implement secure configuration management:
- Encrypted secrets at rest
- RBAC for configuration access
- Audit logging for configuration changes
- Secret rotation procedures

### Hands-on Project: Microservices Configuration

Deploy a microservices application with comprehensive configuration management:

```yaml
# Shared configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: shared-config
data:
  common.yml: |
    logging:
      level: info
      format: json
    
    monitoring:
      metrics:
        enabled: true
        port: 9090
      
      tracing:
        enabled: true
        jaeger_endpoint: http://jaeger:14268/api/traces

---
# Service-specific configurations
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config
data:
  config.js: |
    window.config = {
      api_base_url: '/api',
      features: {
        user_registration: true,
        payment_gateway: true,
        analytics: true
      },
      ui: {
        theme: 'modern',
        language: 'en'
      }
    };

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
data:
  application.yml: |
    server:
      port: 8080
    
    spring:
      datasource:
        url: jdbc:postgresql://postgres:5432/myapp
        username: ${DB_USERNAME}
        password: ${DB_PASSWORD}
      
      redis:
        host: redis
        port: 6379
        password: ${REDIS_PASSWORD}
    
    app:
      jwt:
        secret: ${JWT_SECRET}
        expiration: 86400
      
      external_apis:
        payment_gateway: ${PAYMENT_API_URL}
        notification_service: ${NOTIFICATION_API_URL}

---
# Secrets
apiVersion: v1
kind: Secret
metadata:
  name: database-credentials
type: Opaque
data:
  username: YXBwdXNlcg==  # appuser
  password: c2VjdXJlcGFzc3dvcmQ=  # securepassword

---
apiVersion: v1
kind: Secret
metadata:
  name: api-keys
type: Opaque
data:
  jwt-secret: bXlzdXBlcnNlY3JldGp3dGtleQ==  # mysupersecretjwtkey
  redis-password: cmVkaXNwYXNzd29yZA==  # redispassword
  payment-api-key: cGF5bWVudC1hcGkta2V5LTEyMzQ1  # payment-api-key-12345
```

### Assessment Rubric

| Skill Area | Beginner | Intermediate | Advanced |
|------------|----------|--------------|----------|
| **ConfigMaps** | Basic key-value pairs | File mounting | Complex configurations |
| **Secrets** | Basic secrets | Multiple secret types | Security best practices |
| **Environment Variables** | Simple env vars | Complex injection | Template processing |
| **Multi-Environment** | Single environment | Basic environments | Full CI/CD integration |
| **Updates** | Manual updates | Rolling updates | Automated reload |

---

## 📚 Additional Resources

### Official Documentation
- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Environment Variables](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)

### Security Best Practices
- [Secrets Security](https://kubernetes.io/docs/concepts/security/secrets-good-practices/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

### Tools and Utilities
- [Kustomize](https://kustomize.io/) - Configuration management
- [Helm](https://helm.sh/) - Package manager with templating
- [Sealed Secrets](https://sealed-secrets.netlify.app/) - Encrypted secrets

---

## ✅ Module Completion Checklist

- [ ] Create and manage ConfigMaps
- [ ] Implement secure Secrets management
- [ ] Use various configuration injection methods
- [ ] Mount configuration files as volumes
- [ ] Implement multi-environment configurations
- [ ] Handle configuration updates and reloads
- [ ] Apply security best practices
- [ ] Complete all hands-on labs
- [ ] Pass assessment with 80% or higher

---

**Next Module**: [05-storage](../05-storage/README.md) - Persistent Storage and Volume Management

**Estimated Time**: 5-6 days  
**Difficulty**: Intermediate  
**Prerequisites**: Module 03 completed
