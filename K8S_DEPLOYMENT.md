# 🚀 VovaGPT on k3s - Deployment Guide

Your VovaGPT app is now **Kubernetes-ready** for deployment on k3s with ArgoCD!

## 📦 What's Created

### Kubernetes Manifests (`k8s/` directory)
```
k8s/
├── namespace.yaml              # vovagpt namespace
├── ollama-deployment.yaml      # Ollama deployment + service + PVC
├── vovagpt-deployment.yaml     # VovaGPT deployment + service + PVC
├── argocd-application.yaml     # ArgoCD app definition
├── kustomization.yaml          # Kustomize config
└── README.md                   # Detailed k8s docs
```

### Container Setup
- **Dockerfile** - Multi-stage build for VovaGPT
- **.dockerignore** - Optimized build context
- **build-and-deploy.sh** - Automated build & deploy script

## 🎯 Current Configuration

Your app is accessible at: **http://192.168.68.67:30099**

### Services:
- **VovaGPT**: NodePort 30099 → Port 5000
- **Ollama**: ClusterIP → Port 11434 (internal)

### Storage:
- **VovaGPT Data**: 5Gi PVC (users, chats)
- **Ollama Models**: 50Gi PVC (AI models)

### Environment:
- `OLLAMA_HOST=http://ollama:11434` (Kubernetes service discovery)
- `VERSION=2.0.0`
- Models stored in Ollama PVC

## 🚀 Quick Deploy

### Method 1: Automated Script (Easiest)
```bash
# Build image and deploy to k3s
./build-and-deploy.sh 2.0.0
```

### Method 2: Manual Steps
```bash
# 1. Build Docker image
docker build -t vovagpt:2.0.0 .

# 2. Load into k3s
docker save vovagpt:2.0.0 | sudo k3s ctr images import -

# 3. Deploy to k8s
kubectl apply -k k8s/

# 4. Check status
kubectl get all -n vovagpt
```

### Method 3: ArgoCD GitOps
```bash
# 1. Update k8s/argocd-application.yaml with your Git repo

# 2. Apply ArgoCD app
kubectl apply -f k8s/argocd-application.yaml

# ArgoCD will auto-sync from Git!
```

## 📊 Architecture in k3s

```
┌─────────────────────────────────────────────────────┐
│                  k3s Cluster                        │
│                                                     │
│  ┌─────────────────────────────────────────────┐  │
│  │         Namespace: vovagpt                  │  │
│  │                                             │  │
│  │  ┌──────────────┐      ┌──────────────┐   │  │
│  │  │   VovaGPT    │─────▶│   Ollama     │   │  │
│  │  │              │      │              │   │  │
│  │  │ Image: vovagpt│      │ Image: ollama│   │  │
│  │  │ Port: 5000   │      │ Port: 11434  │   │  │
│  │  └──────────────┘      └──────────────┘   │  │
│  │         │                      │           │  │
│  │         ▼                      ▼           │  │
│  │  ┌──────────────┐      ┌──────────────┐   │  │
│  │  │ vovagpt-pvc  │      │ ollama-pvc   │   │  │
│  │  │    5Gi       │      │    50Gi      │   │  │
│  │  └──────────────┘      └──────────────┘   │  │
│  └─────────────────────────────────────────────┘  │
│                                                     │
│  NodePort Service: 30099 ─────────────────────┐    │
└─────────────────────────────────────────────────┘  │
                 │                                    │
                 ▼                                    │
        http://192.168.68.67:30099 ◀─────────────────┘
```

## 🔧 Key Configuration Changes

### 1. App Configuration (`app.py`)
```python
# Kubernetes-ready Ollama host
OLLAMA_HOST = os.getenv('OLLAMA_HOST', 'http://localhost:11434')

# In k8s: OLLAMA_HOST=http://ollama:11434 (service name)
```

### 2. Environment Variables (in deployment)
```yaml
env:
- name: OLLAMA_HOST
  value: "http://ollama:11434"  # k8s service discovery
- name: VERSION
  value: "2.0.0"
- name: SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: vovagpt-secrets
      key: secret-key
```

### 3. Data Persistence
- **VovaGPT**: Uses PVC mounted at `/root/script_files/vovagpt/data`
- **Ollama**: Uses PVC mounted at `/root/.ollama` for models

## 🔍 Monitoring & Debugging

### Check Status
```bash
# All resources
kubectl get all -n vovagpt

# Pods
kubectl get pods -n vovagpt -w

# Services
kubectl get svc -n vovagpt

# PVCs
kubectl get pvc -n vovagpt
```

### View Logs
```bash
# VovaGPT logs
kubectl logs -n vovagpt -l app=vovagpt -f

# Ollama logs
kubectl logs -n vovagpt -l app=ollama -f

# Last 50 lines
kubectl logs -n vovagpt deployment/vovagpt --tail=50
```

### Debug Pod Issues
```bash
# Describe pod
kubectl describe pod -n vovagpt -l app=vovagpt

# Get events
kubectl get events -n vovagpt --sort-by='.lastTimestamp'

# Shell into pod
kubectl exec -n vovagpt -it deployment/vovagpt -- /bin/bash
```

### Test Ollama Connection
```bash
# From VovaGPT pod
kubectl exec -n vovagpt -it deployment/vovagpt -- \
  curl http://ollama:11434/api/tags

# Should return: {"models":[]}
```

## 🔄 Updates & Rollbacks

### Update Application
```bash
# Build new version
./build-and-deploy.sh 2.0.1

# Or manually
kubectl set image deployment/vovagpt vovagpt=vovagpt:2.0.1 -n vovagpt

# Check rollout
kubectl rollout status deployment/vovagpt -n vovagpt
```

### Rollback
```bash
# Rollback to previous version
kubectl rollout undo deployment/vovagpt -n vovagpt

# Rollback to specific revision
kubectl rollout undo deployment/vovagpt --to-revision=2 -n vovagpt
```

### With ArgoCD
```bash
# Just push to Git - ArgoCD auto-syncs!
git add .
git commit -m "Update VovaGPT to v2.0.1"
git push

# ArgoCD will detect and deploy automatically
```

## 🔐 Security Best Practices

### Update Secret Key
```bash
# Generate new secret
kubectl create secret generic vovagpt-secrets \
  --from-literal=secret-key="$(openssl rand -base64 32)" \
  -n vovagpt \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart to apply
kubectl rollout restart deployment/vovagpt -n vovagpt
```

### Network Policies (Optional)
```bash
# Restrict Ollama to only VovaGPT pod access
# Add NetworkPolicy to k8s/ directory
```

## 📈 Scaling

### Scale VovaGPT
```bash
# Scale to 3 replicas
kubectl scale deployment vovagpt --replicas=3 -n vovagpt

# Auto-scale based on CPU
kubectl autoscale deployment vovagpt \
  --min=1 --max=5 --cpu-percent=80 -n vovagpt
```

### Scale Ollama
```bash
# Note: Ollama should stay at 1 replica
# Multiple replicas would need shared storage for models
```

## 🌐 Access Options

### 1. NodePort (Current)
```
http://192.168.68.67:30099
```

### 2. Port Forward (Development)
```bash
kubectl port-forward -n vovagpt svc/vovagpt 5000:5000
# Access: http://localhost:5000
```

### 3. Ingress (Production - Optional)
```bash
# Add Ingress manifest to k8s/
# Access via: https://vovagpt.yourdomain.com
```

## 🚨 Troubleshooting

### "Failed to start download" Error
**Cause**: VovaGPT can't reach Ollama

**Solution**:
```bash
# 1. Check Ollama is running
kubectl get pods -n vovagpt -l app=ollama

# 2. Check service exists
kubectl get svc -n vovagpt ollama

# 3. Test connectivity
kubectl exec -n vovagpt deployment/vovagpt -- \
  curl http://ollama:11434/api/tags
```

### Pods Stuck in Pending
**Cause**: PVC provisioning issues

**Solution**:
```bash
# Check PVC status
kubectl get pvc -n vovagpt

# Check storage class
kubectl get sc

# For k3s, ensure local-path exists
kubectl get sc local-path -o yaml
```

### Image Pull Errors
**Cause**: Image not in k3s

**Solution**:
```bash
# Reload image
docker save vovagpt:latest | sudo k3s ctr images import -

# Or check if image exists
sudo k3s crictl images | grep vovagpt
```

## 📚 Additional Resources

- **Kubernetes Docs**: [k8s/README.md](k8s/README.md)
- **Main README**: [README.md](README.md)
- **Quick Start**: [QUICK_START.md](QUICK_START.md)
- **Architecture**: [ARCHITECTURE.md](ARCHITECTURE.md)

---

## 🎉 Summary

You now have:
✅ Kubernetes manifests ready for k3s deployment
✅ ArgoCD GitOps configuration
✅ Automated build & deploy script
✅ Persistent storage for data and models
✅ Service discovery between VovaGPT and Ollama
✅ NodePort access at http://192.168.68.67:30099

**Your app is production-ready for k3s! 🚀**

