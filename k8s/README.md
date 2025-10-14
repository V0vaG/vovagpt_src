# 🚀 VovaGPT - Kubernetes Deployment

Deploy VovaGPT on k3s with ArgoCD for automated GitOps deployments.

## 📋 Prerequisites

- k3s cluster running
- ArgoCD installed
- kubectl configured
- Docker for building images

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│           k3s Cluster                   │
│                                         │
│  ┌──────────────┐    ┌──────────────┐ │
│  │   VovaGPT    │───▶│   Ollama     │ │
│  │   Pod        │    │   Pod        │ │
│  │              │    │              │ │
│  │ Port: 5000   │    │ Port: 11434  │ │
│  └──────────────┘    └──────────────┘ │
│         │                     │        │
│         ▼                     ▼        │
│  ┌──────────────┐    ┌──────────────┐ │
│  │  vovagpt-pvc │    │  ollama-pvc  │ │
│  │    (5Gi)     │    │   (50Gi)     │ │
│  └──────────────┘    └──────────────┘ │
│                                         │
│  NodePort: 30099 ─────────────────────┐│
└────────────────────────────────────────┘│
             │                            │
             ▼                            │
    http://192.168.68.67:30099 ◀──────────┘
```

## 🔧 Configuration

### Environment Variables

Set in `vovagpt-deployment.yaml`:

```yaml
env:
- name: OLLAMA_HOST
  value: "http://ollama:11434"  # Ollama service name
- name: VERSION
  value: "2.0.0"
- name: SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: vovagpt-secrets
      key: secret-key
```

### Storage

- **VovaGPT Data**: 5Gi PVC for users/chats
- **Ollama Models**: 50Gi PVC for AI models
- **Storage Class**: `local-path` (k3s default)

## 📦 Build & Deploy

### Option 1: Manual Deployment

```bash
# 1. Build Docker image
docker build -t vovagpt:latest .

# 2. Push to registry (or load into k3s)
docker save vovagpt:latest | sudo k3s ctr images import -

# 3. Apply manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/ollama-deployment.yaml
kubectl apply -f k8s/vovagpt-deployment.yaml

# 4. Check status
kubectl get pods -n vovagpt
kubectl get svc -n vovagpt
```

### Option 2: ArgoCD (Recommended)

```bash
# 1. Update argocd-application.yaml with your Git repo URL

# 2. Apply ArgoCD application
kubectl apply -f k8s/argocd-application.yaml

# 3. ArgoCD will automatically sync and deploy
```

### Option 3: Kustomize

```bash
# Deploy using kustomize
kubectl apply -k k8s/
```

## 🌐 Access

Once deployed, access VovaGPT at:

```
http://192.168.68.67:30099/dashboard
```

Or use kubectl port-forward:

```bash
kubectl port-forward -n vovagpt svc/vovagpt 5000:5000
# Then access: http://localhost:5000
```

## 🔍 Monitoring

### Check Deployment Status

```bash
# View all resources
kubectl get all -n vovagpt

# Check pod logs
kubectl logs -n vovagpt -l app=vovagpt -f
kubectl logs -n vovagpt -l app=ollama -f

# Check PVCs
kubectl get pvc -n vovagpt

# Describe deployments
kubectl describe deployment -n vovagpt vovagpt
kubectl describe deployment -n vovagpt ollama
```

### ArgoCD Dashboard

```bash
# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open: https://localhost:8080
```

## 🛠️ Troubleshooting

### VovaGPT can't connect to Ollama

```bash
# Check Ollama service
kubectl get svc -n vovagpt ollama

# Test connectivity from VovaGPT pod
kubectl exec -n vovagpt -it deployment/vovagpt -- \
  curl http://ollama:11434/api/tags
```

### Models not downloading

```bash
# Check Ollama logs
kubectl logs -n vovagpt -l app=ollama -f

# Check PVC
kubectl describe pvc -n vovagpt ollama-pvc

# Exec into Ollama pod
kubectl exec -n vovagpt -it deployment/ollama -- /bin/sh
# Inside pod: ollama list
```

### Storage Issues

```bash
# Check PVC status
kubectl get pvc -n vovagpt

# If pending, check storage class
kubectl get sc

# For k3s, local-path should exist
kubectl get sc local-path
```

## 🔄 Updates

### Update VovaGPT Application

```bash
# 1. Build new image with version tag
docker build -t vovagpt:2.0.1 .

# 2. Update deployment
kubectl set image deployment/vovagpt vovagpt=vovagpt:2.0.1 -n vovagpt

# Or with ArgoCD - just push to git and it auto-syncs!
```

### Update Ollama

```bash
# Update Ollama image
kubectl set image deployment/ollama ollama=ollama/ollama:latest -n vovagpt
```

## 📊 Resource Requirements

### VovaGPT Pod
- **Requests**: 256Mi RAM, 100m CPU
- **Limits**: 1Gi RAM, 1 CPU

### Ollama Pod
- **Requests**: 2Gi RAM, 500m CPU  
- **Limits**: 8Gi RAM, 4 CPU
- **Note**: Increase for larger models

## 🔐 Security

### Update Secret Key

```bash
# Generate new secret
NEW_SECRET=$(openssl rand -base64 32)

# Update secret
kubectl create secret generic vovagpt-secrets \
  --from-literal=secret-key="$NEW_SECRET" \
  -n vovagpt \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart deployment
kubectl rollout restart deployment/vovagpt -n vovagpt
```

## 📝 Manifest Structure

```
k8s/
├── namespace.yaml              # Namespace definition
├── ollama-deployment.yaml      # Ollama deployment, service, PVC
├── vovagpt-deployment.yaml     # VovaGPT deployment, service, PVC, secret
├── argocd-application.yaml     # ArgoCD application manifest
├── kustomization.yaml          # Kustomize configuration
└── README.md                   # This file
```

## 🚀 Quick Commands

```bash
# Deploy everything
kubectl apply -k k8s/

# Check status
kubectl get all -n vovagpt

# View logs
kubectl logs -n vovagpt -l app=vovagpt --tail=50 -f

# Access shell
kubectl exec -n vovagpt -it deployment/vovagpt -- /bin/bash

# Delete everything
kubectl delete namespace vovagpt
```

## 🔗 URLs

- **VovaGPT**: http://192.168.68.67:30099
- **Ollama API**: http://ollama.vovagpt.svc.cluster.local:11434 (internal)

---

**Happy Deploying! 🎉**

