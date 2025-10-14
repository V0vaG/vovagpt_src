FROM python:3.11-slim

ARG VERSION
ENV VERSION=$VERSION

ARG B_NUM
ENV B_NUM=$B_NUM

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy Ollama binary directly (faster and more reliable)
COPY app/ollama /usr/local/bin/ollama
RUN chmod +x /usr/local/bin/ollama

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY . .

# Create data directory and ollama models directory
RUN mkdir -p /root/script_files/vovagpt/data
RUN mkdir -p /root/script_files/vovagpt/data/models

# Create simple startup script
RUN echo '#!/bin/bash\n\
ollama serve > /tmp/ollama.log 2>&1 &\n\
sleep 5\n\
gunicorn -w 4 -b 0.0.0.0:5000 --timeout 120 wsgi:app\n\
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
CMD ["./start.sh"]

