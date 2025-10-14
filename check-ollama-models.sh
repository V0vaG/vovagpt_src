#!/bin/bash

echo "🔍 Checking where Ollama is storing models"
echo "==========================================="
echo ""

# Check environment variable
echo "1. OLLAMA_MODELS environment variable:"
echo "   Current: $OLLAMA_MODELS"
echo ""

# Check default location
echo "2. Default Ollama location (~/.ollama/models/):"
ls -lah ~/.ollama/models/ 2>/dev/null || echo "   Not found"
echo ""

# Check custom location
echo "3. Custom location (~/script_files/vovagpt/data/models/):"
ls -lah ~/script_files/vovagpt/data/models/ 2>/dev/null || echo "   Not found"
echo ""

# Check if Ollama is running
echo "4. Ollama process:"
ps aux | grep ollama | grep -v grep || echo "   Not running"
echo ""

# Check Ollama models via API
echo "5. Models via Ollama API:"
curl -s http://localhost:11434/api/tags 2>/dev/null | jq '.' || echo "   Cannot connect to Ollama"
echo ""

# Find all model files
echo "6. Searching for Ollama model files on system:"
find ~ -type f -path "*ollama*" -name "*.bin" -o -path "*ollama*" -name "manifest.json" 2>/dev/null | head -10
echo ""

echo "================================"
echo "📋 Summary:"
echo "================================"
echo "Models are likely in one of these locations:"
echo "  1. ~/.ollama/models/ (default)"
echo "  2. ~/script_files/vovagpt/data/models/ (custom - if OLLAMA_MODELS is set)"
echo ""
echo "To use custom location:"
echo "  export OLLAMA_MODELS=~/script_files/vovagpt/data/models"
echo "  Then restart Ollama: pkill ollama && ollama serve"
echo ""

