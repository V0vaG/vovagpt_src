# 🔧 Memory Fix for Ollama

## Issue
Exit code 137 = Container killed due to OOM (Out of Memory)

Your current manifest has:
```yaml
resources:
  limits:
    memory: "512Mi"  # ← Too small for Ollama + models
```

## Solution

Update your manifest to increase memory:

```yaml
resources:
  requests:
    memory: "2Gi"     # ← Minimum for Ollama
    cpu: "1000m"
  limits:
    memory: "8Gi"     # ← Allow room for models
    cpu: "4000m"
```

## Apply Fix

```bash
# Update your manifest with new resource limits
# Then apply:
sudo kubectl apply -f <your-manifest>.yaml

# Or patch directly:
sudo kubectl patch deployment vovagpt-deployment -n argocd -p '{"spec":{"template":{"spec":{"containers":[{"name":"vovagpt","resources":{"requests":{"memory":"2Gi","cpu":"1"},"limits":{"memory":"8Gi","cpu":"4"}}}]}}}}'

# Delete pod to restart with new limits
sudo kubectl delete pod -n argocd -l app=vovagpt
```

## Why This Is Needed

- Ollama needs ~1-2GB just to run
- Models need 2-8GB depending on size
- Flask app needs ~256MB
- Total: **Minimum 2-3GB, recommended 4-8GB**

## Quick Patch Command

```bash
sudo kubectl set resources deployment vovagpt-deployment -n argocd \
  --limits=cpu=4,memory=8Gi \
  --requests=cpu=1,memory=2Gi
  
sudo kubectl delete pod -n argocd -l app=vovagpt
```

