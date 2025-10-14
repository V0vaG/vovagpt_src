#!/bin/bash

# Build VovaGPT with Ollama included
# This creates a single container with both Flask app and Ollama

set -e

VERSION=${1:-"latest"}
IMAGE_NAME="vova0911/vovagpt"
TAG="amd64_${VERSION}"

echo "🚀 Building VovaGPT with Ollama (All-in-One)"
echo "============================================="
echo "Image: ${IMAGE_NAME}:${TAG}"
echo ""

# Build the image
echo "📦 Building Docker image..."
docker build -t ${IMAGE_NAME}:${TAG} .

echo ""
echo "✅ Image built successfully!"
echo ""

# Ask to push
read -p "🤔 Push to Docker Hub? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📤 Pushing to Docker Hub..."
    docker push ${IMAGE_NAME}:${TAG}
    
    # Also tag and push as latest
    if [ "$VERSION" != "latest" ]; then
        echo "🏷️  Tagging as latest..."
        docker tag ${IMAGE_NAME}:${TAG} ${IMAGE_NAME}:amd64_latest
        docker push ${IMAGE_NAME}:amd64_latest
    fi
    
    echo "✅ Pushed successfully!"
fi

echo ""
echo "📋 Image details:"
docker images | grep ${IMAGE_NAME} | head -3

echo ""
echo "🎯 Next steps:"
echo "1. Update your k8s deployment (if needed)"
echo "2. Apply to k8s: sudo kubectl apply -f <your-manifest>.yaml"
echo "3. Restart pods: sudo kubectl rollout restart deployment -n vovagpt"
echo ""
echo "✅ Done!"

