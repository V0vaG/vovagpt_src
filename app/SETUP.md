# 🚀 Quick Setup Guide

## Option 1: Fastest Start (using run.sh)

```bash
cd /home/vova/GIT/list_src/chat_app
./run.sh
```

This script will:
- Create a virtual environment
- Install dependencies
- Start the application

## Option 2: Manual Setup

### Step 1: Install Dependencies
```bash
cd /home/vova/GIT/list_src/chat_app
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Step 2: Set API Keys
```bash
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="sk-ant-..."
export SECRET_KEY="your-random-secret-key"
```

### Step 3: Run
```bash
python app.py
```

### Step 4: Access
Open browser: http://localhost:5000

## Option 3: Docker (Production)

```bash
# Create .env file first with your API keys
docker-compose up -d
```

Access: http://localhost

## First Login

1. You'll be asked to create a root account
2. Choose a username and strong password
3. Log in with your credentials
4. Click "New Chat" to start!

## Tips

- **Multiple Models**: You can use GPT-4, GPT-3.5, or Claude models
- **Save Chats**: All conversations are automatically saved
- **Settings**: Change your default model in Settings
- **Admin**: Root users can access Admin Dashboard to manage users

## Need Help?

Check README.md for detailed documentation.

