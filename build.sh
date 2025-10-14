#!/bin/bash

VERSION=$(grep VERSION app/env | cut -d"'" -f2)
IMAGE="vova0911/vovagpt:amd64_${VERSION}"

echo "🚀 Building $IMAGE with Ollama"
docker build --no-cache -t $IMAGE .
docker tag $IMAGE vova0911/vovagpt:amd64_latest

echo ""
echo "✅ Build done! Pushing..."
docker push $IMAGE
docker push vova0911/vovagpt:amd64_latest

echo ""
echo "✅ Done! Now restart your k8s deployment:"
echo "sudo kubectl delete pod -n argocd -l app=vovagpt"

