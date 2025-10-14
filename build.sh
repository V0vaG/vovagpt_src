#!/bin/bash
VERSION=$(grep VERSION app/env | cut -d"'" -f2)
IMAGE="vova0911/vovagpt:amd64_${VERSION}"

echo "🚀 Building $IMAGE"
docker build --no-cache -t $IMAGE .
docker tag $IMAGE vova0911/vovagpt:amd64_latest

echo "📤 Pushing..."
docker push $IMAGE
docker push vova0911/vovagpt:amd64_latest

echo "✅ Done! Restart k8s pod:"
echo "sudo kubectl delete pod -n argocd -l app=vovagpt"

