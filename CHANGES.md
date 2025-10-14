# 📝 Manifest Changes

## What Changed

### 1. Storage (PV/PVC)
- **Before:** 1Gi
- **After:** 50Gi (for AI models)

### 2. Memory Resources
- **Before:** 256Mi request, 512Mi limit
- **After:** 2Gi request, 8Gi limit (for Ollama + models)

### 3. CPU Resources
- **Before:** 500m request, 1 limit
- **After:** 1000m (1 CPU) request, 4 limit

### 4. Environment Variables (New)
```yaml
env:
- name: OLLAMA_HOST
  value: "http://localhost:11434"
- name: OLLAMA_MODELS
  value: "/root/script_files/vovagpt/data/models"
- name: VERSION
  value: "0.0.11"
```

## Why These Changes

| Change | Reason |
|--------|--------|
| **50Gi storage** | AI models are 2-8GB each |
| **8Gi memory** | Ollama needs 1-2GB + models need 2-8GB |
| **4 CPU** | AI inference is CPU-intensive |
| **Environment vars** | Configure Ollama and app properly |

## Deploy

```bash
chmod +x deploy.sh
./deploy.sh
```

