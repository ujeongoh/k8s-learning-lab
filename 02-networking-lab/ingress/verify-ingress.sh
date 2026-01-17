#!/bin/bash

# ==============================================================================
# Phase 2-3: Ingress Routing Test
# Deploys an Ingress rule and verifies access using a fake domain header.
# ==============================================================================

MANIFEST="02-networking-lab/ingress/ingress-demo.yaml"
DOMAIN="devops.local"
INGRESS_PORT="30080"

echo "🚀 Starting Ingress Routing Test..."

# 1. Apply Resources
echo "📦 Deploying Web App & Ingress Rule..."
kubectl apply -f $MANIFEST

# 2. Wait for Ingress to get an IP (wait for Address allocation)
echo "⏳ Waiting for Ingress to be ready..."
kubectl wait --for=condition=Available deployment/demo-web --timeout=60s > /dev/null 2>&1
sleep 5 # time for Ingress controller to reflect the rules

# 3. Get Worker Node IP
# we need to access the Ingress Controller's port 30080.
# any worker node's IP is fine.
NODE_IP=$(multipass info k8s-worker1 | grep IPv4 | awk '{print $2}')

echo "--------------------------------------------------"
echo "ℹ️  Test Connection Info:"
echo "   - Target Domain: $DOMAIN"
echo "   - Node IP:       $NODE_IP"
echo "   - Entry Port:    $INGRESS_PORT"
echo "   - Full URL:      http://$NODE_IP:$INGRESS_PORT"
echo "--------------------------------------------------"

# 4. Verification (The Trick)
echo "📡 Sending Request with Host Header: '$DOMAIN'..."

# -H "Host: devops.local" : this is the key part!
# we're connecting via IP, but telling it "I'm looking for devops.local"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: $DOMAIN" http://$NODE_IP:$INGRESS_PORT)

if [ "$HTTP_CODE" -eq 200 ]; then
    echo "✅ Success! Ingress routed the request correctly."
    echo "   (You saw the 'Welcome to nginx!' page implicitly)"
else
    echo "❌ Failed. HTTP Code: $HTTP_CODE"
    echo "   Is the Ingress Controller running? Check 'kubectl get pods -n ingress-nginx'"
fi

# 5. Cleanup Prompt
echo "--------------------------------------------------"
read -p "🗑️  Clean up test resources? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl delete -f $MANIFEST
    echo "✅ Cleanup done."
fi