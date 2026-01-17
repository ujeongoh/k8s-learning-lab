#!/bin/bash

# ==============================================================================
# CNI Installation Script (Calico Version)
# Installs Tigera Calico Operator and Custom Resources.
# Automatically adjusts CIDR to match our cluster (10.244.0.0/16).
# ==============================================================================

MASTER_NODE="k8s-master"
CALICO_VERSION="v3.27.0" # Stable version

echo "🚀 Installing CNI (Calico) on Cluster..."

# 1. Install Tigera Calico Operator
# The operator manages the lifecycle of Calico.
echo "   -> Deploying Tigera Operator..."
multipass exec $MASTER_NODE -- kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/$CALICO_VERSION/manifests/tigera-operator.yaml

# 2. Configure Calico (Custom Resources)
# We need to download the config, change CIDR from 192.168.0.0/16 to 10.244.0.0/16, and apply it.
echo "   -> Configuring Calico CIDR (10.244.0.0/16)..."

# Run a complex command inside the VM to handle file modification
multipass exec $MASTER_NODE -- bash -c "
    # Download the default custom-resources.yaml
    wget -q https://raw.githubusercontent.com/projectcalico/calico/$CALICO_VERSION/manifests/custom-resources.yaml -O calico-config.yaml
    
    # Use sed to replace the default CIDR with our POD_CIDR (10.244.0.0/16)
    sed -i 's/192.168.0.0\/16/10.244.0.0\/16/g' calico-config.yaml
    
    # Apply the modified configuration
    kubectl create -f calico-config.yaml
    
    # Clean up
    rm calico-config.yaml
"

echo "--------------------------------------------------"
echo "✅ Calico installation command sent."
echo "⏳ It may take 1-2 minutes for Calico pods to start."
echo "--------------------------------------------------"

# 3. Watch Status
echo "🔍 Checking Node Status (might take a moment to become Ready)..."
multipass exec $MASTER_NODE -- kubectl get nodes