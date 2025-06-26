# Scripts Directory

This directory contains comprehensive utility scripts for Kubernetes setup, management, troubleshooting, and automation.

## Available Scripts

### 1. install-all.sh
Complete Kubernetes installation script for Ubuntu Server.

**Purpose**: Automates the entire Kubernetes installation process
**Usage**: `./install-all.sh`
**Features**:
- System updates and prerequisites
- Docker installation and configuration
- Kubernetes components installation
- Cluster initialization
- CNI plugin installation
- Basic verification

### 2. quick-setup.sh
Quick development environment setup.

**Purpose**: Sets up a basic development environment quickly
**Usage**: `./quick-setup.sh`
**Features**:
- Creates sample namespaces
- Deploys basic workloads
- Sets up monitoring
- Configures ingress

### 3. reset-cluster.sh
Complete Kubernetes cluster reset utility.

**Purpose**: Safely reset and clean up Kubernetes cluster
**Usage**: `./reset-cluster.sh [OPTIONS]`
**Features**:
- Namespace cleanup
- Resource removal
- kubeadm reset
- Container runtime cleanup
- Network cleanup
- Safety confirmations

**Options**:
- `-h, --help`: Show help message
- `-y, --yes`: Skip confirmation prompts (use with caution!)

### 4. troubleshoot.sh
Comprehensive Kubernetes troubleshooting tool.

**Purpose**: Diagnose and troubleshoot common Kubernetes issues
**Usage**: `./troubleshoot.sh [COMMAND] [OPTIONS]`

**Commands**:
- `check`: Run full health check (default)
- `pods`: Troubleshoot pod issues
- `network`: Troubleshoot network issues
- `nodes`: Troubleshoot node issues
- `resources`: Troubleshoot resource issues
- `security`: Troubleshoot security issues
- `diagnostics`: Generate diagnostics package
- `interactive`: Run interactive troubleshooting

**Options**:
- `-h, --help`: Show help message
- `-v, --verbose`: Enable verbose output

### 5. manage-environments.sh
Environment management for development, staging, and production.

**Purpose**: Deploy and manage different environment configurations
**Usage**: `./manage-environments.sh <command> [options]`

**Commands**:
- `deploy <env>`: Deploy environment (development|staging|production|all)
- `switch <env>`: Switch to environment namespace
- `status [env]`: Show environment status (default: all)
- `cleanup <env>`: Clean up environment
- `compare`: Compare all environments
- `monitoring`: Deploy monitoring stack

## Usage Instructions

### Making Scripts Executable
```bash
chmod +x *.sh
```

### Basic Workflow
```bash
# 1. Install Kubernetes cluster
./install-all.sh

# 2. Set up development environment
./manage-environments.sh deploy development

# 3. Switch to development namespace
./manage-environments.sh switch development

# 4. Check cluster health
./troubleshoot.sh check

# 5. Deploy all environments
./manage-environments.sh deploy all
```

### Advanced Usage Examples
```bash
# Troubleshoot specific issues
./troubleshoot.sh pods                    # Check pod issues
./troubleshoot.sh network                 # Check network issues
./troubleshoot.sh diagnostics             # Generate diagnostics

# Environment management
./manage-environments.sh deploy staging   # Deploy staging
./manage-environments.sh status           # Check all environments
./manage-environments.sh compare          # Compare environments

# Reset cluster (with confirmation)
./reset-cluster.sh

# Quick reset (skip confirmations - dangerous!)
./reset-cluster.sh -y
```

### Interactive Mode
```bash
# Run interactive troubleshooting
./troubleshoot.sh interactive
```

## Script Prerequisites

### System Requirements
- Ubuntu Server 20.04 or later
- Sudo privileges (where required)
- Internet connectivity
- Minimum 2GB RAM, 2 CPU cores

### Required Tools
- `kubectl` (installed by install-all.sh)
- `helm` (for some advanced features)
- `docker` or `containerd` (installed by install-all.sh)

## Output and Logging

### Log Files
Scripts generate logs in various locations:
- `/tmp/kubernetes-install.log` (install-all.sh)
- `/tmp/quick-setup.log` (quick-setup.sh)
- `./k8s-diagnostics-*` (troubleshoot.sh diagnostics)

### Color-Coded Output
- 🟢 **Green**: Success messages and normal operation
- 🟡 **Yellow**: Warnings and important notices
- 🔴 **Red**: Errors and critical issues
- 🔵 **Blue**: Information and status updates
- 🟦 **Cyan**: Debug information (verbose mode)

## Troubleshooting Scripts

### Common Issues
1. **Permission denied**: Make scripts executable with `chmod +x *.sh`
2. **Network issues**: Check internet connectivity and cluster access
3. **Resource constraints**: Ensure sufficient system resources
4. **kubectl not found**: Run install-all.sh first or install kubectl manually

### Getting Help
```bash
# Show help for any script
./script-name.sh --help

# Run cluster health check
./troubleshoot.sh check

# Generate comprehensive diagnostics
./troubleshoot.sh diagnostics
```

## Safety and Best Practices

### Safety Notes
- **Test First**: Always test scripts in non-production environments
- **Review Code**: Review scripts before execution in production
- **Backup Data**: Backup important data before running destructive operations
- **Understand Impact**: Understand what each script does before running

### Best Practices
1. Run `troubleshoot.sh check` regularly to monitor cluster health
2. Use environment management scripts to maintain consistency
3. Generate diagnostics before making major changes
4. Keep scripts updated with your cluster configuration

### Security Considerations
- Scripts may require elevated privileges
- Some operations are destructive (reset-cluster.sh)
- Network access is required for downloads
- Container images are pulled from public registries

## Advanced Features

### Integration with CI/CD
Scripts can be integrated into CI/CD pipelines:
```bash
# Example pipeline step
./manage-environments.sh deploy staging
./troubleshoot.sh check
```

### Customization
Scripts are designed to be modular and customizable:
- Modify environment configurations in manage-environments.sh
- Add custom troubleshooting checks to troubleshoot.sh
- Extend installation process in install-all.sh

### Monitoring Integration
Scripts integrate with the monitoring stack:
- Deploy monitoring with: `./manage-environments.sh monitoring`
- Check monitoring status with: `./troubleshoot.sh check`
