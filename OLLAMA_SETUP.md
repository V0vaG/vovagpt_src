# 🤖 Chat AI with Ollama - Offline AI Models

A powerful, privacy-focused chat application powered by **Ollama** - run AI models completely offline on your local machine!

## ✨ Features

- 🔒 **100% Private & Offline** - All AI processing happens locally
- 📥 **Easy Model Management** - Download and manage AI models through the dashboard
- 💬 **Multi-Chat Support** - Create and manage multiple conversations
- 👥 **User Management** - Root user can create and manage multiple users
- 🎨 **Beautiful UI** - Modern, ChatGPT-like interface
- 🚀 **Real-time Downloads** - See model download progress in real-time

## 📋 Prerequisites

### 1. Install Ollama

**Linux:**
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

**macOS:**
```bash
brew install ollama
```

**Windows:**
Download from [ollama.com](https://ollama.com/download)

### 2. Start Ollama Service

```bash
# Start Ollama server
ollama serve
```

The Ollama server will run on `http://localhost:11434`

## 🚀 Quick Start

### 1. Install Dependencies

```bash
cd app
pip install -r requirements.txt
```

### 2. Run the Application

```bash
# Development mode
python app.py

# Or with Gunicorn (production)
gunicorn -w 4 -b 0.0.0.0:5000 wsgi:app
```

### 3. Access the App

Open your browser to `http://localhost:5000`

### 4. First Time Setup

1. **Register Root User** - Create the admin account on first visit
2. **Download Models** - Go to dashboard and download your first AI model
3. **Create Chat** - Start chatting once a model is downloaded!

## 📦 Available Models

The app includes popular models like:

| Model | Size | Best For |
|-------|------|----------|
| **llama3.2:latest** | 2.0GB | General use, fast responses |
| **qwen2.5:latest** | 4.7GB | Multilingual, coding |
| **deepseek-r1:latest** | 4.7GB | Reasoning tasks |
| **mistral:latest** | 4.1GB | Fast and capable |
| **phi4:latest** | 7.9GB | Compact but powerful |
| **codellama:latest** | 3.8GB | Code generation |

## 💡 Usage Guide

### Downloading Models

1. Navigate to the **Dashboard**
2. Scroll to **"Available Models for Download"** section
3. Click **Download** on any model
4. Watch the real-time progress bar
5. Once complete, the model appears in **"Downloaded Models"**

### Creating Chats

1. Click **"+ New Chat"** on the dashboard
2. (Optional) Give your chat a name
3. Select a model from downloaded models
4. Click **"Create Chat"**
5. Start chatting!

### Managing Models

- **Delete Models**: Click the Delete button next to any downloaded model
- **View Model**: Each chat shows which model it's using in the navbar

### User Management (Root User Only)

1. Click **"Admin"** in the navbar
2. Create new users from the admin dashboard
3. Remove users as needed

## 🔧 Configuration

### Environment Variables

Create a `.env` file or set environment variables:

```bash
# Secret key for sessions (change in production!)
SECRET_KEY=your-secret-key-here

# Ollama host (default: http://localhost:11434)
OLLAMA_HOST=http://localhost:11434

# App version
VERSION=2.0.0
```

### Using Custom Ollama Host

If Ollama is running on a different host/port:

```bash
export OLLAMA_HOST=http://192.168.1.100:11434
python app.py
```

## 🐳 Docker Deployment

```bash
# Build and run with docker-compose
cd app
docker-compose up -d
```

The docker-compose setup includes:
- Flask app with Gunicorn
- Nginx reverse proxy
- Persistent data storage

## 🛠️ Troubleshooting

### "Failed to start download" Error

**Problem**: Cannot download models

**Solution**:
```bash
# Make sure Ollama is running
ollama serve

# Check if Ollama is accessible
curl http://localhost:11434/api/tags
```

### "Ollama error: Connection refused"

**Problem**: App can't connect to Ollama

**Solution**:
1. Verify Ollama is running: `ps aux | grep ollama`
2. Start Ollama service: `ollama serve`
3. Check firewall settings

### Models Not Showing

**Problem**: Downloaded models don't appear

**Solution**:
1. Refresh the page
2. Check Ollama has models: `ollama list`
3. Restart Ollama service

### Chat Response Errors

**Problem**: "Model response error" when chatting

**Solution**:
1. Ensure the model is fully downloaded
2. Verify model exists: `ollama list`
3. Try restarting Ollama: `ollama serve`

## 📁 Project Structure

```
app/
├── app.py                 # Main Flask application with Ollama integration
├── requirements.txt       # Python dependencies
├── wsgi.py               # WSGI entry point
├── docker-compose.yml    # Docker deployment config
├── Dockerfile            # Docker image definition
├── templates/            # HTML templates
│   ├── dashboard.html    # Main dashboard with model management
│   ├── chat.html         # Chat interface
│   ├── login.html        # Login page
│   ├── settings.html     # User settings
│   └── ...
└── nginx/                # Nginx configuration
    └── nginx.conf
```

## 🔒 Security Notes

- All data stored locally in `~/script_files/chat/data/`
- Change `SECRET_KEY` in production
- Models and chats are stored on your local machine
- No data sent to external servers (100% offline)

## 🎯 Tips for Best Experience

1. **Start Small**: Download a small model (llama3.2) first to test
2. **Storage**: Ensure you have enough disk space (models range from 2GB-40GB)
3. **Performance**: Larger models (70B) need powerful hardware
4. **RAM**: 8GB+ recommended for most models
5. **GPU**: Optional but significantly speeds up responses

## 🌟 Features in Detail

### Model Management
- Real-time download progress with percentage
- Easy model deletion to free up space
- Automatic model discovery
- Size and description for each model

### Chat Features
- Multiple simultaneous chats
- Each chat can use a different model
- Conversation history saved automatically
- Clean and delete chats anytime
- Model display in chat navbar

### User System
- Root user for administration
- Multiple regular users
- Per-user chat isolation
- Per-user model preferences

## 📝 Common Ollama Commands

```bash
# List downloaded models
ollama list

# Download a model manually
ollama pull llama3.2

# Remove a model manually
ollama rm llama3.2

# Show model info
ollama show llama3.2

# Test model
ollama run llama3.2 "Hello!"
```

## 🤝 Support

For issues with:
- **Ollama**: Visit [ollama.com](https://ollama.com) or [GitHub](https://github.com/ollama/ollama)
- **This App**: Check the troubleshooting section above

## 📄 License

This application is provided as-is for personal and educational use.

---

**Enjoy your private, offline AI chat experience!** 🚀

