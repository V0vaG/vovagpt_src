# 🏗️ Architecture - Chat AI with Ollama

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        User's Browser                        │
│  ┌────────────┐  ┌──────────────┐  ┌──────────────────┐    │
│  │ Dashboard  │  │  Chat View   │  │   Settings       │    │
│  │            │  │              │  │                  │    │
│  │ • Models   │  │ • Messages   │  │ • Preferences    │    │
│  │ • Download │  │ • Send/Recv  │  │ • Model Select   │    │
│  │ • Delete   │  │ • History    │  │                  │    │
│  └────────────┘  └──────────────┘  └──────────────────┘    │
└────────────┬────────────────────────────────────────────────┘
             │ HTTP/SSE
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    Flask Application                         │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    Routes & Logic                    │   │
│  │  • /dashboard    - Model management UI              │   │
│  │  • /chat/<id>    - Chat interface                   │   │
│  │  • /model/download/<name> - Stream download (SSE)   │   │
│  │  • /model/delete/<name>   - Remove model            │   │
│  │  • /models/list  - Get available models             │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Ollama Integration Layer                │   │
│  │  • get_ollama_models()          - List installed    │   │
│  │  • get_available_ollama_models() - List available   │   │
│  │  • download_ollama_model()      - Pull with progress│   │
│  │  • delete_ollama_model()        - Remove model      │   │
│  │  • get_ai_response()            - Chat with model   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                Data Persistence                      │   │
│  │  ~/script_files/chat/data/                          │   │
│  │    ├── users.json  (User accounts)                  │   │
│  │    └── chats.json  (Chat history)                   │   │
│  └─────────────────────────────────────────────────────┘   │
└────────────┬────────────────────────────────────────────────┘
             │ HTTP REST API
             ▼
┌─────────────────────────────────────────────────────────────┐
│                    Ollama Server                             │
│                  (localhost:11434)                           │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                  Ollama API                          │   │
│  │  • /api/tags     - List models                      │   │
│  │  • /api/pull     - Download model (streaming)       │   │
│  │  • /api/delete   - Remove model                     │   │
│  │  • /api/chat     - Chat completion                  │   │
│  │  • /api/show     - Model details                    │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Local AI Models Storage                 │   │
│  │  ~/.ollama/models/                                   │   │
│  │    ├── llama3.2/                                     │   │
│  │    ├── qwen2.5/                                      │   │
│  │    ├── deepseek-r1/                                  │   │
│  │    └── ... (other models)                            │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 Data Flow

### 1. Model Download Flow
```
User clicks "Download" 
    ↓
JavaScript initiates EventSource connection
    ↓
Flask route: /model/download/<name>
    ↓
Calls: download_ollama_model(name)
    ↓
HTTP POST to Ollama: /api/pull (streaming)
    ↓
Server-Sent Events stream progress to browser
    ↓
Progress bar updates in real-time
    ↓
On complete: Page reloads, model appears in "Downloaded"
```

### 2. Chat Message Flow
```
User types message and clicks Send
    ↓
JavaScript: POST /chat/<id>/message
    ↓
Flask: Receives message, adds to chat history
    ↓
Prepares messages array for Ollama
    ↓
Calls: get_ai_response(messages, model)
    ↓
HTTP POST to Ollama: /api/chat
    ↓
Ollama processes with local AI model
    ↓
Response returned to Flask
    ↓
Saved to chat history (chats.json)
    ↓
JSON response to browser
    ↓
Message displayed in chat UI
```

### 3. Model Management Flow
```
Dashboard loads
    ↓
Flask calls: get_ollama_models()
    ↓
HTTP GET to Ollama: /api/tags
    ↓
Returns list of installed models
    ↓
Also gets: get_available_ollama_models()
    ↓
Compares lists to show only uninstalled models
    ↓
Renders dashboard with both lists
```

## 🗂️ File Structure

```
app/
├── app.py                          # Main Flask application
│   ├── Ollama Functions            # Model management
│   ├── Routes                      # HTTP endpoints
│   ├── User Management            # Auth & sessions
│   └── Chat Logic                 # Conversation handling
│
├── templates/
│   ├── dashboard.html             # Model management UI
│   │   ├── Downloaded Models      # Grid of installed models
│   │   ├── Available Models       # Grid with download buttons
│   │   └── Chat List              # User's conversations
│   │
│   ├── chat.html                  # Chat interface
│   │   ├── Message Display        # Conversation view
│   │   ├── Input Area             # Send messages
│   │   └── Model Display          # Shows active model
│   │
│   ├── settings.html              # User preferences
│   └── login.html / register*.html # Authentication
│
├── requirements.txt               # Python dependencies
├── docker-compose.yml            # Container orchestration
├── Dockerfile                    # Container image
└── start.sh                      # Quick start script
```

## 🔐 Security Architecture

```
Session Management:
├── Flask sessions (server-side)
├── Secure password hashing (pbkdf2:sha256)
└── User isolation (chats separated by user)

Data Privacy:
├── All data stored locally
├── No external API calls
├── Ollama runs on localhost
└── Optional: Docker network isolation
```

## 🌊 Request/Response Patterns

### Standard HTTP Requests
```
Browser → Flask → Ollama → Flask → Browser
  [Request] → [Process] → [Response]
```

### Server-Sent Events (Model Download)
```
Browser ←─────────── Flask ←────────── Ollama
        [Event Stream with progress updates]
```

### WebSocket Alternative (Not Used)
```
We use SSE instead of WebSocket because:
✅ Simpler implementation
✅ Built-in browser support (EventSource)
✅ One-way communication sufficient
✅ Automatic reconnection
```

## 🔧 Technology Stack

### Frontend
- **HTML5** - Structure
- **CSS3** - Styling (no frameworks, custom design)
- **Vanilla JavaScript** - Interactivity
- **EventSource API** - Real-time updates
- **Fetch API** - AJAX requests

### Backend
- **Flask** - Web framework
- **Python 3.7+** - Programming language
- **Werkzeug** - WSGI utilities & security
- **Requests** - HTTP client for Ollama API

### AI Layer
- **Ollama** - Local AI model server
- **REST API** - Communication protocol
- **Streaming** - Real-time responses

### Data Storage
- **JSON Files** - User data & chat history
- **File System** - Local storage
- **No Database** - Simple, portable

### Deployment
- **Gunicorn** - WSGI HTTP Server
- **Docker** - Containerization
- **Nginx** - Reverse proxy (optional)

## 🎯 Design Patterns

### 1. **Model-View-Controller (MVC)**
- **Model**: JSON files (users.json, chats.json)
- **View**: HTML templates (Jinja2)
- **Controller**: Flask routes (app.py)

### 2. **Repository Pattern**
```python
def load_users() / save_users()
def load_chats() / save_chats()
```

### 3. **Decorator Pattern**
```python
@login_required
def protected_route():
    pass
```

### 4. **Streaming Pattern**
```python
def generate():
    for chunk in stream:
        yield chunk
return Response(generate(), mimetype='text/event-stream')
```

## 📊 Performance Considerations

### Optimizations
- ✅ Async model downloads (non-blocking)
- ✅ Streaming responses (progressive loading)
- ✅ Client-side state management
- ✅ Minimal database queries (JSON files)
- ✅ Local processing (no network latency)

### Scalability
- **Users**: Suitable for 1-50 users
- **Chats**: Handles 1000s of conversations
- **Models**: Limited by disk space
- **Concurrent**: Flask handles multiple requests

## 🔄 State Management

### Server State
```
Session:
├── user_id (username)
└── is_root (boolean)

Files:
├── users.json (user accounts)
└── chats.json (conversations)
```

### Client State
```
JavaScript Variables:
├── Current chat ID
├── Model selection
├── Download progress
└── UI state (modals, etc.)
```

## 🚀 Deployment Options

### Option 1: Standalone
```
Ollama (localhost:11434) ← Flask (localhost:5000) ← Users
```

### Option 2: Docker (Host Network)
```
Ollama (host:11434) ← Flask (container:5000) ← Nginx (80/443) ← Users
```

### Option 3: Remote Ollama
```
Ollama (server:11434) ← Flask (app:5000) ← Users
         [LAN/VPN]
```

---

**This architecture provides a balance of simplicity, performance, and privacy for local AI chat!** 🎯

