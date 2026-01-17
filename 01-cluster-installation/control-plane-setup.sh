#!/bin/bash

# ==============================================================================
# Kubernetes Control Plane Initialization Script
# Run this ONLY on the Master Node.
# ==============================================================================

# 1. Configuration
# MASTER_IP: The IP address of the 'k8s-master' node.
# (Verify this with 'multipass info k8s-master' on your host machine)
MASTER_IP="192.168.64.2"

# POD_CIDR: The IP range for Pods.
# We use 10.244.0.0/16 to match the default setting of Flannel/Calico CNI.
POD_CIDR="10.244.0.0/16"

# 2. Initialize Control Plane
echo "🚀 Initializing Kubernetes Control Plane..."
echo "   - Master IP: $MASTER_IP"
echo "   - Pod Network CIDR: $POD_CIDR"

# kubeadm init: Bootstraps the Kubernetes control plane.
# --pod-network-cidr: Specifies the range of IP addresses for the pod network.
# --apiserver-advertise-address: The IP address the API Server will advertise to listen on.
sudo kubeadm init \
  --pod-network-cidr=$POD_CIDR \
  --apiserver-advertise-address=$MASTER_IP

# 3. Configure kubectl for the 'ubuntu' user
# To use kubectl without 'sudo', we need to copy the admin config file to the user's home directory.
echo "🔑 Configuring kubectl for user 'ubuntu'..."

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "--------------------------------------------------"
echo "✅ Control Plane initialized successfully!"
echo "--------------------------------------------------"
echo "⚠️  [ACTION REQUIRED] Below is the command to join worker nodes."
echo "    Copy the 'kubeadm join ...' command from the output above!"
echo "--------------------------------------------------"