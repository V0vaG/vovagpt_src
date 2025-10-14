#!/bin/bash

# VovaGPT - Build and Deploy Script for k3s
# Usage: ./build-and-deploy.sh [version]

set -e

VERSION=${1:-"latest"}
IMAGE_NAME="vovagpt"
NAMESPACE="vovagpt"

echo "🚀 VovaGPT Build & Deploy Script"
echo "=================================="
echo "Version: $VERSION"
echo ""

# Build Docker image
echo "📦 Building Docker image..."
docker build -t ${IMAGE_NAME}:${VERSION} .

# Tag as latest
if [ "$VERSION" != "latest" ]; then
    docker tag ${IMAGE_NAME}:${VERSION} ${IMAGE_NAME}:latest
fi

echo "✅ Image built: ${IMAGE_NAME}:${VERSION}"
echo ""

# Check if running in k3s
if command -v k3s &> /dev/null; then
    echo "📥 Loading image into k3s..."
    docker save ${IMAGE_NAME}:${VERSION} | sudo k3s ctr images import -
    echo "✅ Image loaded into k3s"
else
    echo "⚠️  k3s not found - skipping image import"
    echo "   If you have a registry, push with:"
    echo "   docker push ${IMAGE_NAME}:${VERSION}"
fi

echo ""

# Ask to deploy
read -p "🤔 Deploy to k3s now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Deploying to k3s..."
    
    # Apply manifests
    kubectl apply -f k8s/namespace.yaml
    kubectl apply -f k8s/ollama-deployment.yaml
    kubectl apply -f k8s/vovagpt-deployment.yaml
    
    echo ""
    echo "✅ Deployment complete!"
    echo ""
    echo "📊 Check status with:"
    echo "   kubectl get all -n $NAMESPACE"
    echo ""
    echo "📝 View logs with:"
    echo "   kubectl logs -n $NAMESPACE -l app=vovagpt -f"
    echo ""
    echo "🌐 Access at: http://192.168.68.67:30099"
else
    echo "⏭️  Skipping deployment"
    echo ""
    echo "To deploy manually:"
    echo "   kubectl apply -k k8s/"
fi

echo ""
echo "🎉 Done!"

