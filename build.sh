#!/bin/bash
VERSION=$(grep VERSION app/env | cut -d"'" -f2)
IMAGE="vova0911/vovagpt:amd64_${VERSION}"

echo "🚀 Building $IMAGE"
docker build --no-cache -t $IMAGE .
docker tag $IMAGE vova0911/vovagpt:amd64_latest

echo ""
echo "📤 Pushing..."
docker push $IMAGE
docker push vova0911/vovagpt:amd64_latest

echo ""
echo "✅ Done!"
echo "sudo kubectl delete pod -n vovagpt -l app=vovagpt"

