#!/bin/bash

# ==============================================================================
# Worker Node Join Script
# Automatically fetches the join command from the Master and executes it on Workers.
# ==============================================================================

MASTER_NODE="k8s-master"
WORKER_NODES=("k8s-worker1" "k8s-worker2")

echo "🚀 Starting Worker Node Join Process..."

# 1. Fetch the Join Command from Master
# We ask the master to generate a fresh join command.
# 'tr -d' removes any potential carriage return characters that might break the command.
echo "🔑 Fetching join token from $MASTER_NODE..."
JOIN_COMMAND=$(multipass exec $MASTER_NODE -- kubeadm token create --print-join-command | tr -d '\r')

if [ -z "$JOIN_COMMAND" ]; then
    echo "❌ Error: Failed to retrieve join command."
    exit 1
fi

echo "   -> Command received: $JOIN_COMMAND"

# 2. Execute Join Command on Each Worker
for WORKER in "${WORKER_NODES[@]}"; do
    echo "--------------------------------------------------"
    echo "🔗 Joining $WORKER to the cluster..."
    
    # Run the join command with sudo privileges inside the worker node
    multipass exec $WORKER -- sudo $JOIN_COMMAND
    
    if [ $? -eq 0 ]; then
        echo "✅ $WORKER joined successfully!"
    else
        echo "❌ $WORKER failed to join."
    fi
done

echo "--------------------------------------------------"
echo "🎉 All workers processed!"