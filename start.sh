#!/bin/bash
ollama serve > /tmp/ollama.log 2>&1 &
sleep 5
gunicorn -w 4 -b 0.0.0.0:5000 --timeout 120 wsgi:app

