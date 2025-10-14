#!/bin/bash

# Chat AI - Quick Start Script

echo "🤖 Chat AI - Starting application..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔄 Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "📥 Installing dependencies..."
pip install -q -r requirements.txt

# Check for .env file
if [ ! -f ".env" ]; then
    echo "⚠️  Warning: .env file not found!"
    echo "Please set your API keys as environment variables:"
    echo "  export OPENAI_API_KEY='your-key-here'"
    echo "  export ANTHROPIC_API_KEY='your-key-here'"
    echo ""
fi

# Run the application
echo "🚀 Starting Chat AI on http://localhost:5000"
echo "Press Ctrl+C to stop"
echo ""
python app.py

