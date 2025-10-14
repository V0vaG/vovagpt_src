#!/bin/bash

set -e

echo "🚀 Quick Fix - Building and Deploying VovaGPT with Ollama"
echo "=========================================================="
echo ""

# Step 1: Build image
echo "📦 Step 1: Building Docker image with Ollama..."
docker build -t vova0911/vovagpt:amd64_latest .

echo ""
echo "✅ Image built successfully!"
echo ""

# Step 2: Push to Docker Hub
echo "📤 Step 2: Pushing to Docker Hub..."
docker push vova0911/vovagpt:amd64_latest

echo ""
echo "✅ Image pushed successfully!"
echo ""

# Step 3: Restart deployment in argocd namespace
echo "🔄 Step 3: Restarting deployment..."
DEPLOYMENT=$(sudo kubectl get deployment -n argocd -l app=vovagpt -o jsonpath='{.items[0].metadata.name}')

if [ -z "$DEPLOYMENT" ]; then
    echo "❌ No deployment found in argocd namespace"
    echo "Trying vovagpt namespace..."
    DEPLOYMENT=$(sudo kubectl get deployment -n vovagpt -l app=vovagpt -o jsonpath='{.items[0].metadata.name}')
    NAMESPACE="vovagpt"
else
    NAMESPACE="argocd"
fi

echo "Found deployment: $DEPLOYMENT in namespace: $NAMESPACE"

# Delete the pod to force pull new image
sudo kubectl delete pod -n $NAMESPACE -l app=vovagpt

echo ""
echo "⏳ Waiting for new pod to be ready..."
sudo kubectl wait --for=condition=ready pod -l app=vovagpt -n $NAMESPACE --timeout=300s

echo ""
echo "✅ Deployment updated!"
echo ""

# Step 4: Verify
echo "🧪 Step 4: Verifying Ollama is running..."
POD=$(sudo kubectl get pod -n $NAMESPACE -l app=vovagpt -o jsonpath='{.items[0].metadata.name}')

echo "Testing Ollama in pod: $POD"
sudo kubectl exec -n $NAMESPACE $POD -- curl -s http://localhost:11434/api/tags && \
    echo "✅ Ollama is working!" || \
    echo "❌ Ollama still not responding - check logs"

echo ""
echo "📝 Pod logs (last 30 lines):"
sudo kubectl logs -n $NAMESPACE $POD --tail=30

echo ""
echo "================================"
echo "✅ All Done!"
echo "================================"
echo ""
echo "🌐 Access your app at: http://192.168.68.67:30099"
echo "Try downloading a model now!"
echo ""

