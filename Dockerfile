FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy Ollama binary directly (faster and more reliable)
COPY app/ollama /usr/local/bin/ollama
RUN chmod +x /usr/local/bin/ollama

# Copy requirements and install Python dependencies
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ .

# Create data directory and ollama models directory
RUN mkdir -p /root/script_files/vovagpt/data
RUN mkdir -p /root/script_files/vovagpt/data/models

# Create simple startup script
RUN echo '#!/bin/bash\n\
echo "Starting Ollama..."\n\
export OLLAMA_HOST=0.0.0.0:11434\n\
export OLLAMA_MODELS=/root/script_files/vovagpt/data/models\n\
ollama serve &\n\
echo "Waiting for Ollama to start..."\n\
sleep 5\n\
echo "Starting Flask..."\n\
exec gunicorn -w 4 -b 0.0.0.0:5000 --timeout 120 wsgi:app\n\
' > /start.sh && chmod +x /start.sh

# Expose ports
EXPOSE 5000 11434

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV FLASK_APP=app.py
ENV OLLAMA_HOST=http://localhost:11434
ENV OLLAMA_MODELS=/root/script_files/vovagpt/data/models

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:5000/ || exit 1

# Run startup script
CMD ["/start.sh"]

