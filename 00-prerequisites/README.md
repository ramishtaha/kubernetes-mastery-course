# Module 00: Prerequisites and Foundation

Welcome to your Kubernetes learning journey! This module ensures you have all the foundational knowledge needed to succeed with Kubernetes.

## 📚 Learning Objectives

By the end of this module, you will:
- Understand containerization concepts and Docker basics
- Be proficient with Linux command line operations
- Master YAML syntax for configuration files
- Grasp fundamental networking concepts
- Have a prepared learning environment

## 📋 Module Outline

1. [Understanding Containerization](#1-understanding-containerization)
2. [Linux Command Line Mastery](#2-linux-command-line-mastery)
3. [YAML Fundamentals](#3-yaml-fundamentals)
4. [Networking Basics](#4-networking-basics)
5. [Development Environment Setup](#5-development-environment-setup)
6. [Hands-on Labs](#6-hands-on-labs)
7. [Assessment](#7-assessment)

---

## 1. Understanding Containerization

### What are Containers?

Containers are lightweight, portable, and self-sufficient software packages that include:
- Application code
- Runtime environment
- System libraries
- Dependencies
- Configuration files

### Key Container Benefits

1. **Consistency**: "Works on my machine" → "Works everywhere"
2. **Isolation**: Applications run independently
3. **Portability**: Run anywhere containers are supported
4. **Efficiency**: Share host OS kernel
5. **Scalability**: Quick startup and resource efficiency

### Docker Fundamentals

Docker is the most popular containerization platform:

```bash
# Basic Docker commands you should know
docker --version                    # Check Docker version
docker pull nginx                   # Download an image
docker images                       # List local images
docker run -d -p 80:80 nginx       # Run container in background
docker ps                          # List running containers
docker ps -a                       # List all containers
docker stop <container-id>         # Stop a container
docker rm <container-id>           # Remove a container
docker rmi <image-id>              # Remove an image
```

### Container vs Virtual Machine

| Aspect | Containers | Virtual Machines |
|--------|------------|-----------------|
| Resource Usage | Lightweight | Heavy |
| Startup Time | Seconds | Minutes |
| Isolation | Process-level | Hardware-level |
| OS | Share host kernel | Full OS per VM |
| Use Case | Microservices | Legacy apps |

---

## 2. Linux Command Line Mastery

### Essential Commands

#### File and Directory Operations
```bash
# Navigation
pwd                    # Print working directory
ls -la                 # List files with details
cd /path/to/directory  # Change directory
mkdir directory_name   # Create directory
rmdir directory_name   # Remove empty directory
rm -rf directory_name  # Remove directory and contents

# File operations
touch filename         # Create empty file
cp source destination  # Copy file
mv source destination  # Move/rename file
rm filename           # Delete file
find /path -name "*.yaml"  # Find files by pattern
```

#### Text Processing
```bash
# View file contents
cat filename           # Display entire file
less filename          # Page through file
head -n 10 filename    # First 10 lines
tail -n 10 filename    # Last 10 lines
tail -f filename       # Follow file changes

# Search and filter
grep "pattern" filename        # Search in file
grep -r "pattern" directory/   # Recursive search
awk '{print $1}' filename      # Print first column
sed 's/old/new/g' filename     # Replace text
```

#### Process Management
```bash
# Process operations
ps aux                 # List all processes
top                    # Real-time process monitor
htop                   # Enhanced process monitor
kill PID               # Terminate process
killall process_name   # Kill by name
nohup command &        # Run in background
```

#### Network Commands
```bash
# Network utilities
ping hostname          # Test connectivity
curl -I http://site    # HTTP request
wget http://file       # Download file
netstat -tulpn         # Show listening ports
ss -tulpn              # Modern netstat alternative
```

#### System Information
```bash
# System details
uname -a               # System information
df -h                  # Disk usage
free -h                # Memory usage
lscpu                  # CPU information
lsblk                  # Block devices
```

### File Permissions

Understanding Linux permissions is crucial:

```bash
# Permission format: drwxrwxrwx
# d = directory, - = file
# rwx = read, write, execute
# Three groups: owner, group, others

chmod 755 filename     # rwxr-xr-x
chmod +x script.sh     # Add execute permission
chown user:group file  # Change ownership
```

### Environment Variables
```bash
# Environment variables
export VARIABLE=value  # Set variable
echo $VARIABLE         # Display variable
env                    # List all variables
unset VARIABLE         # Remove variable

# Common variables
echo $HOME             # Home directory
echo $PATH             # Executable paths
echo $USER             # Current user
```

---

## 3. YAML Fundamentals

YAML (YAML Ain't Markup Language) is the primary configuration format for Kubernetes.

### YAML Syntax Rules

1. **Indentation**: Use spaces (2 or 4), never tabs
2. **Case sensitive**: `Name` ≠ `name`
3. **Data types**: Strings, numbers, booleans, arrays, objects

### Basic YAML Structure

```yaml
# Comments start with hash
---  # Document separator (optional)

# Key-value pairs
name: "John Doe"
age: 30
active: true

# Nested objects
address:
  street: "123 Main St"
  city: "New York"
  zipcode: 10001

# Arrays/Lists
hobbies:
  - reading
  - swimming
  - coding

# Alternative array syntax
skills: ["python", "javascript", "kubernetes"]

# Multi-line strings
description: |
  This is a multi-line string
  that preserves line breaks
  and formatting.

biography: >
  This is a folded string
  that removes line breaks
  and creates a single line.

# Boolean values
enabled: true
disabled: false
also_true: yes
also_false: no
```

### Common YAML Mistakes

```yaml
# ❌ Wrong - using tabs
name:	"value"

# ✅ Correct - using spaces
name: "value"

# ❌ Wrong - inconsistent indentation
items:
  - name: "item1"
    value: 1
   - name: "item2"  # Wrong indentation
     value: 2

# ✅ Correct - consistent indentation
items:
  - name: "item1"
    value: 1
  - name: "item2"
    value: 2
```

### YAML Validation Tools

```bash
# Install yamllint
pip install yamllint

# Validate YAML file
yamllint config.yaml

# Online validators
# - http://www.yamllint.com/
# - https://yamlvalidator.com/
```

---

## 4. Networking Basics

### IP Addressing

Understanding IP addresses and subnets:

```
IPv4 Format: 192.168.1.100
- Network portion: 192.168.1
- Host portion: 100

Subnet Mask: 255.255.255.0 (/24)
- Defines network boundary
- /24 means 24 bits for network, 8 for hosts
```

### Common Network Ranges

```
Private IP Ranges (RFC 1918):
- 10.0.0.0/8        (10.0.0.0 - 10.255.255.255)
- 172.16.0.0/12     (172.16.0.0 - 172.31.255.255)
- 192.168.0.0/16    (192.168.0.0 - 192.168.255.255)

Localhost:
- 127.0.0.1         (loopback address)
- ::1               (IPv6 loopback)
```

### Ports and Protocols

```
Well-known Ports:
- 22   SSH
- 53   DNS
- 80   HTTP
- 443  HTTPS
- 3306 MySQL
- 5432 PostgreSQL
- 6379 Redis
- 8080 Alternative HTTP

Kubernetes Ports:
- 6443 API Server
- 2379-2380 etcd
- 10250 kubelet
- 10251 kube-scheduler
- 10252 kube-controller-manager
```

### DNS Concepts

```
DNS Resolution Process:
1. Check local hosts file (/etc/hosts)
2. Query local DNS cache
3. Query configured DNS servers
4. Recursive DNS lookup

DNS Record Types:
- A     IPv4 address
- AAAA  IPv6 address
- CNAME Canonical name (alias)
- MX    Mail exchange
- TXT   Text records
- SRV   Service records
```

### Load Balancing

Types of load balancing:

1. **Layer 4 (Transport)**: Based on IP and port
2. **Layer 7 (Application)**: Based on content (HTTP headers, URLs)

Load balancing algorithms:
- Round Robin
- Least Connections
- IP Hash
- Weighted Round Robin

---

## 5. Development Environment Setup

### Required Software

#### On Ubuntu Server
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y curl wget git vim nano htop tree jq

# Install Docker (we'll do this in detail in Module 01)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install kubectl (Kubernetes CLI)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

#### Development Tools
```bash
# Install VS Code (optional but recommended)
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt update
sudo apt install code

# Useful VS Code extensions for Kubernetes:
# - Kubernetes
# - YAML
# - Docker
# - GitLens
```

### System Requirements

Minimum requirements for learning environment:
- **CPU**: 2 cores
- **RAM**: 4GB (8GB recommended)
- **Storage**: 20GB free space
- **Network**: Internet connection
- **OS**: Ubuntu 20.04 LTS or newer

For production clusters:
- **Master Node**: 2 CPU, 2GB RAM
- **Worker Node**: 1 CPU, 1GB RAM (minimum)

---

## 6. Hands-on Labs

### Lab 1: Docker Basics

**Objective**: Get comfortable with Docker commands

```bash
# 1. Pull and run a simple web server
docker run -d -p 8080:80 --name my-nginx nginx

# 2. Check if it's running
curl http://localhost:8080

# 3. View logs
docker logs my-nginx

# 4. Execute command in container
docker exec -it my-nginx bash
# Inside container:
ls /usr/share/nginx/html
exit

# 5. Stop and remove
docker stop my-nginx
docker rm my-nginx
```

### Lab 2: YAML Practice

Create a file called `app-config.yaml`:

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: default
data:
  database_url: "postgresql://user:pass@db:5432/myapp"
  redis_url: "redis://redis:6379"
  log_level: "info"
  features: |
    feature1=enabled
    feature2=disabled
    feature3=beta

---
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: default
type: Opaque
data:
  api_key: YWJjZGVmZ2hpams=  # base64 encoded
  db_password: c2VjcmV0UGFzc3dvcmQ=  # base64 encoded
```

Validate the YAML:
```bash
# Install yq for YAML processing
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq

# Validate YAML syntax
yq eval . app-config.yaml
```

### Lab 3: Linux Skills Test

Create a script called `system-info.sh`:

```bash
#!/bin/bash

echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"')"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo ""

echo "=== Hardware Information ==="
echo "CPU: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
echo "Memory: $(free -h | grep Mem | awk '{print $2}')"
echo "Disk: $(df -h / | tail -1 | awk '{print $2}')"
echo ""

echo "=== Network Information ==="
echo "IP Address: $(ip route get 8.8.8.8 | head -1 | awk '{print $7}')"
echo "Gateway: $(ip route | grep default | awk '{print $3}')"
echo ""

echo "=== Docker Status ==="
if command -v docker &> /dev/null; then
    echo "Docker Version: $(docker --version)"
    echo "Docker Status: $(systemctl is-active docker)"
else
    echo "Docker: Not installed"
fi
```

Make it executable and run:
```bash
chmod +x system-info.sh
./system-info.sh
```

### Lab 4: Network Testing

Test network connectivity:

```bash
# Test DNS resolution
nslookup kubernetes.io
dig kubernetes.io

# Test HTTP connectivity
curl -I https://kubernetes.io

# Check listening ports
sudo netstat -tulpn | grep LISTEN

# Test port connectivity
nc -zv google.com 443
```

---

## 7. Assessment

### Knowledge Check Questions

1. **Containers vs VMs**: What are the main differences between containers and virtual machines?

2. **Docker Commands**: How would you run a PostgreSQL database in a container with persistent data?

3. **YAML Syntax**: What's wrong with this YAML?
   ```yaml
   items:
     - name: item1
   	value: 100
     - name: item2
       value: 200
   ```

4. **Linux Commands**: How would you find all YAML files in a directory tree and count the total lines?

5. **Networking**: Explain the difference between 192.168.1.0/24 and 192.168.1.0/16 networks.

### Practical Exercises

#### Exercise 1: Container Deployment
Deploy a WordPress application using Docker containers:
- MySQL database container
- WordPress application container
- Configure environment variables
- Set up persistent volumes
- Verify the application works

#### Exercise 2: Configuration Management
Create a complex YAML configuration file for a web application including:
- Database connection settings
- Feature flags
- Logging configuration
- Security settings
- Multi-environment support

#### Exercise 3: System Administration
Write a bash script that:
- Checks system prerequisites for Kubernetes
- Installs required packages
- Configures system settings
- Validates the installation
- Generates a system report

### Assessment Rubric

| Skill Area | Beginner | Intermediate | Advanced |
|------------|----------|--------------|----------|
| **Containerization** | Understands concepts | Can run containers | Can create images |
| **Linux CLI** | Basic commands | Complex operations | Scripting and automation |
| **YAML** | Simple structures | Complex configurations | Best practices |
| **Networking** | Basic concepts | Troubleshooting | Advanced routing |

### Minimum Passing Criteria

To proceed to Module 01, you must:
- [ ] Score 80% or higher on knowledge questions
- [ ] Complete all practical exercises successfully
- [ ] Demonstrate Linux command proficiency
- [ ] Create valid YAML configurations
- [ ] Deploy and manage Docker containers

---

## 📚 Additional Resources

### Books
- "Docker: Up & Running" by Karl Matthias
- "The Linux Command Line" by William Shotts
- "Learning YAML" by Tanya Janca

### Online Documentation
- [Docker Documentation](https://docs.docker.com/)
- [Ubuntu Server Guide](https://ubuntu.com/server/docs)
- [YAML Specification](https://yaml.org/spec/)

### Practice Platforms
- [Play with Docker](https://labs.play-with-docker.com/)
- [Katacoda Docker Scenarios](https://www.katacoda.com/courses/docker)
- [Linux Journey](https://linuxjourney.com/)

---

## ✅ Module Completion Checklist

- [ ] Read and understand all theory sections
- [ ] Complete all hands-on labs
- [ ] Pass the knowledge assessment
- [ ] Complete practical exercises
- [ ] Set up development environment
- [ ] Ready to proceed to Module 01

---

**Next Module**: [01-installation](../01-installation/README.md) - Kubernetes Installation and Setup

**Estimated Time**: 3-5 days  
**Difficulty**: Beginner  
**Prerequisites**: None
