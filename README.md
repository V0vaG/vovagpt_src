# 🤖 Chat AI with Ollama - Offline AI Chat Application

A beautiful, privacy-focused chat application powered by **Ollama** - run powerful AI models completely offline on your local machine!

![Version](https://img.shields.io/badge/version-2.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Python](https://img.shields.io/badge/python-3.7+-brightgreen)

## ✨ Features

- 🔒 **100% Private & Offline** - All AI processing happens locally, no data sent to cloud
- 📥 **Easy Model Management** - Download, use, and delete AI models from the dashboard
- 📁 **Custom Models Directory** - Models stored in `~/script_files/vovagpt/data/models/` for better organization
- 💬 **Multiple Chats** - Create and manage unlimited conversations
- 👥 **User System** - Root admin can create and manage multiple users
- 🎨 **Beautiful UI** - Modern, ChatGPT-like interface
- 📊 **Real-time Progress** - Watch model downloads with live progress bars
- 🚀 **Fast & Responsive** - Local processing with no network latency
- 🔄 **Model Switching** - Use different models for different chats

## 🎯 Quick Start

### 1. Install Ollama
```bash
# Linux
curl -fsSL https://ollama.com/install.sh | sh

# macOS
brew install ollama
```

### 2. Install Dependencies
```bash
cd app
pip install -r requirements.txt
```

### 3. Run the App
```bash
# Easiest way - automated start script
./start.sh

# Or manually
ollama serve          # Terminal 1
python app.py         # Terminal 2
```

### 4. Access & Setup
1. Open browser: **http://localhost:5000**
2. Register root user (admin)
3. Download your first AI model
4. Create a chat and start talking!

## 📦 Available Models

Popular models included (download from dashboard):

| Model | Size | Best For |
|-------|------|----------|
| **llama3.2** | 2GB | General use, fast |
| **qwen2.5** | 4.7GB | Coding, multilingual |
| **deepseek-r1** | 4.7GB | Reasoning tasks |
| **mistral** | 4.1GB | Balanced performance |
| **phi4** | 7.9GB | Compact but powerful |
| **codellama** | 3.8GB | Code generation |

## 📸 Screenshots

### Dashboard - Model Management
- View downloaded models
- Download new models with progress
- Manage your chats

### Chat Interface
- Clean, modern design
- Real-time responses
- Conversation history

### Settings
- Choose default model
- Manage preferences

## 🏗️ Architecture

```
Browser (UI) 
    ↕️
Flask App (Backend)
    ↕️
Ollama (AI Server)
    ↕️
Local Models (Storage)
```

**Tech Stack:**
- **Frontend**: HTML, CSS, JavaScript (vanilla)
- **Backend**: Flask, Python
- **AI**: Ollama (local models)
- **Storage**: JSON files (portable)

## 📚 Documentation

- **[Quick Start Guide](QUICK_START.md)** - Get up and running in 5 minutes
- **[Setup Documentation](OLLAMA_SETUP.md)** - Detailed installation and configuration
- **[Custom Models Directory](CUSTOM_MODELS_DIR.md)** - How models are stored in custom location
- **[Migration Summary](MIGRATION_SUMMARY.md)** - What changed from cloud APIs to Ollama
- **[Architecture](ARCHITECTURE.md)** - Technical architecture and design patterns

## 🔧 Configuration

### Environment Variables
```bash
# Optional - defaults shown
export OLLAMA_HOST=http://localhost:11434
export SECRET_KEY=your-secret-key-here
export VERSION=2.0.0
```

### Docker Deployment
```bash
cd app
docker-compose up -d
```

## 🛠️ Troubleshooting

### Common Issues

**Q: Models won't download?**
```bash
# Ensure Ollama is running
ollama serve
```

**Q: Chat errors?**
```bash
# Verify model is downloaded
ollama list
```

**Q: Can't connect?**
```bash
# Check Ollama is accessible
curl http://localhost:11434/api/tags
```

See [OLLAMA_SETUP.md](OLLAMA_SETUP.md) for detailed troubleshooting.

## 💡 Usage Tips

1. **Start Small**: Download llama3.2 (2GB) first for quick testing
2. **Storage**: Ensure sufficient disk space (models: 2-40GB each)
3. **Performance**: 8GB+ RAM recommended, GPU optional but helpful
4. **Offline**: After models downloaded, works 100% offline

## 🌟 Key Benefits

| Feature | Cloud APIs | Ollama (This App) |
|---------|-----------|-------------------|
| **Privacy** | ❌ Data sent to servers | ✅ 100% local |
| **Cost** | 💰 Pay per use | ✅ Free forever |
| **Offline** | ❌ Internet required | ✅ Works offline |
| **Speed** | ⏱️ Network dependent | ⚡ Local speed |
| **Control** | ❌ Limited | ✅ Full control |

## 📁 Project Structure

```
vovagpt_src/
├── app/
│   ├── app.py                 # Main application
│   ├── requirements.txt       # Dependencies
│   ├── start.sh              # Quick start script
│   ├── docker-compose.yml    # Docker config
│   └── templates/            # HTML templates
│       ├── dashboard.html    # Model management
│       ├── chat.html         # Chat interface
│       └── settings.html     # User settings
│
├── QUICK_START.md           # Quick start guide
├── OLLAMA_SETUP.md          # Detailed setup
├── MIGRATION_SUMMARY.md     # Migration notes
├── ARCHITECTURE.md          # Technical docs
└── README.md                # This file
```

## 🤝 Contributing

This is a personal/educational project. Feel free to:
- Report issues
- Suggest features
- Fork and modify for your needs

## 📄 License

This project is provided as-is for personal and educational use.

## 🙏 Credits

- **Ollama** - Local AI model server
- **Flask** - Web framework
- **Open source AI models** - Llama, Qwen, DeepSeek, Mistral, etc.

## 📞 Support

- **Ollama Issues**: [ollama.com](https://ollama.com) | [GitHub](https://github.com/ollama/ollama)
- **App Issues**: Check [OLLAMA_SETUP.md](OLLAMA_SETUP.md) troubleshooting section

---

<div align="center">

### ⭐ Enjoy your private, offline AI chat experience! ⭐

**Made with ❤️ for privacy-conscious AI users**

[Quick Start](QUICK_START.md) • [Documentation](OLLAMA_SETUP.md) • [Architecture](ARCHITECTURE.md)

</div>

