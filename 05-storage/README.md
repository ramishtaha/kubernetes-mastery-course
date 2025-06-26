# Module 5: Storage in Kubernetes

## 📚 Learning Objectives

By the end of this module, you will understand:
- Kubernetes storage concepts and architecture
- Different types of volumes and their use cases
- Persistent Volumes (PV) and Persistent Volume Claims (PVC)
- Storage Classes and dynamic provisioning
- StatefulSets and persistent storage
- Storage best practices and troubleshooting

## 🎯 Prerequisites

- Completed Module 4: Configuration Management
- Basic understanding of file systems and storage
- Familiarity with Kubernetes workloads

## 📖 Theory: Kubernetes Storage

### Storage Architecture Overview

Kubernetes provides several storage abstractions:

1. **Volumes**: Mounted storage accessible to containers in a Pod
2. **Persistent Volumes (PV)**: Cluster-wide storage resources
3. **Persistent Volume Claims (PVC)**: User requests for storage
4. **Storage Classes**: Dynamic storage provisioning templates

### Volume Types

#### 1. EmptyDir
- Temporary storage that exists for the Pod's lifetime
- Shared between containers in the same Pod
- Data is lost when Pod is deleted

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-emptydir
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: temp-storage
      mountPath: /tmp/shared
  volumes:
  - name: temp-storage
    emptyDir: {}
```

#### 2. HostPath
- Mounts file or directory from host node
- Useful for system-level containers
- Not portable across nodes

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-hostpath
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: host-storage
      mountPath: /host-data
  volumes:
  - name: host-storage
    hostPath:
      path: /var/log
      type: Directory
```

#### 3. ConfigMap and Secret Volumes
- Mount configuration data as files
- Automatically updated when ConfigMap/Secret changes

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-config
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
    - name: secret-volume
      mountPath: /etc/secrets
  volumes:
  - name: config-volume
    configMap:
      name: app-config
  - name: secret-volume
    secret:
      secretName: app-secrets
```

### Persistent Volumes (PV)

Persistent Volumes are cluster-wide storage resources:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-local
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /mnt/disk1
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - worker-node-1
```

### Persistent Volume Claims (PVC)

PVCs are user requests for storage:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-app-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: local-storage
```

### Storage Classes

Storage Classes enable dynamic provisioning:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/no-provisioner
parameters:
  type: ssd
  zone: us-west-1a
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```

## 🧪 Hands-on Labs

### Lab 1: Working with EmptyDir Volumes

1. **Create a Pod with EmptyDir volume**:

```bash
# Create the Pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: shared-storage-pod
spec:
  containers:
  - name: writer
    image: busybox
    command: ['sh', '-c', 'while true; do echo "$(date): Writer data" >> /shared/data.txt; sleep 10; done']
    volumeMounts:
    - name: shared-vol
      mountPath: /shared
  - name: reader
    image: busybox
    command: ['sh', '-c', 'while true; do if [ -f /shared/data.txt ]; then tail /shared/data.txt; fi; sleep 15; done']
    volumeMounts:
    - name: shared-vol
      mountPath: /shared
  volumes:
  - name: shared-vol
    emptyDir: {}
EOF
```

2. **Monitor the shared data**:

```bash
# Check Pod status
kubectl get pods shared-storage-pod

# Check logs from both containers
kubectl logs shared-storage-pod -c writer
kubectl logs shared-storage-pod -c reader

# Execute into the Pod to see shared files
kubectl exec -it shared-storage-pod -c reader -- ls -la /shared
kubectl exec -it shared-storage-pod -c reader -- cat /shared/data.txt
```

3. **Clean up**:

```bash
kubectl delete pod shared-storage-pod
```

### Lab 2: Persistent Volumes and Claims

1. **Create directories on your node** (if using local storage):

```bash
# On each worker node, create storage directories
sudo mkdir -p /mnt/k8s-storage/pv1
sudo mkdir -p /mnt/k8s-storage/pv2
sudo chmod 777 /mnt/k8s-storage/pv*
```

2. **Create Persistent Volumes**:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-1
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /mnt/k8s-storage/pv1
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-2
spec:
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /mnt/k8s-storage/pv2
EOF
```

3. **View available PVs**:

```bash
kubectl get pv
kubectl describe pv pv-1
```

4. **Create Persistent Volume Claims**:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-small
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
  storageClassName: manual
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-large
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1500Mi
  storageClassName: manual
EOF
```

5. **Check PVC binding**:

```bash
kubectl get pvc
kubectl get pv
```

6. **Use PVC in a Pod**:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: pvc-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: persistent-storage
      mountPath: /usr/share/nginx/html
  volumes:
  - name: persistent-storage
    persistentVolumeClaim:
      claimName: pvc-small
EOF
```

7. **Test persistence**:

```bash
# Write data to the persistent volume
kubectl exec -it pvc-pod -- bash -c "echo '<h1>Persistent Data</h1>' > /usr/share/nginx/html/index.html"

# Delete and recreate the Pod
kubectl delete pod pvc-pod

# Create a new Pod using the same PVC
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: pvc-pod-2
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: persistent-storage
      mountPath: /usr/share/nginx/html
  volumes:
  - name: persistent-storage
    persistentVolumeClaim:
      claimName: pvc-small
EOF

# Check if data persisted
kubectl exec -it pvc-pod-2 -- cat /usr/share/nginx/html/index.html
```

### Lab 3: StatefulSets with Persistent Storage

1. **Create a StorageClass** (if not using hostPath):

```bash
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF
```

2. **Create additional PVs for StatefulSet**:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-stateful-0
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  hostPath:
    path: /mnt/k8s-storage/stateful-0
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-stateful-1
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  hostPath:
    path: /mnt/k8s-storage/stateful-1
EOF
```

3. **Create directories for StatefulSet PVs**:

```bash
sudo mkdir -p /mnt/k8s-storage/stateful-0
sudo mkdir -p /mnt/k8s-storage/stateful-1
sudo chmod 777 /mnt/k8s-storage/stateful-*
```

4. **Create a StatefulSet with persistent storage**:

```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web-stateful
spec:
  serviceName: "web-service"
  replicas: 2
  selector:
    matchLabels:
      app: web-stateful
  template:
    metadata:
      labels:
        app: web-stateful
    spec:
      containers:
      - name: web
        image: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        - name: web-storage
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: web-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: local-storage
      resources:
        requests:
          storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  clusterIP: None
  selector:
    app: web-stateful
  ports:
  - port: 80
EOF
```

5. **Test StatefulSet storage**:

```bash
# Check StatefulSet and PVCs
kubectl get statefulset
kubectl get pvc

# Write unique data to each Pod
kubectl exec web-stateful-0 -- bash -c "echo '<h1>Pod 0 Data</h1>' > /usr/share/nginx/html/index.html"
kubectl exec web-stateful-1 -- bash -c "echo '<h1>Pod 1 Data</h1>' > /usr/share/nginx/html/index.html"

# Delete StatefulSet but keep PVCs
kubectl delete statefulset web-stateful

# Recreate StatefulSet
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web-stateful
spec:
  serviceName: "web-service"
  replicas: 2
  selector:
    matchLabels:
      app: web-stateful
  template:
    metadata:
      labels:
        app: web-stateful
    spec:
      containers:
      - name: web
        image: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        - name: web-storage
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: web-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: local-storage
      resources:
        requests:
          storage: 1Gi
EOF

# Verify data persistence
kubectl exec web-stateful-0 -- cat /usr/share/nginx/html/index.html
kubectl exec web-stateful-1 -- cat /usr/share/nginx/html/index.html
```

## 💡 Best Practices

### 1. Storage Planning
- Choose appropriate volume types for your use case
- Plan for data backup and disaster recovery
- Consider performance requirements (IOPS, bandwidth)
- Implement proper capacity planning

### 2. Security
- Use appropriate access modes (ReadWriteOnce, ReadOnlyMany, ReadWriteMany)
- Implement proper RBAC for storage resources
- Encrypt data at rest when required
- Secure backup locations

### 3. Performance Optimization
- Use local storage for high-performance applications
- Implement proper resource requests and limits
- Monitor storage performance and usage
- Use appropriate storage classes for different workloads

### 4. Lifecycle Management
- Implement proper reclaim policies
- Plan for PV expansion when needed
- Monitor storage usage and cleanup unused PVCs
- Implement automated backup strategies

## 🔧 Troubleshooting Storage Issues

### Common Problems and Solutions

#### 1. PVC Stuck in Pending State

**Problem**: PVC remains in Pending state
**Diagnosis**:
```bash
kubectl describe pvc <pvc-name>
kubectl get pv
kubectl get storageclass
```

**Solutions**:
- Check if matching PV exists
- Verify StorageClass configuration
- Check node selectors and affinity rules
- Ensure provisioner is working

#### 2. Pod Cannot Mount Volume

**Problem**: Pod fails to start due to volume mount issues
**Diagnosis**:
```bash
kubectl describe pod <pod-name>
kubectl get events --sort-by=.metadata.creationTimestamp
```

**Solutions**:
- Verify PVC exists and is bound
- Check volume mount paths and permissions
- Ensure storage class supports required access mode
- Check node capacity and resources

#### 3. Data Not Persisting

**Problem**: Data is lost when Pod restarts
**Diagnosis**:
```bash
kubectl describe pv <pv-name>
kubectl describe pvc <pvc-name>
```

**Solutions**:
- Ensure using PVC instead of emptyDir
- Check reclaim policy settings
- Verify volume mount paths
- Check if using correct storage class

### Storage Monitoring Commands

```bash
# Check storage usage
kubectl top nodes
kubectl describe nodes

# Monitor PV and PVC status
kubectl get pv,pvc --all-namespaces
kubectl describe pv <pv-name>

# Check storage events
kubectl get events --field-selector type=Warning
```

## 📝 Assessment Questions

1. **Multiple Choice**: What happens to data in an emptyDir volume when a Pod is deleted?
   - a) Data is preserved on the node
   - b) Data is moved to persistent storage
   - c) Data is lost permanently
   - d) Data is backed up automatically

2. **Multiple Choice**: Which access mode allows multiple Pods to read and write simultaneously?
   - a) ReadWriteOnce
   - b) ReadOnlyMany
   - c) ReadWriteMany
   - d) WriteOnlyMany

3. **Practical**: Create a StatefulSet with 3 replicas that uses persistent storage and demonstrate that each Pod maintains its own data even after deletion and recreation.

4. **Scenario**: You have a database application that requires 100GB of storage with high IOPS. Design a storage solution including PV, PVC, and StorageClass configurations.

## 🎯 Module Summary

You have learned:
- ✅ Different types of Kubernetes volumes and their use cases
- ✅ How to create and manage Persistent Volumes and Claims
- ✅ Storage Classes and dynamic provisioning
- ✅ StatefulSets with persistent storage
- ✅ Storage best practices and troubleshooting
- ✅ Performance and security considerations for storage

## 🔄 Next Steps

Ready for the next module? Continue to:
**[Module 6: Networking](../06-networking/README.md)**

## 📚 Additional Resources

- [Kubernetes Storage Documentation](https://kubernetes.io/docs/concepts/storage/)
- [Persistent Volumes Guide](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Storage Classes Guide](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [StatefulSets Tutorial](https://kubernetes.io/docs/tutorials/stateful-application/)

---

**💡 Pro Tip**: Always test your storage configuration in a development environment before deploying to production, and implement proper backup and disaster recovery strategies!
