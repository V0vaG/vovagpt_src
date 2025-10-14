#!/bin/bash

echo "🚀 Deploying Ollama to argocd namespace"
echo "========================================"
echo ""

# Deploy Ollama
echo "📦 Deploying Ollama..."
sudo kubectl apply -f k8s/ollama-argocd.yaml

echo ""
echo "⏳ Waiting for Ollama to be ready..."
sudo kubectl wait --for=condition=ready pod -l app=ollama -n argocd --timeout=300s || {
    echo "❌ Timeout waiting for Ollama pod"
    echo "Check status with: sudo kubectl get pods -n argocd -l app=ollama"
    exit 1
}

echo ""
echo "✅ Ollama deployed successfully!"
echo ""
echo "🔍 Checking deployment..."
sudo kubectl get pods -n argocd -l app=ollama
sudo kubectl get svc -n argocd ollama

echo ""
echo "🧪 Testing Ollama..."
POD=$(sudo kubectl get pod -n argocd -l app=vovagpt -o jsonpath='{.items[0].metadata.name}')
if [ -n "$POD" ]; then
    echo "Testing from VovaGPT pod: $POD"
    sudo kubectl exec -n argocd $POD -- curl -s http://ollama:11434/api/tags || {
        echo "❌ Cannot reach Ollama from VovaGPT pod"
        echo "You may need to update OLLAMA_HOST environment variable"
    }
else
    echo "⚠️  VovaGPT pod not found"
fi

echo ""
echo "📝 Next steps:"
echo "1. Update your VovaGPT deployment to set: OLLAMA_HOST=http://ollama:11434"
echo "2. Restart VovaGPT: sudo kubectl rollout restart deployment -n argocd -l app=vovagpt"
echo "3. Try downloading a model from: http://192.168.68.67:30099"
echo ""
echo "🎉 Done!"

