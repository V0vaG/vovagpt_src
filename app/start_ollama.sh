#!/bin/bash

# Start Ollama with custom models directory
# This ensures models are stored in ~/script_files/vovagpt/data/models

MODELS_DIR="$HOME/script_files/vovagpt/data/models"

# Create directory if it doesn't exist
mkdir -p "$MODELS_DIR"

echo "🚀 Starting Ollama with custom models directory"
echo "📁 Models will be stored in: $MODELS_DIR"
echo ""

# Kill any existing Ollama process
pkill ollama 2>/dev/null || true
sleep 1

# Export and start Ollama
export OLLAMA_MODELS="$MODELS_DIR"
export OLLAMA_HOST="0.0.0.0:11434"

echo "Starting Ollama server..."
exec ollama serve

