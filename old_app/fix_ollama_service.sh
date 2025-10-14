#!/usr/bin/env bash
# Quick fix for ollama service $HOME issue

echo "[INFO] Fixing ollama.service to include HOME environment variable..."

sudo tee /etc/systemd/system/ollama.service > /dev/null <<EOF
[Unit]
Description=Ollama Service
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/ollama serve
User=$USER
Environment=OLLAMA_MODELS=/var/lib/ollama
Environment=HOME=$HOME
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

echo "[INFO] Fixing /var/lib/ollama permissions..."
sudo chown -R $USER:$USER /var/lib/ollama
sudo chmod -R 755 /var/lib/ollama

echo "[INFO] Reloading systemd and restarting ollama..."
sudo systemctl daemon-reload
sudo systemctl restart ollama
sleep 2

echo "[INFO] Checking service status..."
sudo systemctl status ollama --no-pager

echo ""
echo "[DONE] Service fixed! You can now use option 6 to launch Ollama."

