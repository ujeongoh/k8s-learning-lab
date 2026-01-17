#!/bin/bash

# ==============================================================================
# Phase 2-3: Install Nginx Ingress Controller (with Fixed NodePorts)
# Installs the controller and patches Service to use ports 30080 & 30443.
# ==============================================================================

echo "🚀 Installing Nginx Ingress Controller..."

# 1. Apply Official Manifest (Bare-metal version)
# this creates the ingress-nginx namespace, controller deployment, and Service.
echo "📦 Applying Ingress Nginx Controller manifest..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/baremetal/deploy.yaml

echo "--------------------------------------------------"
echo "🔧 Patching Service NodePorts..."
echo "   - HTTP  -> 30080"
echo "   - HTTPS -> 30443"

# 2. Patch Service (Force specific NodePorts)
# force NodePort values to 30080 (HTTP) and 30443 (HTTPS)
kubectl patch svc ingress-nginx-controller -n ingress-nginx --type='json' -p='[
  {"op": "replace", "path": "/spec/ports/0/nodePort", "value": 30080},
  {"op": "replace", "path": "/spec/ports/1/nodePort", "value": 30443}
]'

echo "--------------------------------------------------"
echo "⏳ Waiting for Ingress Controller to be ready..."

# 3. Wait for the Controller Pod
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

echo "--------------------------------------------------"
echo "✅ Ingress Controller Installed & Configured!"

# 4. Verify Final Ports
HTTP_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[0].nodePort}')
HTTPS_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[1].nodePort}')

echo "ℹ️  Final Entry Ports:"
echo "   - HTTP:  $HTTP_PORT (Fixed)"
echo "   - HTTPS: $HTTPS_PORT (Fixed)"
echo "--------------------------------------------------"