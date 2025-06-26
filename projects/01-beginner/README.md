# Beginner Level Projects

🟢 **Level 1: Foundation Projects for Kubernetes Beginners**

These projects are designed for those new to Kubernetes who have completed the basic modules (00-04). Each project introduces core concepts progressively while building real applications.

## 📋 Project List

### [01-simple-web-app](01-simple-web-app/)
**Time Estimate:** 2-3 hours  
**Difficulty:** ⭐☆☆☆☆

Deploy a simple web application to learn basic Kubernetes objects.

**Learning Objectives:**
- Understand Pods, Services, and Deployments
- Learn basic kubectl commands
- Configure container networking
- Expose applications externally

**Technologies Used:**
- NGINX web server
- Basic HTML/CSS
- Kubernetes core objects
- kubectl CLI

### [02-database-app](02-database-app/)
**Time Estimate:** 4-5 hours  
**Difficulty:** ⭐⭐☆☆☆

Build a web application with persistent database storage.

**Learning Objectives:**
- Work with Persistent Volumes and Claims
- Understand StatefulSets
- Manage environment variables and secrets
- Configure database connectivity

**Technologies Used:**
- WordPress or simple CRUD app
- MySQL/PostgreSQL database
- Persistent storage
- ConfigMaps and Secrets

### [03-multi-container-app](03-multi-container-app/)
**Time Estimate:** 5-6 hours  
**Difficulty:** ⭐⭐⭐☆☆

Create a complete application with frontend, backend, and database tiers.

**Learning Objectives:**
- Design multi-tier architectures
- Configure service discovery
- Manage inter-service communication
- Implement basic load balancing

**Technologies Used:**
- React/Angular frontend
- Node.js/Python backend API
- PostgreSQL/MongoDB database
- Redis cache
- Multiple services and deployments

## 🎯 Learning Path

### **Prerequisites**
Before starting these projects, ensure you have:
- Completed modules 00-04 from the main course
- Working Kubernetes cluster (single-node is fine)
- kubectl configured and working
- Basic understanding of containers

### **Recommended Order**
1. **Start with Project 01** - Get comfortable with basic deployments
2. **Move to Project 02** - Add persistence and data management
3. **Complete Project 03** - Build a complete application stack

### **Time Investment**
- **Total time:** 11-14 hours
- **Spread over:** 1-2 weeks
- **Daily commitment:** 1-2 hours

## 🛠️ Setup Requirements

### **Cluster Requirements**
- **Nodes:** 1 node minimum (master can be worker)
- **CPU:** 2 cores minimum
- **Memory:** 4GB minimum
- **Storage:** 20GB available

### **Tools Required**
- kubectl (latest version)
- Docker (for building custom images)
- Git (for cloning repositories)
- Text editor (VS Code recommended)

### **Optional Tools**
- k9s (terminal UI for Kubernetes)
- kubectx/kubens (context switching)
- Helm (package manager)

## 📚 Learning Resources

### **Documentation**
Each project includes:
- Detailed README with step-by-step instructions
- Architecture diagrams
- Troubleshooting guides
- Additional learning resources

### **Validation Scripts**
- Automated testing to verify deployment
- Health check scripts
- Performance validation
- Security basic checks

### **Common Commands Reference**
```bash
# Basic deployment commands
kubectl create deployment myapp --image=nginx
kubectl expose deployment myapp --port=80 --type=LoadBalancer

# Debugging commands
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- /bin/bash

# Resource management
kubectl apply -f manifest.yaml
kubectl delete -f manifest.yaml
kubectl get all -n <namespace>
```

## 🎮 Challenges and Extensions

Each project includes optional challenges:

### **Basic Challenges**
- Customize application configurations
- Add health checks and probes
- Implement resource limits
- Add basic monitoring

### **Intermediate Extensions**
- Set up horizontal pod autoscaling
- Add ingress for external access
- Implement rolling updates
- Add persistent logging

### **Advanced Modifications**
- Convert to Helm charts
- Add CI/CD pipeline
- Implement backup strategies
- Add security policies

## 🔍 Assessment Criteria

For each project, evaluate your understanding:

### **Functional Requirements**
- [ ] Application deploys successfully
- [ ] All services are accessible
- [ ] Data persistence works correctly
- [ ] Scaling functions as expected

### **Technical Understanding**
- [ ] Can explain each Kubernetes object used
- [ ] Understands networking between components
- [ ] Can troubleshoot common issues
- [ ] Follows Kubernetes best practices

### **Documentation**
- [ ] Code is well-commented
- [ ] README includes setup instructions
- [ ] Architecture is documented
- [ ] Known issues are listed

## 🚨 Common Issues and Solutions

### **Pod Startup Issues**
```bash
# Check pod status
kubectl get pods

# Describe pod for events
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>
```

### **Service Connectivity Issues**
```bash
# Verify service exists
kubectl get services

# Check endpoints
kubectl get endpoints <service-name>

# Test connectivity from within cluster
kubectl run debug --image=busybox --rm -it -- wget -qO- <service-name>
```

### **Storage Issues**
```bash
# Check PVC status
kubectl get pvc

# Describe PVC for events
kubectl describe pvc <pvc-name>

# Check available storage classes
kubectl get storageclass
```

## 📈 Progress Tracking

### **Project Completion Checklist**
- [ ] **Project 01: Simple Web App**
  - [ ] Deploy NGINX pod
  - [ ] Create service for external access
  - [ ] Configure basic HTML content
  - [ ] Access application from browser
  - [ ] Scale deployment to multiple replicas

- [ ] **Project 02: Database App**
  - [ ] Deploy database with persistent storage
  - [ ] Create application deployment
  - [ ] Configure database connection
  - [ ] Test data persistence
  - [ ] Implement backup strategy

- [ ] **Project 03: Multi-Container App**
  - [ ] Deploy frontend application
  - [ ] Deploy backend API
  - [ ] Deploy database layer
  - [ ] Configure service discovery
  - [ ] Test end-to-end functionality

### **Skills Acquired**
After completing these projects, you should be able to:
- Deploy applications to Kubernetes confidently
- Configure basic networking and storage
- Troubleshoot common deployment issues
- Scale applications horizontally
- Manage configuration and secrets
- Design simple multi-tier architectures

## 🚀 Next Steps

After completing beginner projects:

1. **Review and Refine**
   - Revisit projects and optimize configurations
   - Document lessons learned
   - Share your solutions

2. **Explore Intermediate Topics**
   - Move to [Intermediate Projects](../02-intermediate/)
   - Study advanced networking concepts
   - Learn about monitoring and observability

3. **Practice Troubleshooting**
   - Break things intentionally to learn debugging
   - Use the troubleshooting scripts provided
   - Practice with different failure scenarios

4. **Community Engagement**
   - Share your project outcomes
   - Help other beginners
   - Join Kubernetes community discussions

---

**Ready to start your first project? Begin with [Simple Web App](01-simple-web-app/)!**

*These projects are part of the Comprehensive Kubernetes Learning Project. For more information, see the main [README.md](../../README.md).*
