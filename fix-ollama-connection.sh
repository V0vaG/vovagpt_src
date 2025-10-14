#!/bin/bash

echo "🔧 Fixing Ollama connection for VovaGPT in argocd namespace"
echo "============================================================"
echo ""

# Step 1: Check if Ollama exists
echo "1️⃣ Checking if Ollama is deployed..."
if sudo kubectl get deployment ollama -n argocd &>/dev/null; then
    echo "✅ Ollama deployment found"
else
    echo "❌ Ollama not found - deploying it now..."
    sudo kubectl apply -f k8s/ollama-argocd.yaml
    echo "⏳ Waiting for Ollama to start..."
    sudo kubectl wait --for=condition=ready pod -l app=ollama -n argocd --timeout=300s
fi

echo ""
echo "2️⃣ Checking Ollama service..."
if sudo kubectl get svc ollama -n argocd &>/dev/null; then
    echo "✅ Ollama service found"
    sudo kubectl get svc ollama -n argocd
else
    echo "❌ Ollama service not found"
    exit 1
fi

echo ""
echo "3️⃣ Finding VovaGPT deployment..."
DEPLOYMENT=$(sudo kubectl get deployment -n argocd -l app=vovagpt -o jsonpath='{.items[0].metadata.name}')
if [ -z "$DEPLOYMENT" ]; then
    echo "❌ VovaGPT deployment not found"
    exit 1
fi
echo "✅ Found deployment: $DEPLOYMENT"

echo ""
echo "4️⃣ Updating OLLAMA_HOST environment variable..."
sudo kubectl set env deployment/$DEPLOYMENT -n argocd OLLAMA_HOST=http://ollama:11434

echo ""
echo "5️⃣ Waiting for rollout to complete..."
sudo kubectl rollout status deployment/$DEPLOYMENT -n argocd

echo ""
echo "6️⃣ Testing connection..."
sleep 5
POD=$(sudo kubectl get pod -n argocd -l app=vovagpt -o jsonpath='{.items[0].metadata.name}')
echo "Testing from pod: $POD"
sudo kubectl exec -n argocd $POD -- curl -s http://ollama:11434/api/tags

echo ""
echo "✅ All done! Try downloading a model now at:"
echo "   http://192.168.68.67:30099/dashboard"
echo ""

