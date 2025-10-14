#!/bin/bash
echo "🚀 Starting Ollama..."
ollama serve > /tmp/ollama.log 2>&1 &
echo "⏳ Waiting for Ollama..."
sleep 5
echo "🌐 Starting Flask with 10min timeout..."
exec gunicorn -w 4 -b 0.0.0.0:5000 --timeout 600 --log-level info wsgi:app

