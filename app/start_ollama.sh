#!/bin/bash

# Start Ollama with custom models directory
# This ensures models are stored in ~/script_files/vovagpt/data/models

MODELS_DIR="$HOME/script_files/vovagpt/data/models"

# Create directory if it doesn't exist
mkdir -p "$MODELS_DIR"

echo "🚀 Starting Ollama with custom models directory"
echo "📁 Models will be stored in: $MODELS_DIR"
echo ""

# Export and start Ollama
export OLLAMA_MODELS="$MODELS_DIR"
exec ollama serve

