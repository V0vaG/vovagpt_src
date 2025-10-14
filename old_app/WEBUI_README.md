# 🌐 Ollama Web UI - ChatGPT-like Interface

A modern, ChatGPT-style web interface for your local Ollama AI models.

## ✨ Features

- **🎨 Beautiful ChatGPT-like Interface** - Clean, modern design with streaming responses
- **💬 Chat History** - Keep track of your conversations
- **⚙️ Customizable Settings** - Adjust temperature, max tokens, and system prompts
- **🔄 Model Switching** - Easily switch between different AI models
- **📱 Responsive Design** - Works on desktop, tablet, and mobile
- **🚀 Two Modes**:
  - **System Mode**: Use Ollama installed on your system
  - **USB Mode**: Run completely portable from USB drive

## 🎯 Quick Start

### Option 1: From the Main Script

```bash
bash ollama.sh
# Select option 7: Launch Web UI (ChatGPT-like interface)
```

### Option 2: Direct Launch

```bash
# Install dependencies (only once)
pip3 install -r requirements.txt

# System mode
python3 ollama_webui.py

# USB mode
python3 ollama_webui.py --models-dir /path/to/models --ollama-bin /path/to/ollama
```

## 📦 Requirements

- Python 3.7+
- `gradio` >= 4.0.0
- `requests` >= 2.31.0

Install with:
```bash
pip3 install gradio requests
# OR
pip3 install -r requirements.txt
```

## 🎮 Usage

### Basic Usage

1. **Launch the Web UI**:
   ```bash
   python3 ollama_webui.py
   ```

2. **Open your browser** to: `http://localhost:7860`

3. **Select a model** from the dropdown

4. **Start chatting!** 🎉

### Advanced Options

```bash
# Custom port
python3 ollama_webui.py --port 8080

# Create public share link (for remote access)
python3 ollama_webui.py --share

# USB/Portable mode
python3 ollama_webui.py --models-dir ./models --ollama-bin ./bin/ollama
```

## ⚙️ Settings Panel

- **Select Model**: Choose from available models
- **System Prompt**: Define the AI's behavior and personality
- **Temperature**: Control creativity (0.0 = focused, 2.0 = very creative)
- **Max Tokens**: Set maximum response length (128-4096)

### Example System Prompts

**Helpful Assistant:**
```
You are a helpful AI assistant. Provide clear, accurate, and concise answers.
```

**Code Expert:**
```
You are an expert programmer. Provide code examples with explanations. Use best practices and consider edge cases.
```

**Creative Writer:**
```
You are a creative writer. Craft engaging stories with vivid descriptions and compelling narratives.
```

## 🚀 Features in Detail

### Chat Interface
- **Real-time Streaming**: See responses as they're generated
- **Message History**: Scroll through past conversations
- **Clear Chat**: Start fresh with one click
- **Regenerate**: Try different responses for the same prompt

### Model Management
- **Refresh Models**: Update available models list
- **Model Info**: View detailed information about selected model
- **Hot Switching**: Change models mid-conversation

### Customization
- **System Prompts**: Set custom behavior for each conversation
- **Temperature Control**: Fine-tune response creativity
- **Token Limits**: Control response length

## 🛠️ Troubleshooting

### Web UI won't start

**Problem**: `ModuleNotFoundError: No module named 'gradio'`

**Solution**:
```bash
pip3 install --user gradio requests
```

### No models showing

**Problem**: Dropdown shows "No models found"

**Solution**:
1. Make sure Ollama is running (`ollama serve`)
2. Download at least one model (`ollama pull llama3.1`)
3. Click "Refresh Models" button

### Connection refused

**Problem**: Can't connect to Ollama server

**Solution**:
- **System mode**: Start Ollama service: `sudo systemctl start ollama`
- **USB mode**: The script handles server startup automatically

### Port already in use

**Problem**: `Address already in use`

**Solution**:
```bash
# Use a different port
python3 ollama_webui.py --port 8080
```

## 📱 Mobile Access

To access from your phone/tablet on the same network:

1. Find your computer's IP address:
   ```bash
   hostname -I | awk '{print $1}'
   ```

2. Launch with share option:
   ```bash
   python3 ollama_webui.py --share
   ```

3. Use the Gradio public URL provided (looks like: `https://xxxxx.gradio.live`)

## 🔒 Privacy

- **100% Local**: All processing happens on your machine
- **No Data Sent**: Nothing is sent to external servers (unless using `--share`)
- **Offline Capable**: Works completely offline (except `--share` mode)

## 💡 Tips

1. **Faster Responses**: Use smaller models (3B-7B) for quick responses
2. **Better Quality**: Use larger models (8B-12B+) for complex tasks
3. **Save System Prompts**: Keep a text file with your favorite prompts
4. **Temperature Guide**:
   - 0.0-0.3: Focused, factual responses
   - 0.5-0.7: Balanced creativity
   - 0.8-1.5: Creative writing
   - 1.5-2.0: Very experimental

## 🎨 Interface Preview

The interface includes:
- **Left Side**: Chat window with message history
- **Right Side**: Settings panel with model selection and parameters
- **Bottom**: Message input with send button
- **Top**: Model information and status

## 🤝 Comparison with Other Tools

| Feature | Ollama Web UI | ChatGPT | Ollama CLI |
|---------|---------------|---------|------------|
| **Local/Private** | ✅ Yes | ❌ No | ✅ Yes |
| **Free** | ✅ Yes | ⚠️ Limited | ✅ Yes |
| **Offline** | ✅ Yes | ❌ No | ✅ Yes |
| **Web Interface** | ✅ Yes | ✅ Yes | ❌ No |
| **Portable (USB)** | ✅ Yes | ❌ No | ⚠️ Partial |
| **Model Switching** | ✅ Easy | ❌ No | ✅ Manual |
| **Chat History** | ✅ Yes | ✅ Yes | ❌ No |

## 📄 License

This tool is part of the Offline AI USB Toolkit and is provided as-is for personal and educational use.

---

**Enjoy your private, local ChatGPT experience!** 🎉

