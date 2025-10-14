#!/bin/bash

# Chat AI with Ollama - Quick Start Script

echo "🤖 Chat AI with Ollama - Setup"
echo "================================"
echo ""

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama is not installed!"
    echo ""
    echo "Please install Ollama first:"
    echo "  Linux:   curl -fsSL https://ollama.com/install.sh | sh"
    echo "  macOS:   brew install ollama"
    echo "  Windows: Download from ollama.com"
    echo ""
    exit 1
fi

echo "✅ Ollama is installed"

# Check if Ollama is running
if ! curl -s http://localhost:11434/api/tags &> /dev/null; then
    echo "⚠️  Ollama server is not running"
    echo "Starting Ollama server..."
    
    # Start Ollama in background
    ollama serve &> /dev/null &
    OLLAMA_PID=$!
    
    # Wait for Ollama to start
    sleep 3
    
    if curl -s http://localhost:11434/api/tags &> /dev/null; then
        echo "✅ Ollama server started (PID: $OLLAMA_PID)"
    else
        echo "❌ Failed to start Ollama server"
        echo "Please start it manually: ollama serve"
        exit 1
    fi
else
    echo "✅ Ollama server is running"
fi

echo ""

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed!"
    exit 1
fi

echo "✅ Python 3 is installed"

# Install dependencies if needed
if [ ! -d "venv" ]; then
    echo ""
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
    
    echo "📦 Installing dependencies..."
    pip install -r requirements.txt -q
    echo "✅ Dependencies installed"
else
    source venv/bin/activate
    echo "✅ Virtual environment activated"
fi

echo ""
echo "🚀 Starting Chat AI..."
echo ""
echo "Access the app at: http://localhost:5000"
echo ""
echo "To stop: Press Ctrl+C"
echo "================================"
echo ""

# Run the Flask app
python app.py

