# VovaGPT - Offline AI Chat with Ollama

Offline chat app with Ollama AI models.

## Build & Deploy

```bash
# Build and push
chmod +x build.sh
./build.sh

# Restart pod
sudo kubectl delete pod -n vovagpt -l app=vovagpt
```

Access: **http://192.168.68.67:30099**

## Important Notes

⏱️ **First message takes 1-2 minutes** - Model needs to load into memory  
⚡ **Subsequent messages are fast** - Model stays loaded for 5 minutes  
🔄 **Timeout increased to 10 minutes** - Handles slow first loads

## Files
- `Dockerfile` - Container (VovaGPT + Ollama)
- `start.sh` - Starts Ollama then Flask
- `build.sh` - Build & push script
- `app/ollama` - Ollama binary
- `app/` - Flask app

## Troubleshooting

### Check logs
```bash
sudo kubectl logs -n vovagpt -l app=vovagpt --tail=100
```

### Test in pod
```bash
POD=$(sudo kubectl get pod -n vovagpt -l app=vovagpt -o jsonpath='{.items[0].metadata.name}')
sudo kubectl exec -n vovagpt $POD -- curl http://localhost:11434/api/tags
```

### Common Issues

**First message timeout?**
- Wait 1-2 minutes for model to load
- Check CPU resources (4 cores recommended)
- Larger models need more time

**Not answering at all?**
- Check logs for `[DEBUG]` messages
- Verify model downloaded
- Ensure 8Gi memory available

## Resources
- Memory: 8Gi (for Ollama + models)
- CPU: 4 cores (for AI inference)
- Storage: 50Gi (for models)
