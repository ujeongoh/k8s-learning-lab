#!/bin/bash

# ==============================================================================
# Phase 1 Final Verification Script: "Hello Nginx"
# Deploys Nginx, exposes it via NodePort, and curls it from the Mac Host.
# ==============================================================================

MASTER_NODE="k8s-master"
APP_NAME="nginx-verify"

echo "🚀 Starting End-to-End Cluster Verification..."

# 1. Clean up old resources (if any) to start fresh
echo "🧹 Cleaning up previous tests (if any)..."
multipass exec $MASTER_NODE -- kubectl delete service $APP_NAME --ignore-not-found=true > /dev/null 2>&1
multipass exec $MASTER_NODE -- kubectl delete deployment $APP_NAME --ignore-not-found=true > /dev/null 2>&1

# 2. Deploy Nginx
echo "📦 Deploying Nginx Pod..."
multipass exec $MASTER_NODE -- kubectl create deployment $APP_NAME --image=nginx

# 3. Wait for Pod to be READY
echo "⏳ Waiting for Nginx to start..."
multipass exec $MASTER_NODE -- kubectl rollout status deployment/$APP_NAME

# 4. Expose Service (NodePort)
echo "🔓 Exposing Service via NodePort..."
multipass exec $MASTER_NODE -- kubectl expose deployment $APP_NAME --port=80 --type=NodePort

# 5. Get Connection Info
# We need the Node's IP and the assigned NodePort number.
NODE_IP=$(multipass info $MASTER_NODE | grep IPv4 | awk '{print $2}')
NODE_PORT=$(multipass exec $MASTER_NODE -- kubectl get service $APP_NAME -o jsonpath='{.spec.ports[0].nodePort}')

echo "--------------------------------------------------"
echo "ℹ️  Connection Info:"
echo "   - Node IP:   $NODE_IP"
echo "   - NodePort:  $NODE_PORT"
echo "   - Full URL:  http://$NODE_IP:$NODE_PORT"
echo "--------------------------------------------------"

# 6. Test Connectivity from Mac Host
echo "📡 Testing connectivity from Mac..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$NODE_IP:$NODE_PORT)

if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "✅ Success! Received HTTP 200 OK from Nginx."
    echo "🎉 Verification PASSED! Your cluster is fully operational."
    
    # Optional: Show the Welcome title
    curl -s http://$NODE_IP:$NODE_PORT | grep "<title>"
else
    echo "❌ Failed! HTTP Status: $HTTP_STATUS"
    echo "   Check your Firewall/Network settings."
fi

# 7. Cleanup Prompt
echo "--------------------------------------------------"
read -p "🗑️  Do you want to clean up these test resources? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🧹 Removing test resources..."
    multipass exec $MASTER_NODE -- kubectl delete service $APP_NAME
    multipass exec $MASTER_NODE -- kubectl delete deployment $APP_NAME
    echo "✅ Cleanup done."
else
    echo "🛑 Resources kept. You can access Nginx at http://$NODE_IP:$NODE_PORT"
fi