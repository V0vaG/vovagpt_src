# VovaGPT - Offline AI Chat with Ollama

Chat app with Ollama AI models. Works 100% offline.

## Quick Start

### Build & Deploy
```bash
# Build image
chmod +x build.sh
./build.sh

# Restart k8s pod
sudo kubectl delete pod -n argocd -l app=vovagpt
```

### Access
http://192.168.68.67:30099

## Features
- 🤖 Offline AI models via Ollama
- 📥 Download models from dashboard
- 💬 Multiple chats
- 👥 User management
- 🟢 Real-time Ollama status

## Files
- `Dockerfile` - All-in-one container (VovaGPT + Ollama)
- `app/` - Flask application
- `app/ollama` - Ollama binary
- `build.sh` - Build and push image

## Storage
- Data: `/home/vova/script_files/vovagpt/data/`
- Models: `/home/vova/script_files/vovagpt/data/models/`

