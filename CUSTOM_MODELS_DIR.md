# 📁 Custom Models Directory Setup

Your app is configured to store Ollama models in a **custom directory** instead of the default Ollama location.

## 📍 Models Location

**Models Directory:** `~/script_files/vovagpt/data/models/`

This keeps all your app data organized in one place:
```
~/script_files/vovagpt/
├── data/
│   ├── users.json      # User accounts
│   ├── chats.json      # Chat history
│   └── models/         # AI models (custom location)
│       ├── llama3.2/
│       ├── qwen2.5/
│       └── ... (other models)
```

## 🚀 How to Start Ollama with Custom Directory

### Option 1: Using the Helper Script (Easiest)
```bash
cd app
./start_ollama.sh
```

This automatically:
- Creates the models directory
- Sets the `OLLAMA_MODELS` environment variable
- Starts Ollama server

### Option 2: Manual Start
```bash
export OLLAMA_MODELS="$HOME/script_files/vovagpt/data/models"
ollama serve
```

### Option 3: One-liner
```bash
OLLAMA_MODELS="$HOME/script_files/vovagpt/data/models" ollama serve
```

## 🎯 Complete Startup Process

### Method 1: Using start.sh (Recommended)
The `start.sh` script handles everything automatically:

```bash
cd app
./start.sh
```

This script:
1. ✅ Checks if Ollama is installed
2. ✅ Sets the custom models directory
3. ✅ Starts Ollama if not running
4. ✅ Installs Python dependencies
5. ✅ Starts the Flask app

### Method 2: Manual Two-Terminal Setup
```bash
# Terminal 1: Start Ollama with custom directory
cd app
./start_ollama.sh

# Terminal 2: Start the app
cd app
python app.py
```

## ⚙️ How It Works

### Environment Variable
The app sets `OLLAMA_MODELS` environment variable:
```python
# In app.py
MODELS_DIR = os.path.join(DATA_DIR, 'models')
os.environ['OLLAMA_MODELS'] = MODELS_DIR
```

When Ollama starts with this variable set, it uses the custom directory instead of `~/.ollama/models/`.

### Verification
To verify Ollama is using the correct directory:

```bash
# Check Ollama environment
env | grep OLLAMA

# Should show:
# OLLAMA_MODELS=/home/yourusername/script_files/vovagpt/data/models

# Download a test model
ollama pull llama3.2

# Check if model is in custom directory
ls -la ~/script_files/vovagpt/data/models/
```

## 🐳 Docker Setup

When using Docker, the models directory is mapped:

```yaml
volumes:
  - ./data:/root/script_files/vovagpt/data
```

The Docker container sets:
```yaml
environment:
  - OLLAMA_MODELS=/root/script_files/vovagpt/data/models
```

**Note:** With Docker, Ollama must be running on the **host** system with the same models directory.

## 📊 Benefits of Custom Directory

| Benefit | Description |
|---------|-------------|
| 🗂️ **Organization** | All app data in one place |
| 💾 **Easy Backup** | Backup one directory: `~/script_files/vovagpt/` |
| 🚀 **Portability** | Move entire app with data and models |
| 🔒 **Isolation** | Separate from system Ollama models |
| 🧹 **Easy Cleanup** | Delete one directory to remove everything |

## 🛠️ Troubleshooting

### Models Download to Wrong Location

**Problem:** Models still downloading to `~/.ollama/models/`

**Solution:** Restart Ollama with the custom directory:
```bash
# Kill existing Ollama
pkill ollama

# Start with custom directory
OLLAMA_MODELS="$HOME/script_files/vovagpt/data/models" ollama serve
```

### Can't Find Downloaded Models

**Problem:** App says "No models available"

**Solution:** 
1. Check Ollama is using custom directory:
   ```bash
   env | grep OLLAMA_MODELS
   ```

2. Check models in directory:
   ```bash
   ls -la ~/script_files/vovagpt/data/models/
   ```

3. Restart both Ollama and the app

### Disk Space Issues

**Problem:** Need to check model sizes

**Solution:**
```bash
# Check total size of models directory
du -sh ~/script_files/vovagpt/data/models/

# Check individual model sizes
du -sh ~/script_files/vovagpt/data/models/*
```

### Moving Existing Models

**Problem:** Already have models in `~/.ollama/models/`

**Solution:**
```bash
# Copy existing models to custom directory
cp -r ~/.ollama/models/* ~/script_files/vovagpt/data/models/

# Or move them
mv ~/.ollama/models/* ~/script_files/vovagpt/data/models/
```

## 📝 Quick Commands Reference

```bash
# Start Ollama with custom directory
./start_ollama.sh

# Or manually
OLLAMA_MODELS="$HOME/script_files/vovagpt/data/models" ollama serve

# Check models location
echo $OLLAMA_MODELS

# List models in custom directory
ls ~/script_files/vovagpt/data/models/

# Check disk usage
du -sh ~/script_files/vovagpt/data/models/

# Backup everything (data + models)
tar -czf vovagpt_backup.tar.gz ~/script_files/vovagpt/
```

## 🔄 Switching Back to Default Location

If you want to use the default Ollama directory:

1. **Remove from app.py:**
   ```python
   # Comment out or remove this line:
   # os.environ['OLLAMA_MODELS'] = MODELS_DIR
   ```

2. **Start Ollama normally:**
   ```bash
   ollama serve
   ```

3. Models will use default: `~/.ollama/models/`

## 📦 File Structure Summary

```
~/script_files/vovagpt/
├── data/
│   ├── users.json              # User accounts
│   ├── chats.json              # Conversations
│   └── models/                 # AI Models (CUSTOM)
│       ├── manifests/
│       │   └── registry.ollama.ai/
│       │       └── library/
│       │           ├── llama3.2/
│       │           ├── qwen2.5/
│       │           └── ...
│       └── blobs/
│           └── sha256-xxxxx    # Model files
```

---

**Your models are now stored in `~/script_files/vovagpt/data/models/` for better organization!** 📁

