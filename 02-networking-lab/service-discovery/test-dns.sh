#!/bin/bash

# ==============================================================================
# Phase 2-2: Service Discovery & DNS Test
# Verifies if we can access pods using the Service Name (DNS).
# ==============================================================================

MANIFEST="02-networking-lab/service-discovery/dns-experiment.yaml"
CLIENT_POD="curl-dns-client"
SERVICE_NAME="my-nginx-service"

echo "🚀 Starting Service Discovery (DNS) Test..."

# 1. Apply Manifest
echo "📦 Deploying Deployment (3 replicas) + Service..."
kubectl apply -f $MANIFEST

# 2. Wait for Resources
echo "⏳ Waiting for client pod to be ready..."
kubectl wait --for=condition=Ready pod/$CLIENT_POD --timeout=60s

echo "⏳ Waiting for Nginx deployment to be available..."
kubectl wait --for=condition=Available deployment/nginx-deployment --timeout=60s

# 3. DNS Lookup Test
echo "--------------------------------------------------"
echo "🔍 Step 1: DNS Lookup Test"
echo "   Trying to resolve '$SERVICE_NAME'..."
# verify if the domain name resolves to an IP address by nslookup
RESULT=$(kubectl exec $CLIENT_POD -- nslookup $SERVICE_NAME 2>&1)
echo "$RESULT"

if echo "$RESULT" | grep -q "Address"; then
    echo "✅ DNS Resolution Successful! (Found IP address)"
else
    echo "❌ DNS Resolution Failed. Check CoreDNS."
    exit 1
fi

# 4. Connection Loop Test
echo "--------------------------------------------------"
echo "🔄 Step 2: Load Balancing Test"
echo "   Sending 5 requests to 'http://$SERVICE_NAME'..."

for i in {1..5}; do
    echo -n "   Request $i: "
    # connect with service name not the IP
    kubectl exec $CLIENT_POD -- curl -s -o /dev/null -w "%{http_code}" http://$SERVICE_NAME
    echo " (OK)"
done

echo "--------------------------------------------------"
echo "🎉 Test Completed! You can access services by NAME."

# 5. Cleanup Prompt
echo
read -p "🗑️  Do you want to clean up? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl delete -f $MANIFEST
    echo "✅ Cleanup done."
fi