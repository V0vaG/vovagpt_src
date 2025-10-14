#!/bin/bash

echo "🚀 Deploying VovaGPT with Ollama"
echo "==============================="
echo ""

# Apply manifest
sudo kubectl apply -f manifest.yaml

echo ""
echo "⏳ Waiting for pod to be ready..."
sudo kubectl wait --for=condition=ready pod -l app=vovagpt -n vovagpt --timeout=300s || {
    echo "⚠️ Pod not ready yet, checking logs..."
    sudo kubectl logs -n vovagpt -l app=vovagpt --tail=30
}

echo ""
echo "📊 Status:"
sudo kubectl get pods -n vovagpt

echo ""
echo "✅ Done!"
echo "🌐 Access: http://192.168.68.67:30099"

