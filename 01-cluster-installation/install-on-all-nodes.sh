#!/bin/bash

# Configuration
NODES=("k8s-master" "k8s-worker1" "k8s-worker2")
SCRIPT_PATH="01-cluster-installation/common-setup.sh"
REMOTE_PATH="/home/ubuntu/common-setup.sh"

# Check if script exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "Error: $SCRIPT_PATH not found."
    exit 1
fi

echo "🚀 Starting installation on all nodes..."

for NODE in "${NODES[@]}"; do
    echo "--------------------------------------------------"
    echo "📦 Processing Node: $NODE"
    
    # 1. Transfer the script to the VM
    echo "   -> Transferring setup script..."
    multipass transfer $SCRIPT_PATH $NODE:$REMOTE_PATH
    
    # 2. Make executable and run inside the VM
    echo "   -> Executing setup script..."
    multipass exec $NODE -- bash -c "chmod +x $REMOTE_PATH && $REMOTE_PATH"
    
    echo "✅ Node $NODE is ready!"
done

echo "--------------------------------------------------"
echo "🎉 All nodes have been provisioned with Containerd and K8s binaries."