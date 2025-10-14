# 🤖 Chat AI - ChatGPT-like Web Application

A modern, full-featured chat application with multiple AI model support, built with Flask. Similar in structure to your existing app but designed for conversational AI interactions.

## ✨ Features

- 🔐 **User Authentication** - Root and regular user roles with secure password hashing
- 💬 **Multiple Chat Sessions** - Create and manage multiple conversation threads
- 🤖 **Multi-Model Support** - Choose between OpenAI GPT and Anthropic Claude models
- 💾 **Conversation History** - All chats are saved and can be continued later
- 🎨 **Modern UI** - Beautiful, responsive interface inspired by ChatGPT
- ⚡ **Real-time Messaging** - Smooth, interactive chat experience
- 🐳 **Docker Ready** - Easy deployment with Docker and Docker Compose
- 🔒 **Secure** - Session management and password encryption

## 🚀 Quick Start

### Prerequisites

- Python 3.11+
- Docker & Docker Compose (optional, for containerized deployment)
- OpenAI API Key and/or Anthropic API Key

### Method 1: Local Development

1. **Clone and navigate to the project:**
   ```bash
   cd /home/vova/GIT/list_src/chat_app
   ```

2. **Create a virtual environment:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up environment variables:**
   ```bash
   export SECRET_KEY="your-secret-key-here"
   export OPENAI_API_KEY="your-openai-api-key"
   export ANTHROPIC_API_KEY="your-anthropic-api-key"
   ```

5. **Run the application:**
   ```bash
   python app.py
   ```

6. **Access the app:**
   Open your browser and go to `http://localhost:5000`

### Method 2: Docker Deployment

1. **Create environment file:**
   ```bash
   cat > .env << EOF
   SECRET_KEY=your-secret-key-here
   OPENAI_API_KEY=your-openai-api-key
   ANTHROPIC_API_KEY=your-anthropic-api-key
   VERSION=1.0.0
   EOF
   ```

2. **Build and run with Docker Compose:**
   ```bash
   docker-compose up -d
   ```

3. **Access the app:**
   - Direct access: `http://localhost:5000`
   - Via Nginx: `http://localhost`

4. **View logs:**
   ```bash
   docker-compose logs -f chat_app
   ```

5. **Stop the application:**
   ```bash
   docker-compose down
   ```

## 🔑 Getting API Keys

### OpenAI API Key
1. Visit [OpenAI Platform](https://platform.openai.com/api-keys)
2. Create an account or sign in
3. Navigate to API Keys section
4. Create a new API key
5. Copy and save it securely

### Anthropic API Key
1. Visit [Anthropic Console](https://console.anthropic.com/)
2. Create an account or sign in
3. Navigate to API Keys section
4. Create a new API key
5. Copy and save it securely

## 📁 Project Structure

```
chat_app/
├── app.py                 # Main Flask application
├── wsgi.py               # WSGI entry point
├── requirements.txt      # Python dependencies
├── Dockerfile           # Docker configuration
├── docker-compose.yml   # Docker Compose setup
├── .dockerignore        # Docker ignore patterns
├── templates/           # HTML templates
│   ├── login.html
│   ├── register_root.html
│   ├── register_user.html
│   ├── dashboard.html
│   ├── chat.html
│   ├── root_dashboard.html
│   └── settings.html
├── nginx/               # Nginx configuration
│   └── nginx.conf
└── data/               # Application data (created at runtime)
    ├── users.json
    └── chats.json
```

## 🎯 Usage Guide

### First Time Setup

1. **Register Root User:**
   - On first access, you'll be prompted to create a root administrator account
   - This account has full administrative privileges

2. **Create Regular Users:**
   - Root can create additional users via the Admin Dashboard
   - Or users can self-register at `/register_user`

### Creating Chats

1. Log in to your account
2. Click "New Chat" on the dashboard
3. Optionally name your chat
4. Select your preferred AI model
5. Start chatting!

### Managing Chats

- **View All Chats:** Dashboard shows all your chat sessions
- **Continue Chat:** Click "Open" on any chat card
- **Delete Chat:** Click "Delete" button (requires confirmation)
- **Clear History:** Use "Clear Chat" button in an active chat

### Changing Settings

1. Navigate to Settings from the navbar
2. Select your preferred default AI model
3. Save your preferences

## 🔧 Configuration

### Available Models

**OpenAI Models:**
- `gpt-4` - Most capable, best for complex tasks
- `gpt-3.5-turbo` - Fast and efficient, good for most tasks

**Anthropic Models:**
- `claude-3-opus-20240229` - Most capable Claude model
- `claude-3-sonnet-20240229` - Balanced performance
- `claude-3-haiku-20240307` - Fastest response times

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `SECRET_KEY` | Flask secret key for sessions | Yes |
| `OPENAI_API_KEY` | OpenAI API key | For GPT models |
| `ANTHROPIC_API_KEY` | Anthropic API key | For Claude models |
| `VERSION` | App version display | No |

## 🛠️ Production Deployment

### Using Nginx (Recommended)

1. **Update nginx.conf** with your domain:
   ```nginx
   server_name your-domain.com;
   ```

2. **Add SSL certificates:**
   - Place your certificates in `nginx/ssl/`
   - Uncomment HTTPS server block in nginx.conf

3. **Deploy:**
   ```bash
   docker-compose up -d
   ```

### Security Considerations

- ✅ Change default `SECRET_KEY` in production
- ✅ Use strong passwords for root account
- ✅ Enable HTTPS in production
- ✅ Keep API keys secure and never commit them to git
- ✅ Regularly update dependencies
- ✅ Set up proper backup for data directory

## 🐛 Troubleshooting

### API Key Errors
- Ensure API keys are correctly set in environment
- Verify API keys are valid and have sufficient credits
- Check which model you're trying to use

### Port Already in Use
```bash
# Change port in docker-compose.yml or stop conflicting service
sudo lsof -i :5000
```

### Data Not Persisting
- Ensure `data/` directory has write permissions
- Check Docker volume mounts in docker-compose.yml

## 📝 License

This project is provided as-is for personal or commercial use.

## 🤝 Contributing

Feel free to fork, modify, and improve this application!

## 📧 Support

For issues or questions:
1. Check the troubleshooting section
2. Review the application logs
3. Verify environment variables are set correctly

## 🎨 Customization

The app is designed to be easily customizable:

- **Styling:** Edit CSS in template files
- **Models:** Add new models in `app.py` `get_ai_response()` function
- **Features:** Extend functionality by adding new routes
- **UI:** Modify templates to match your brand

---

**Built with ❤️ using Flask, OpenAI, and Anthropic Claude**

