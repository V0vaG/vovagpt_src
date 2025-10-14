# 🚀 Quick Start Guide - Chat AI with Ollama

## 📥 Installation (One-time)

### Step 1: Install Ollama
```bash
# Linux
curl -fsSL https://ollama.com/install.sh | sh

# macOS
brew install ollama
```

### Step 2: Install Python Dependencies
```bash
cd app
pip install -r requirements.txt
```

## 🏃 Running the App

### Easiest Way - Use Start Script (Recommended):
```bash
cd app
./start.sh
```

This automatically:
- Sets up custom models directory: `~/script_files/vovagpt/data/models/`
- Starts Ollama if needed
- Starts the Flask app

### Manual Way:
```bash
# Terminal 1: Start Ollama with custom models directory
cd app
./start_ollama.sh

# Terminal 2: Start App
cd app
python app.py
```

Then open: **http://localhost:5000**

> 💡 **Note:** Models are stored in `~/script_files/vovagpt/data/models/` instead of the default Ollama location. See [CUSTOM_MODELS_DIR.md](CUSTOM_MODELS_DIR.md) for details.

## 📋 First Time Setup

1. **Register Root User** (admin account)
2. **Download a Model**:
   - Go to Dashboard
   - Scroll to "Available Models"
   - Click "Download" on any model (recommended: llama3.2:latest - 2GB)
   - Wait for download to complete
3. **Create First Chat**:
   - Click "+ New Chat"
   - Select your downloaded model
   - Start chatting!

## 🎯 Common Tasks

### Download a Model
Dashboard → "Available Models" → Click "Download" → Wait for progress bar

### Delete a Model
Dashboard → "Downloaded Models" → Click "Delete" on model

### Create New Chat
Dashboard → "+ New Chat" → Choose model → Create

### Change Default Model
Click "Settings" → Select model → Save

## 🛠️ Troubleshooting

### App won't start?
```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# If not, start it
ollama serve
```

### Can't download models?
```bash
# Restart Ollama
pkill ollama
ollama serve
```

### Models not showing in chat?
- Refresh the browser page
- Make sure model download completed 100%

## 💡 Pro Tips

- **Start small**: Download llama3.2 (2GB) first
- **Storage**: Each model takes 2-40GB disk space
- **Performance**: Close other apps for faster responses
- **RAM**: 8GB+ recommended for smooth operation

## 📱 Access from Other Devices

1. Find your computer's IP:
   ```bash
   hostname -I | awk '{print $1}'
   ```

2. Access from phone/tablet:
   ```
   http://YOUR_IP:5000
   ```

## 🔧 Advanced

### Custom Ollama Host
```bash
export OLLAMA_HOST=http://192.168.1.100:11434
python app.py
```

### Docker Deployment
```bash
cd app
docker-compose up -d
```

### Check Ollama Models
```bash
ollama list              # Show downloaded models
ollama pull llama3.2     # Download model manually
ollama rm llama3.2       # Remove model manually
```

---

**Need more help?** See `OLLAMA_SETUP.md` for detailed documentation.

