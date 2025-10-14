#!/bin/bash

set -e

# Get version from env file
VERSION=$(grep VERSION app/env | cut -d"'" -f2)
IMAGE_NAME="vova0911/vovagpt"
TAG="amd64_${VERSION}"

echo "🚀 Building VovaGPT with Ollama"
echo "==============================="
echo "Version: $VERSION"
echo "Image: ${IMAGE_NAME}:${TAG}"
echo ""

# Build
echo "📦 Building Docker image..."
docker build -t ${IMAGE_NAME}:${TAG} .

# Also tag as latest
docker tag ${IMAGE_NAME}:${TAG} ${IMAGE_NAME}:amd64_latest

echo ""
echo "✅ Image built successfully!"
echo ""

# Push
echo "📤 Pushing to Docker Hub..."
docker push ${IMAGE_NAME}:${TAG}
docker push ${IMAGE_NAME}:amd64_latest

echo ""
echo "✅ Images pushed:"
echo "  - ${IMAGE_NAME}:${TAG}"
echo "  - ${IMAGE_NAME}:amd64_latest"
echo ""

# Update ArgoCD deployment
echo "🔄 Updating ArgoCD deployment..."
DEPLOYMENT=$(sudo kubectl get deployment -n argocd -l app=vovagpt -o jsonpath='{.items[0].metadata.name}')

if [ -n "$DEPLOYMENT" ]; then
    # Update image
    sudo kubectl set image deployment/${DEPLOYMENT} -n argocd vovagpt=${IMAGE_NAME}:${TAG}
    
    echo "✅ Deployment updated to use ${TAG}"
    echo ""
    
    # Wait for rollout
    echo "⏳ Waiting for rollout to complete..."
    sudo kubectl rollout status deployment/${DEPLOYMENT} -n argocd --timeout=300s
    
    echo ""
    echo "✅ Rollout complete!"
    
    # Verify
    echo ""
    echo "🧪 Verifying Ollama..."
    sleep 5
    POD=$(sudo kubectl get pod -n argocd -l app=vovagpt -o jsonpath='{.items[0].metadata.name}')
    sudo kubectl exec -n argocd $POD -- curl -s http://localhost:11434/api/tags && \
        echo "✅ Ollama is working!" || \
        echo "❌ Ollama not responding - check logs"
else
    echo "❌ No deployment found in argocd namespace"
fi

echo ""
echo "================================"
echo "✅ All Done!"
echo "================================"
echo ""
echo "🌐 Access: http://192.168.68.67:30099"
echo ""

