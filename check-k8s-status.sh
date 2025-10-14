#!/bin/bash

echo "🔍 VovaGPT k3s Status Check"
echo "============================"
echo ""

# Check if vovagpt namespace exists
echo "📦 Checking namespace..."
kubectl get namespace vovagpt 2>/dev/null || echo "❌ Namespace 'vovagpt' not found"

echo ""
echo "🚀 Checking deployments..."
kubectl get deployments -n vovagpt 2>/dev/null || echo "❌ No deployments found"

echo ""
echo "📊 Checking pods..."
kubectl get pods -n vovagpt 2>/dev/null || echo "❌ No pods found"

echo ""
echo "🌐 Checking services..."
kubectl get svc -n vovagpt 2>/dev/null || echo "❌ No services found"

echo ""
echo "💾 Checking PVCs..."
kubectl get pvc -n vovagpt 2>/dev/null || echo "❌ No PVCs found"

echo ""
echo "🔍 Checking VovaGPT environment..."
kubectl get deployment vovagpt -n vovagpt -o jsonpath='{.spec.template.spec.containers[0].env}' 2>/dev/null | jq '.' || echo "❌ Cannot get VovaGPT env vars"

echo ""
echo "🧪 Testing Ollama connectivity from VovaGPT pod..."
POD=$(kubectl get pods -n vovagpt -l app=vovagpt -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD" ]; then
    echo "Testing from pod: $POD"
    kubectl exec -n vovagpt $POD -- curl -s http://ollama:11434/api/tags 2>/dev/null || echo "❌ Cannot reach Ollama from VovaGPT pod"
else
    echo "❌ No VovaGPT pod found"
fi

echo ""
echo "📝 VovaGPT logs (last 10 lines)..."
kubectl logs -n vovagpt -l app=vovagpt --tail=10 2>/dev/null || echo "❌ Cannot get logs"

echo ""
echo "Done! ✅"

