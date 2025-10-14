#!/bin/bash

set -e

# Force rebuild with --no-cache to ensure Ollama is installed

VERSION=$(grep VERSION app/env | cut -d"'" -f2)
IMAGE_NAME="vova0911/vovagpt"
TAG="amd64_${VERSION}"

echo "🔨 FORCE REBUILDING VovaGPT with Ollama (no cache)"
echo "=================================================="
echo "Version: $VERSION"
echo "Image: ${IMAGE_NAME}:${TAG}"
echo ""

# Clean up old images first
echo "🧹 Cleaning up old images..."
docker rmi ${IMAGE_NAME}:${TAG} 2>/dev/null || true
docker rmi ${IMAGE_NAME}:amd64_latest 2>/dev/null || true

echo ""
echo "📦 Building with --no-cache (this will take ~10 minutes)..."
docker build --no-cache -t ${IMAGE_NAME}:${TAG} .

# Tag as latest
docker tag ${IMAGE_NAME}:${TAG} ${IMAGE_NAME}:amd64_latest

echo ""
echo "✅ Build complete!"
echo ""

# Verify Ollama is in the image
echo "🔍 Verifying Ollama is in the image..."
docker run --rm ${IMAGE_NAME}:${TAG} which ollama && \
    echo "✅ Ollama found in image!" || \
    echo "❌ Ollama STILL not in image - something is wrong!"

echo ""
echo "📤 Pushing to Docker Hub..."
docker push ${IMAGE_NAME}:${TAG}
docker push ${IMAGE_NAME}:amd64_latest

echo ""
echo "✅ Images pushed!"
echo ""

# Update deployment
echo "🔄 Updating ArgoCD deployment..."
DEPLOYMENT=$(sudo kubectl get deployment -n argocd -l app=vovagpt -o jsonpath='{.items[0].metadata.name}')

if [ -n "$DEPLOYMENT" ]; then
    # Force delete pod to pull new image
    sudo kubectl delete pod -n argocd -l app=vovagpt
    
    echo "⏳ Waiting for new pod to start..."
    sudo kubectl wait --for=condition=ready pod -l app=vovagpt -n argocd --timeout=300s
    
    echo ""
    echo "🧪 Verifying Ollama in pod..."
    sleep 5
    POD=$(sudo kubectl get pod -n argocd -l app=vovagpt -o jsonpath='{.items[0].metadata.name}')
    
    echo "Checking if Ollama is installed..."
    sudo kubectl exec -n argocd $POD -- which ollama && \
        echo "✅ Ollama binary found!" || \
        echo "❌ Ollama binary not found!"
    
    echo ""
    echo "Testing Ollama API..."
    sudo kubectl exec -n argocd $POD -- curl -s http://localhost:11434/api/tags && \
        echo "✅ Ollama is working!" || \
        echo "❌ Ollama not responding"
        
    echo ""
    echo "Checking processes..."
    sudo kubectl exec -n argocd $POD -- ps aux | grep -E 'ollama|supervisor'
fi

echo ""
echo "================================"
echo "✅ All Done!"
echo "================================"
echo ""
echo "🌐 Access: http://192.168.68.67:30099"
echo "Now try downloading a model!"
echo ""

