# VovaGPT - Offline AI Chat with Ollama

Chat app with Ollama AI models. Works 100% offline.

## Quick Start

```bash
# Build & push
./build.sh

# Restart pod
sudo kubectl delete pod -n vovagpt -l app=vovagpt
```

Access: **http://192.168.68.67:30099**

## Files
- `Dockerfile` - Container with VovaGPT + Ollama
- `start.sh` - Startup script (starts Ollama then Flask)
- `build.sh` - Build and push image
- `app/` - Flask application
- `app/ollama` - Ollama binary

## Troubleshooting

### Check logs
```bash
sudo kubectl logs -n vovagpt -l app=vovagpt --tail=50
```

Look for:
- `[DEBUG]` lines showing chat requests
- Ollama errors
- HTTP status codes

### Test Ollama in pod
```bash
POD=$(sudo kubectl get pod -n vovagpt -l app=vovagpt -o jsonpath='{.items[0].metadata.name}')
sudo kubectl exec -n vovagpt $POD -- curl http://localhost:11434/api/tags
```

### Common Issues

**Not answering questions?**
- Check logs for `[DEBUG]` messages
- Verify model is downloaded: look for model name in logs
- Check if model exists in Ollama

**"Model not found" error?**
- Model name might be wrong
- Download model from dashboard first

## Requirements
- Memory: 8Gi
- Storage: 50Gi
- CPU: 4 cores

