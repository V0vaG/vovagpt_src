#!/bin/bash

echo "🔧 Fixing Local Ollama Models Location"
echo "======================================"
echo ""

CUSTOM_DIR="$HOME/script_files/vovagpt/data/models"
DEFAULT_DIR="$HOME/.ollama"

# Step 1: Check current situation
echo "1️⃣ Checking current model locations..."
echo ""

if [ -d "$DEFAULT_DIR/models/manifests" ]; then
    MODEL_COUNT=$(find "$DEFAULT_DIR/models/manifests" -type f -name "*.json" 2>/dev/null | wc -l)
    echo "📦 Found $MODEL_COUNT model(s) in default location: $DEFAULT_DIR"
    echo "   Models:"
    find "$DEFAULT_DIR/models/manifests" -type f -name "*.json" 2>/dev/null | while read file; do
        echo "   - $(dirname $(dirname $file) | xargs basename)"
    done
else
    MODEL_COUNT=0
    echo "📦 No models in default location"
fi

echo ""

# Step 2: Stop Ollama
echo "2️⃣ Stopping Ollama..."
pkill ollama 2>/dev/null || true
sleep 2
echo "✅ Ollama stopped"
echo ""

# Step 3: Move models if they exist
if [ $MODEL_COUNT -gt 0 ]; then
    read -p "📦 Move $MODEL_COUNT model(s) to custom location? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📦 Moving models to $CUSTOM_DIR..."
        mkdir -p "$CUSTOM_DIR"
        
        # Move the entire .ollama directory content
        cp -r "$DEFAULT_DIR/"* "$CUSTOM_DIR/" 2>/dev/null || true
        
        echo "✅ Models copied to custom location"
        echo ""
        
        read -p "🗑️  Delete models from default location? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$DEFAULT_DIR"
            echo "✅ Default location cleaned"
        fi
    fi
else
    mkdir -p "$CUSTOM_DIR"
    echo "📁 Created custom models directory"
fi

echo ""

# Step 4: Start Ollama with custom directory
echo "3️⃣ Starting Ollama with custom models directory..."
export OLLAMA_MODELS="$CUSTOM_DIR"
export OLLAMA_HOST="0.0.0.0:11434"

cd $(dirname $0)/app
nohup ollama serve > /tmp/ollama.log 2>&1 &
OLLAMA_PID=$!

echo "✅ Ollama started (PID: $OLLAMA_PID)"
echo "   Models directory: $CUSTOM_DIR"
echo "   Log file: /tmp/ollama.log"
echo ""

# Step 5: Wait and verify
echo "4️⃣ Waiting for Ollama to start..."
sleep 3

curl -s http://localhost:11434/api/tags > /dev/null 2>&1 && \
    echo "✅ Ollama is responding" || \
    echo "❌ Ollama not responding - check /tmp/ollama.log"

echo ""

# Step 6: Show models
echo "5️⃣ Current models:"
curl -s http://localhost:11434/api/tags 2>/dev/null | jq -r '.models[].name' 2>/dev/null || echo "   No models found"

echo ""
echo "================================"
echo "✅ Done!"
echo "================================"
echo ""
echo "📋 Next steps:"
echo "1. Start Flask app: cd app && python app.py"
echo "2. Access: http://localhost:5000"
echo "3. Download models - they will save to: $CUSTOM_DIR"
echo ""
echo "📁 Models location: $CUSTOM_DIR"
echo "📝 Ollama log: /tmp/ollama.log"
echo ""

