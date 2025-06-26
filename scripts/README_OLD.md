#!/bin/bash

# Kubernetes Installation Scripts
# This directory contains automation scripts for setting up Kubernetes

echo "=== Kubernetes Installation Automation ==="
echo "Available scripts:"
echo ""
echo "1. prepare-system.sh         - System preparation and prerequisites"
echo "2. install-containerd.sh     - Container runtime installation"
echo "3. install-kubernetes.sh     - Kubernetes components installation"
echo "4. init-cluster.sh          - Cluster initialization"
echo "5. install-cni.sh           - Network plugin installation"
echo "6. install-all.sh           - Complete automated installation"
echo "7. reset-cluster.sh         - Reset cluster (for troubleshooting)"
echo ""
echo "Usage:"
echo "  chmod +x script-name.sh"
echo "  ./script-name.sh"
echo ""
echo "For complete installation:"
echo "  ./install-all.sh"
echo ""
echo "⚠️  Always review scripts before executing!"
echo "⚠️  Ensure you have sudo privileges!"
echo ""
