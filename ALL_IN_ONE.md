# 🎯 All-in-One Container - VovaGPT with Ollama

Your Dockerfile now includes **both VovaGPT and Ollama in a single container**. This means you can use your existing manifest without any changes!

## ✨ What's Included

The Docker image now contains:
- ✅ VovaGPT Flask app (port 5000)
- ✅ Ollama server (port 11434)
- ✅ Supervisor to manage both processes
- ✅ Automatic connection between app and Ollama

## 🏗️ How It Works

The container runs **two processes** using Supervisor:

1. **Ollama Server**: Listens on `localhost:11434`
2. **VovaGPT App**: Runs on port `5000`, connects to Ollama at `http://localhost:11434`

```
┌─────────────────────────────┐
│     Single Container        │
│                             │
│  ┌──────────────────────┐  │
│  │  Supervisor          │  │
│  │  ┌────────────────┐  │  │
│  │  │ Ollama Server  │  │  │
│  │  │ :11434         │  │  │
│  │  └────────────────┘  │  │
│  │         ▲             │  │
│  │         │             │  │
│  │  ┌──────┴─────────┐  │  │
│  │  │ VovaGPT App    │  │  │
│  │  │ :5000          │  │  │
│  │  └────────────────┘  │  │
│  └──────────────────────┘  │
└─────────────────────────────┘
```

## 🚀 Build & Deploy

### Step 1: Build the Image

```bash
chmod +x build-with-ollama.sh
./build-with-ollama.sh
```

Or manually:
```bash
docker build -t vova0911/vovagpt:amd64_latest .
docker push vova0911/vovagpt:amd64_latest
```

### Step 2: Deploy with Your Existing Manifest

Your existing manifest works **as-is**! No changes needed:

```bash
sudo kubectl apply -f <your-manifest>.yaml
```

The manifest you showed me:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vovagpt-deployment
  namespace: vovagpt
spec:
  template:
    spec:
      containers:
      - name: vovagpt
        image: vova0911/vovagpt:amd64_latest  # ✅ This now includes Ollama!
        ports:
        - containerPort: 5000
```

### Step 3: Restart (if already deployed)

```bash
sudo kubectl rollout restart deployment/vovagpt-deployment -n vovagpt
```

## ✅ Advantages

### ✨ Pros:
- ✅ **Simple deployment** - One container, one manifest
- ✅ **No service mesh** - App and Ollama in same pod
- ✅ **Use existing manifest** - No changes required
- ✅ **Faster communication** - localhost connection
- ✅ **Easy to manage** - Single pod to monitor

### ⚠️ Cons:
- ❌ **Larger image size** (~2GB with Ollama)
- ❌ **More resources per pod** - Both app and Ollama in one container
- ❌ **Can't scale separately** - They scale together

## 📊 Resource Requirements

Update your manifest resources for the combined container:

```yaml
resources:
  requests:
    memory: "2Gi"      # ← Increased for Ollama
    cpu: "1000m"       # ← Increased for Ollama
  limits:
    memory: "8Gi"      # ← Allow more for models
    cpu: "4000m"
```

## 🔍 Verify It's Working

### Check Logs
```bash
# You'll see both Ollama and Flask logs
sudo kubectl logs -n vovagpt -l app=vovagpt --tail=50

# Look for:
# ✅ Ollama server starting
# ✅ Flask app starting
# ✅ Connection to http://localhost:11434
```

### Test from Inside Pod
```bash
POD=$(sudo kubectl get pod -n vovagpt -l app=vovagpt -o jsonpath='{.items[0].metadata.name}')

# Test Ollama
sudo kubectl exec -n vovagpt $POD -- curl http://localhost:11434/api/tags

# Should return: {"models":[]}
```

### Access the App
```
http://192.168.68.67:30099
```

Try downloading a model - it should work now! 🎉

## 🔧 Troubleshooting

### Container Crashes
```bash
# Check logs
sudo kubectl logs -n vovagpt -l app=vovagpt --tail=100

# Look for supervisor errors
sudo kubectl logs -n vovagpt -l app=vovagpt | grep supervisor
```

### Models Not Downloading
```bash
# Exec into container
POD=$(sudo kubectl get pod -n vovagpt -l app=vovagpt -o jsonpath='{.items[0].metadata.name}')
sudo kubectl exec -n vovagpt -it $POD -- /bin/bash

# Inside container:
curl http://localhost:11434/api/tags
ollama list
```

### Out of Memory
```bash
# Increase memory limits in your manifest
resources:
  limits:
    memory: "8Gi"  # or higher
```

## 📝 Environment Variables

The container automatically sets:
- `OLLAMA_HOST=http://localhost:11434`
- `VERSION=2.0.0`
- `PYTHONUNBUFFERED=1`

You can override these in your manifest if needed:
```yaml
env:
- name: VERSION
  value: "2.1.0"
- name: SECRET_KEY
  value: "your-secret"
```

## 🔄 Updates

To update the app:

```bash
# 1. Make changes to code
# 2. Rebuild image
./build-with-ollama.sh 2.0.1

# 3. Update manifest image tag (or latest)
# 4. Apply
sudo kubectl apply -f <your-manifest>.yaml

# 5. Restart
sudo kubectl rollout restart deployment/vovagpt-deployment -n vovagpt
```

## 📦 Image Size

```bash
# Check image size
docker images vova0911/vovagpt

# Typical size: ~2GB (includes Ollama binary and Python runtime)
```

## 🎉 Summary

Your **existing manifest works perfectly** with the new all-in-one image!

1. ✅ Build: `./build-with-ollama.sh`
2. ✅ Deploy: `sudo kubectl apply -f <your-manifest>.yaml`
3. ✅ Access: `http://192.168.68.67:30099`
4. ✅ Download models and enjoy!

**No manifest changes needed!** 🚀

