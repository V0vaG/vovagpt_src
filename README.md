# VovaGPT - Offline AI Chat with Ollama

Chat app with Ollama AI models. Works 100% offline.

## Quick Start

### Build & Deploy
```bash
# 1. Build image
chmod +x build.sh deploy.sh
./build.sh

# 2. Deploy to k8s
./deploy.sh
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
- `manifest.yaml` - Kubernetes deployment
- `build.sh` - Build and push image
- `deploy.sh` - Deploy to k8s
- `app/` - Flask application
- `app/ollama` - Ollama binary

## Storage
- Data: `/home/vova/script_files/vovagpt/data/`
- Models: `/home/vova/script_files/vovagpt/data/models/`

## Requirements
- Memory: 8Gi (for Ollama + models)
- Storage: 50Gi (for multiple models)
- CPU: 4 cores (for AI inference)

