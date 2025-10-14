#!/bin/bash

echo "🚀 Deploying Complete VovaGPT Stack with Ollama"
echo "================================================"
echo ""

# Create ollama models directory on host
echo "📁 Creating Ollama models directory..."
mkdir -p /home/vova/script_files/vovagpt/ollama-models
echo "✅ Directory created: /home/vova/script_files/vovagpt/ollama-models"

echo ""
echo "🔄 Applying manifest..."
sudo kubectl apply -f k8s/vovagpt-complete.yaml

echo ""
echo "⏳ Waiting for Ollama to be ready..."
sudo kubectl wait --for=condition=ready pod -l app=ollama -n vovagpt --timeout=300s || {
    echo "⚠️  Timeout waiting for Ollama, checking status..."
    sudo kubectl get pods -n vovagpt -l app=ollama
}

echo ""
echo "⏳ Waiting for VovaGPT to be ready..."
sudo kubectl wait --for=condition=ready pod -l app=vovagpt -n vovagpt --timeout=300s || {
    echo "⚠️  Timeout waiting for VovaGPT, checking status..."
    sudo kubectl get pods -n vovagpt -l app=vovagpt
}

echo ""
echo "📊 Deployment Status:"
echo "===================="
sudo kubectl get all -n vovagpt

echo ""
echo "💾 Storage:"
echo "=========="
sudo kubectl get pv,pvc -n vovagpt

echo ""
echo "🧪 Testing Ollama Connection..."
POD=$(sudo kubectl get pod -n vovagpt -l app=vovagpt -o jsonpath='{.items[0].metadata.name}')
if [ -n "$POD" ]; then
    echo "Testing from VovaGPT pod: $POD"
    sudo kubectl exec -n vovagpt $POD -- curl -s http://ollama:11434/api/tags && \
        echo "✅ Connection successful!" || \
        echo "❌ Connection failed"
fi

echo ""
echo "📝 VovaGPT Logs (last 10 lines):"
echo "================================"
sudo kubectl logs -n vovagpt -l app=vovagpt --tail=10

echo ""
echo "✅ Deployment Complete!"
echo ""
echo "🌐 Access your app at: http://192.168.68.67:30099"
echo ""
echo "📋 Useful commands:"
echo "  - View logs:  sudo kubectl logs -n vovagpt -l app=vovagpt -f"
echo "  - Check pods: sudo kubectl get pods -n vovagpt"
echo "  - Restart:    sudo kubectl rollout restart deployment -n vovagpt"
echo ""

