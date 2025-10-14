#!/bin/bash

echo "📦 Moving Ollama Models to Custom Directory"
echo "==========================================="
echo ""

SYSTEM_DIR="/var/lib/ollama"
CUSTOM_DIR="$HOME/script_files/vovagpt/data/models"

# Check if models exist
if [ ! -d "$SYSTEM_DIR" ]; then
    echo "❌ No models found in $SYSTEM_DIR"
    exit 1
fi

echo "📊 Current situation:"
echo "  System location: $SYSTEM_DIR (systemd default)"
echo "  Custom location: $CUSTOM_DIR (your desired location)"
echo ""

# Show current models
echo "📦 Current models in system location:"
curl -s http://localhost:11434/api/tags | jq -r '.models[].name'
echo ""

# Step 1: Copy models
echo "1️⃣ Copying models to custom directory..."
mkdir -p "$CUSTOM_DIR"
sudo cp -r "$SYSTEM_DIR/"* "$CUSTOM_DIR/" 2>/dev/null || {
    echo "❌ Failed to copy. Trying with sudo..."
    sudo cp -r "$SYSTEM_DIR/"* "$CUSTOM_DIR/"
}
sudo chown -R $USER:$USER "$CUSTOM_DIR"
echo "✅ Models copied"
echo ""

# Step 2: Stop systemd Ollama
echo "2️⃣ Stopping systemd Ollama service..."
sudo systemctl stop ollama
sudo systemctl disable ollama
echo "✅ Systemd service stopped and disabled"
echo ""

# Step 3: Start Ollama with custom directory
echo "3️⃣ Starting Ollama with custom directory..."
export OLLAMA_MODELS="$CUSTOM_DIR"
export OLLAMA_HOST="0.0.0.0:11434"

nohup ollama serve > /tmp/ollama-custom.log 2>&1 &
OLLAMA_PID=$!
echo "✅ Ollama started with custom directory (PID: $OLLAMA_PID)"
echo "   Models: $CUSTOM_DIR"
echo "   Log: /tmp/ollama-custom.log"
echo ""

# Step 4: Wait and verify
echo "4️⃣ Waiting for Ollama to start..."
sleep 5

echo ""
echo "5️⃣ Verifying models..."
curl -s http://localhost:11434/api/tags | jq -r '.models[].name' && echo "✅ Models accessible!" || echo "❌ Error accessing models"

echo ""
echo "================================"
echo "✅ Done!"
echo "================================"
echo ""
echo "📁 Models are now in: $CUSTOM_DIR"
echo "📝 Ollama log: /tmp/ollama-custom.log"
echo ""
echo "🚀 To make this permanent, add to ~/.bashrc or ~/.profile:"
echo "   export OLLAMA_MODELS=$CUSTOM_DIR"
echo "   export OLLAMA_HOST=0.0.0.0:11434"
echo ""
echo "📋 To start Ollama on boot with custom directory:"
echo "   1. Create systemd override: sudo systemctl edit ollama"
echo "   2. Add: [Service]"
echo "           Environment=\"OLLAMA_MODELS=$CUSTOM_DIR\""
echo "   3. Enable: sudo systemctl enable ollama"
echo ""

