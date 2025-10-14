# 🔧 Troubleshooting "Failed to start download" in k3s

Since you're accessing VovaGPT at **http://192.168.68.67:30099/dashboard**, the app is running in your k3s cluster. The download error means the VovaGPT pod can't connect to Ollama.

## 🔍 Quick Diagnosis

Run this diagnostic script:

```bash
chmod +x check-k8s-status.sh
./check-k8s-status.sh
```

## 🎯 Common Issues & Solutions

### Issue 1: Ollama Not Deployed

**Check:**
```bash
kubectl get pods -n vovagpt
```

**Expected:** You should see both `vovagpt-xxx` and `ollama-xxx` pods

**Fix if Ollama is missing:**
```bash
# Deploy Ollama
kubectl apply -f k8s/ollama-deployment.yaml

# Wait for it to be ready
kubectl wait --for=condition=ready pod -l app=ollama -n vovagpt --timeout=300s
```

### Issue 2: Wrong OLLAMA_HOST

**Check current config:**
```bash
kubectl get deployment vovagpt -n vovagpt -o yaml | grep OLLAMA_HOST
```

**Should be:**
```
- name: OLLAMA_HOST
  value: http://ollama:11434
```

**Fix if incorrect:**
```bash
kubectl set env deployment/vovagpt -n vovagpt OLLAMA_HOST=http://ollama:11434
```

### Issue 3: Ollama Service Not Accessible

**Check service:**
```bash
kubectl get svc ollama -n vovagpt
```

**Test connectivity from VovaGPT pod:**
```bash
POD=$(kubectl get pod -n vovagpt -l app=vovagpt -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n vovagpt $POD -- curl http://ollama:11434/api/tags
```

**Expected response:** `{"models":[]}`

**Fix if service missing:**
```bash
kubectl apply -f k8s/ollama-deployment.yaml
```

## 🚀 Complete Redeployment

If things are broken, redeploy everything:

```bash
# Delete everything
kubectl delete namespace vovagpt

# Wait a moment
sleep 5

# Redeploy
kubectl apply -k k8s/

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app=vovagpt -n vovagpt --timeout=300s
kubectl wait --for=condition=ready pod -l app=ollama -n vovagpt --timeout=300s

# Check status
kubectl get all -n vovagpt
```

## 📊 Check Logs

### VovaGPT Logs
```bash
kubectl logs -n vovagpt -l app=vovagpt -f
```

Look for:
- ✅ `🚀 VovaGPT starting...`
- ✅ `🤖 Ollama host: http://ollama:11434`
- ❌ Any connection errors

### Ollama Logs
```bash
kubectl logs -n vovagpt -l app=ollama -f
```

Look for:
- ✅ `Ollama server running`
- ❌ Any startup errors

## 🔍 Detailed Diagnostics

### 1. Check All Resources
```bash
kubectl get all,pvc,secrets -n vovagpt
```

### 2. Describe Pods
```bash
kubectl describe pod -n vovagpt -l app=vovagpt
kubectl describe pod -n vovagpt -l app=ollama
```

### 3. Check Events
```bash
kubectl get events -n vovagpt --sort-by='.lastTimestamp'
```

### 4. Test DNS Resolution
```bash
POD=$(kubectl get pod -n vovagpt -l app=vovagpt -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n vovagpt $POD -- nslookup ollama
```

## ✅ Expected Working State

When everything is working:

```bash
$ kubectl get pods -n vovagpt
NAME                       READY   STATUS    RESTARTS   AGE
vovagpt-xxxxx             1/1     Running   0          5m
ollama-xxxxx              1/1     Running   0          5m

$ kubectl get svc -n vovagpt  
NAME      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
vovagpt   NodePort    10.43.xxx.xxx   <none>        5000:30099/TCP   5m
ollama    ClusterIP   10.43.xxx.xxx   <none>        11434/TCP        5m
```

## 🆘 If Still Failing

1. **Check if it's a local test vs k8s:**
   - Local: `http://localhost:5000` 
   - k8s: `http://192.168.68.67:30099`

2. **Verify you deployed to k8s:**
   ```bash
   kubectl get deployments -n vovagpt
   ```

3. **Share the output of:**
   ```bash
   ./check-k8s-status.sh
   ```

## 📞 Next Steps

After running diagnostics:

1. Run: `./check-k8s-status.sh`
2. Share the output
3. We'll identify and fix the specific issue

---

**Quick Fix Command:**
```bash
# Redeploy both services
kubectl delete -f k8s/vovagpt-deployment.yaml
kubectl delete -f k8s/ollama-deployment.yaml
sleep 3
kubectl apply -f k8s/ollama-deployment.yaml
sleep 10
kubectl apply -f k8s/vovagpt-deployment.yaml

# Check status
kubectl get pods -n vovagpt -w
```

