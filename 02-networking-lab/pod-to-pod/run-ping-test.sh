#!/bin/bash

# ==============================================================================
# Phase 2-1: Pod-to-Pod Communication Test
# Verifies if 'source-curl' pod can reach 'target-nginx' pod via its Pod IP.
# ==============================================================================

MANIFEST="02-networking-lab/pod-to-pod/pod-communication.yaml"
SERVER_POD="target-nginx"
CLIENT_POD="source-curl"

echo "🚀 Starting Pod-to-Pod Connectivity Test..."

# 1. Apply Manifest
echo "📦 Deploying test pods..."
kubectl apply -f $MANIFEST

# 2. Wait for Pods to be Ready
echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=Ready pod/$SERVER_POD --timeout=60s
kubectl wait --for=condition=Ready pod/$CLIENT_POD --timeout=60s

# 3. Get Target IP
# get pod IP of the server pod
TARGET_IP=$(kubectl get pod $SERVER_POD -o jsonpath='{.status.podIP}')
TARGET_NODE=$(kubectl get pod $SERVER_POD -o jsonpath='{.spec.nodeName}')
CLIENT_NODE=$(kubectl get pod $CLIENT_POD -o jsonpath='{.spec.nodeName}')

echo "--------------------------------------------------"
echo "ℹ️  Test Scenario:"
echo "   - Client: $CLIENT_POD (on $CLIENT_NODE)"
echo "   - Server: $SERVER_POD (on $TARGET_NODE)"
echo "   - Target IP: $TARGET_IP"
echo "--------------------------------------------------"

# 4. Perform Connectivity Test
echo "📡 Sending request from Client -> Server..."
# execute curl command inside the client pod
HTTP_CODE=$(kubectl exec $CLIENT_POD -- curl -s -o /dev/null -w "%{http_code}" http://$TARGET_IP)

if [ "$HTTP_CODE" -eq 200 ]; then
    echo "✅ Success! HTTP 200 OK received."
    echo "   (Conclusion: The Overlay Network (Calico) is working perfectly!)"
else
    echo "❌ Failed. HTTP Code: $HTTP_CODE"
fi

# 5. Cleanup Prompt
echo "--------------------------------------------------"
read -p "🗑️  Do you want to clean up these pods? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl delete -f $MANIFEST
    echo "✅ Cleanup done."
fi