#!/bin/bash

# ==============================================================================
# Wrapper Script: Initialize Control Plane
# This script runs on the Host (Mac) to trigger the setup on the Master Node.
# ==============================================================================

NODE_NAME="k8s-master"
SCRIPT_PATH="01-cluster-installation/control-plane-setup.sh"
REMOTE_PATH="/home/ubuntu/control-plane-setup.sh"

# 1. Check if the payload script exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ Error: File '$SCRIPT_PATH' not found."
    echo "   Please create the control-plane-setup.sh file first."
    exit 1
fi

echo "🚀 Starting Control Plane Initialization on $NODE_NAME..."

# 2. Transfer the script
echo "📦 Transferring setup script to $NODE_NAME..."
multipass transfer $SCRIPT_PATH $NODE_NAME:$REMOTE_PATH

# 3. Execute the script remotely
echo "⚙️  Executing script on $NODE_NAME..."
echo "--------------------------------------------------"
# We use 'multipass exec' to run the script inside the VM.
# The output (including the Join Token) will be streamed to your terminal.
multipass exec $NODE_NAME -- bash -c "chmod +x $REMOTE_PATH && $REMOTE_PATH"

echo "--------------------------------------------------"
echo "✅ Wrapper script finished."