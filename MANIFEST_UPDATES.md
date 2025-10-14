# 📝 Manifest Updates - What Changed

Your original manifest was missing **Ollama**, which is why model downloads were failing. I've created an updated complete manifest.

## 🔍 What Was Added

### 1. **Ollama Deployment**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ollama
  namespace: vovagpt
spec:
  containers:
  - name: ollama
    image: ollama/ollama:latest
    ports:
    - containerPort: 11434
```

### 2. **Ollama Service** 
```yaml
apiVersion: v1
kind: Service
metadata:
  name: ollama
  namespace: vovagpt
spec:
  type: ClusterIP
  ports:
  - port: 11434
    targetPort: 11434
  selector:
    app: ollama
```

### 3. **Ollama Storage (PV + PVC)**
```yaml
# PV for Ollama models (50Gi)
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ollama-models-pv
spec:
  capacity:
    storage: 50Gi
  hostPath:
    path: /home/vova/script_files/vovagpt/ollama-models
---
# PVC for Ollama
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ollama-models-pvc
  namespace: vovagpt
spec:
  resources:
    requests:
      storage: 50Gi
  volumeName: ollama-models-pv
```

### 4. **Environment Variables in VovaGPT**
```yaml
env:
- name: OLLAMA_HOST
  value: "http://ollama:11434"  # ← Points to Ollama service
- name: VERSION
  value: "2.0.0"
- name: SECRET_KEY
  value: "change-this-in-production"
```

## 📊 Before vs After

### Before (Your Original Manifest)
```
vovagpt namespace
  ├─ vovagpt-deployment (your app)
  ├─ vovagpt-service (NodePort 30099)
  ├─ vovagpt-data-pv/pvc (1Gi)
  └─ ❌ NO OLLAMA!
```

### After (Updated Complete Manifest)
```
vovagpt namespace
  ├─ vovagpt-deployment (your app)
  │  └─ ENV: OLLAMA_HOST=http://ollama:11434 ← NEW!
  ├─ vovagpt-service (NodePort 30099)
  ├─ vovagpt-data-pv/pvc (1Gi)
  ├─ ✅ ollama deployment (NEW!)
  ├─ ✅ ollama service (NEW!)
  └─ ✅ ollama-models-pv/pvc (50Gi) (NEW!)
```

## 🚀 How to Deploy

### Option 1: Use the Complete Manifest (Recommended)
```bash
chmod +x deploy-complete.sh
./deploy-complete.sh
```

This will:
1. Create the Ollama models directory
2. Deploy everything (VovaGPT + Ollama)
3. Wait for pods to be ready
4. Test the connection
5. Show status and logs

### Option 2: Manual Deployment
```bash
# 1. Create Ollama models directory
mkdir -p /home/vova/script_files/vovagpt/ollama-models

# 2. Apply the complete manifest
sudo kubectl apply -f k8s/vovagpt-complete.yaml

# 3. Wait for pods
sudo kubectl wait --for=condition=ready pod -l app=ollama -n vovagpt --timeout=300s
sudo kubectl wait --for=condition=ready pod -l app=vovagpt -n vovagpt --timeout=300s

# 4. Check status
sudo kubectl get all -n vovagpt
```

### Option 3: Update Existing Deployment
If you want to keep your current setup and just add Ollama:

```bash
# Just deploy Ollama parts
sudo kubectl apply -f k8s/ollama-deployment.yaml

# Update VovaGPT environment
sudo kubectl set env deployment/vovagpt-deployment -n vovagpt \
  OLLAMA_HOST=http://ollama:11434 \
  VERSION=2.0.0

# Restart VovaGPT
sudo kubectl rollout restart deployment/vovagpt-deployment -n vovagpt
```

## 📂 File Structure After Deployment

```
/home/vova/script_files/vovagpt/
├── data/                           # VovaGPT data (users, chats)
│   ├── users.json
│   └── chats.json
└── ollama-models/                  # Ollama AI models (NEW!)
    └── (models will be downloaded here)
```

## ✅ Verification

After deployment, verify everything works:

```bash
# 1. Check all pods are running
sudo kubectl get pods -n vovagpt

# Expected output:
# NAME                                  READY   STATUS    RESTARTS   AGE
# vovagpt-deployment-xxxxx              1/1     Running   0          2m
# ollama-xxxxx                          1/1     Running   0          2m

# 2. Check services
sudo kubectl get svc -n vovagpt

# Expected output:
# NAME              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)           AGE
# vovagpt-service   NodePort    10.43.xxx.xxx   <none>        80:30099/TCP      2m
# ollama            ClusterIP   10.43.xxx.xxx   <none>        11434/TCP         2m

# 3. Test Ollama connection
POD=$(sudo kubectl get pod -n vovagpt -l app=vovagpt -o jsonpath='{.items[0].metadata.name}')
sudo kubectl exec -n vovagpt $POD -- curl -s http://ollama:11434/api/tags

# Expected output:
# {"models":[]}
```

## 🎯 Quick Deploy Command

```bash
# One-line deploy with the complete manifest
sudo kubectl apply -f k8s/vovagpt-complete.yaml && \
  sudo kubectl wait --for=condition=ready pod -l app=ollama -n vovagpt --timeout=300s && \
  sudo kubectl wait --for=condition=ready pod -l app=vovagpt -n vovagpt --timeout=300s && \
  echo "✅ Deployment complete! Access at http://192.168.68.67:30099"
```

## 🔄 Updating Your ArgoCD Application

If you're using ArgoCD, update your application to use the new complete manifest:

```yaml
# In your ArgoCD Application spec:
spec:
  source:
    path: k8s
    targetRevision: main
    # Point to vovagpt-complete.yaml
```

Or commit the changes to git and ArgoCD will auto-sync!

## 🎉 Result

After deployment:
- ✅ VovaGPT accessible at http://192.168.68.67:30099
- ✅ Ollama running internally at http://ollama:11434
- ✅ Model downloads will work
- ✅ All data persisted to /home/vova/script_files/vovagpt/

---

**Ready to deploy? Run:**
```bash
./deploy-complete.sh
```

