# ✅ Custom Models Directory - Setup Complete

## 🎯 What Changed

Your app now downloads and saves Ollama models to a **custom directory** instead of the default Ollama location.

### Models Location
**Before:** `~/.ollama/models/` (default Ollama location)  
**After:** `~/script_files/vovagpt/data/models/` (custom location)

## 📝 Changes Made

### 1. **app.py** - Added Custom Directory Setup
```python
# Added MODELS_DIR path
MODELS_DIR = os.path.join(DATA_DIR, 'models')

# Create directory
os.makedirs(MODELS_DIR, exist_ok=True)

# Set Ollama to use custom directory
os.environ['OLLAMA_MODELS'] = MODELS_DIR
```

### 2. **start.sh** - Updated to Use Custom Directory
- Sets `OLLAMA_MODELS` environment variable
- Creates models directory automatically
- Starts Ollama with custom models path

### 3. **start_ollama.sh** - New Helper Script
A dedicated script to start Ollama with the custom directory:
```bash
OLLAMA_MODELS="$HOME/script_files/vovagpt/data/models" ollama serve
```

### 4. **docker-compose.yml** - Updated Volume Mapping
```yaml
environment:
  - OLLAMA_MODELS=/root/script_files/vovagpt/data/models
volumes:
  - ./data:/root/script_files/vovagpt/data
```

### 5. **Documentation** - Added Guide
- Created `CUSTOM_MODELS_DIR.md` - Complete guide on custom directory
- Updated `README.md` - Added feature mention
- Updated `QUICK_START.md` - Added setup notes

## 🚀 How to Use

### Option 1: Automated (Easiest)
```bash
cd app
./start.sh
```

The script automatically:
1. ✅ Creates `~/script_files/vovagpt/data/models/`
2. ✅ Sets `OLLAMA_MODELS` environment variable
3. ✅ Starts Ollama with custom directory
4. ✅ Starts the Flask app

### Option 2: Manual Start
```bash
# Terminal 1: Start Ollama
cd app
./start_ollama.sh

# Terminal 2: Start App
python app.py
```

### Option 3: Direct Command
```bash
# Set variable and start Ollama
OLLAMA_MODELS="$HOME/script_files/vovagpt/data/models" ollama serve

# In another terminal, start app
python app.py
```

## 📁 Directory Structure

Your complete app structure:
```
~/script_files/vovagpt/
├── data/
│   ├── users.json              # User accounts
│   ├── chats.json              # Chat history  
│   └── models/                 # ← AI Models (CUSTOM)
│       ├── manifests/
│       │   └── registry.ollama.ai/
│       │       └── library/
│       │           ├── llama3.2/
│       │           └── qwen2.5/
│       └── blobs/
│           └── sha256-xxxxx    # Model files
```

## ✅ Benefits

| Benefit | Description |
|---------|-------------|
| 🗂️ **Organization** | All app data in one directory |
| 💾 **Easy Backup** | `tar -czf backup.tar.gz ~/script_files/vovagpt/` |
| 🚀 **Portable** | Move entire app with data and models |
| 🔒 **Isolated** | Separate from system Ollama |
| 🧹 **Clean** | Delete one directory to remove all |

## 🔍 Verification

### Check if Custom Directory is Active:
```bash
# Check environment variable
echo $OLLAMA_MODELS
# Should show: /home/yourusername/script_files/vovagpt/data/models

# List models in custom directory
ls -la ~/script_files/vovagpt/data/models/

# Check disk usage
du -sh ~/script_files/vovagpt/data/models/
```

### Test Download:
1. Start the app: `./start.sh`
2. Open browser: http://localhost:5000
3. Download a model (e.g., llama3.2)
4. Check if it's in custom directory:
   ```bash
   ls ~/script_files/vovagpt/data/models/manifests/registry.ollama.ai/library/
   ```

## 🛠️ Troubleshooting

### Models Still Going to Default Location?

**Problem:** Models download to `~/.ollama/models/` instead of custom directory

**Solution:**
1. Kill any running Ollama:
   ```bash
   pkill ollama
   ```

2. Start with custom directory:
   ```bash
   ./start_ollama.sh
   # or
   OLLAMA_MODELS="$HOME/script_files/vovagpt/data/models" ollama serve
   ```

3. Restart the app

### App Can't Find Models?

**Solution:**
1. Verify Ollama is using custom directory:
   ```bash
   env | grep OLLAMA_MODELS
   ```

2. If not set, restart Ollama with:
   ```bash
   ./start_ollama.sh
   ```

### Want to Move Existing Models?

If you have models in `~/.ollama/models/`:

```bash
# Copy to custom directory
cp -r ~/.ollama/models/* ~/script_files/vovagpt/data/models/

# Or move them
mv ~/.ollama/models/* ~/script_files/vovagpt/data/models/
```

## 📦 Scripts Summary

| Script | Purpose |
|--------|---------|
| `start.sh` | Complete automated setup (Ollama + App) |
| `start_ollama.sh` | Start Ollama with custom models directory |
| `app.py` | Sets `OLLAMA_MODELS` environment variable |

## 🎉 Success!

Your models are now stored in:
```
~/script_files/vovagpt/data/models/
```

Everything is organized in one place for easy management, backup, and portability!

---

**For more details, see [CUSTOM_MODELS_DIR.md](CUSTOM_MODELS_DIR.md)**

