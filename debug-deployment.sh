#!/bin/bash

echo "🔍 VovaGPT Deployment Debug"
echo "==========================="
echo ""

# Get the pod name
POD=$(sudo kubectl get pod -n vovagpt -l app=vovagpt -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD" ]; then
    echo "❌ No VovaGPT pod found in namespace 'vovagpt'"
    echo ""
    echo "Checking argocd namespace..."
    POD=$(sudo kubectl get pod -n argocd -l app=vovagpt -o jsonpath='{.items[0].metadata.name}')
    NAMESPACE="argocd"
else
    NAMESPACE="vovagpt"
fi

if [ -z "$POD" ]; then
    echo "❌ No VovaGPT pod found in any namespace"
    exit 1
fi

echo "✅ Found pod: $POD in namespace: $NAMESPACE"
echo ""

# Check what image is running
echo "📦 Current image:"
sudo kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.spec.containers[0].image}'
echo ""
echo ""

# Check if Ollama is in the container
echo "🔍 Checking if Ollama is installed..."
sudo kubectl exec -n $NAMESPACE $POD -- which ollama 2>/dev/null && echo "✅ Ollama binary found" || echo "❌ Ollama not found in container"
echo ""

# Check if supervisor is running
echo "🔍 Checking processes in container..."
sudo kubectl exec -n $NAMESPACE $POD -- ps aux 2>/dev/null | head -10
echo ""

# Check if Ollama port is listening
echo "🔍 Checking if Ollama is listening on port 11434..."
sudo kubectl exec -n $NAMESPACE $POD -- netstat -tuln 2>/dev/null | grep 11434 || echo "❌ Port 11434 not listening"
echo ""

# Try to connect to Ollama
echo "🧪 Testing Ollama connection..."
sudo kubectl exec -n $NAMESPACE $POD -- curl -s http://localhost:11434/api/tags 2>/dev/null && echo "✅ Ollama responding" || echo "❌ Ollama not responding"
echo ""

# Check environment variables
echo "🔧 Environment variables:"
sudo kubectl exec -n $NAMESPACE $POD -- env | grep -E 'OLLAMA|VERSION'
echo ""

# Check logs
echo "📝 Recent logs (last 20 lines):"
sudo kubectl logs -n $NAMESPACE $POD --tail=20
echo ""

echo "================================"
echo "📋 Summary:"
echo "================================"
echo "If Ollama is NOT installed:"
echo "  1. Build new image: ./build-with-ollama.sh"
echo "  2. Push to registry"
echo "  3. Update deployment: sudo kubectl rollout restart deployment -n $NAMESPACE"
echo ""
echo "If Ollama is installed but not running:"
echo "  Check logs above for errors"
echo ""

