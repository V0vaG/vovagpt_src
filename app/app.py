from flask import Flask, render_template, redirect, request, url_for, flash, session, jsonify, Response, stream_with_context
import json
import os
from werkzeug.security import generate_password_hash, check_password_hash
from functools import wraps
import uuid
from datetime import datetime
import requests
import time

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'your_secret_key_change_in_production')
app_version = os.getenv('VERSION', '1.0.0')

# Set up paths
alias = "vovagpt"
HOME_DIR = os.path.expanduser("~")
FILES_PATH = os.path.join(HOME_DIR, "script_files", alias)
DATA_DIR = os.path.join(FILES_PATH, "data")
USERS_FILE = os.path.join(DATA_DIR, 'users.json')
CHATS_FILE = os.path.join(DATA_DIR, 'chats.json')
MODELS_DIR = os.path.join(DATA_DIR, 'models')

# Ensure directories exist
os.makedirs(DATA_DIR, exist_ok=True)
os.makedirs(MODELS_DIR, exist_ok=True)

# Ollama Configuration - Kubernetes/Cloud-native ready
# In k8s cluster: Set OLLAMA_HOST to the Ollama service name
# Example: OLLAMA_HOST=http://ollama-service:11434
OLLAMA_HOST = os.getenv('OLLAMA_HOST', 'http://localhost:11434')

print(f"🚀 VovaGPT starting...")
print(f"📁 Data directory: {DATA_DIR}")
print(f"🤖 Ollama host: {OLLAMA_HOST}")

# ------------------ Helpers ------------------

def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            flash("Please log in first.", "danger")
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

def load_users():
    if os.path.exists(USERS_FILE):
        with open(USERS_FILE, 'r') as file:
            return json.load(file)
    return []

def save_users(users):
    with open(USERS_FILE, 'w') as file:
        json.dump(users, file, indent=4)

def get_root_user():
    users = load_users()
    return users[0] if users else None

def is_root_registered():
    return bool(get_root_user())

def save_root_user(username, password):
    password_hash = generate_password_hash(password, method='pbkdf2:sha256')
    users = [{"root_user": username, "password_hash": password_hash}, {"users": []}]
    save_users(users)

def save_user(username, password):
    password_hash = generate_password_hash(password, method='pbkdf2:sha256')
    users = load_users()
    users[1]['users'].append({
        "username": username, 
        "password_hash": password_hash,
        "created_at": datetime.now().isoformat(),
        "model_preference": "gpt-4"
    })
    save_users(users)

def remove_user(username):
    users = load_users()
    if len(users) > 1:
        users[1]['users'] = [user for user in users[1]['users'] if user['username'] != username]
        save_users(users)
        return True
    return False

def load_chats():
    if os.path.exists(CHATS_FILE):
        with open(CHATS_FILE, 'r') as f:
            return json.load(f)
    return []

def save_chats(chats):
    with open(CHATS_FILE, 'w') as f:
        json.dump(chats, f, indent=2)

# ------------------ Ollama Functions ------------------

def get_ollama_models():
    """Get list of downloaded Ollama models"""
    try:
        response = requests.get(f"{OLLAMA_HOST}/api/tags", timeout=5)
        if response.status_code == 200:
            data = response.json()
            return [model['name'] for model in data.get('models', [])]
        return []
    except Exception as e:
        print(f"Error getting models: {e}")
        return []

def get_available_ollama_models():
    """Get list of popular Ollama models available for download"""
    # Popular Ollama models
    return [
        {"name": "llama3.2:latest", "size": "2.0GB", "description": "Meta's Llama 3.2 - Fast and efficient"},
        {"name": "llama3.2:3b", "size": "2.0GB", "description": "Llama 3.2 3B - Lightweight model"},
        {"name": "llama3.1:latest", "size": "4.7GB", "description": "Meta's Llama 3.1 8B - Balanced performance"},
        {"name": "llama3.1:70b", "size": "40GB", "description": "Llama 3.1 70B - Best quality (large)"},
        {"name": "qwen2.5:latest", "size": "4.7GB", "description": "Alibaba's Qwen 2.5 - Multilingual"},
        {"name": "qwen2.5:7b", "size": "4.7GB", "description": "Qwen 2.5 7B - Good for coding"},
        {"name": "qwen2.5:14b", "size": "9.0GB", "description": "Qwen 2.5 14B - Better reasoning"},
        {"name": "qwen2.5-coder:latest", "size": "4.7GB", "description": "Qwen 2.5 Coder - Specialized for coding"},
        {"name": "deepseek-r1:latest", "size": "4.7GB", "description": "DeepSeek R1 - Reasoning model"},
        {"name": "deepseek-r1:7b", "size": "4.7GB", "description": "DeepSeek R1 7B"},
        {"name": "deepseek-coder-v2:latest", "size": "8.9GB", "description": "DeepSeek Coder V2 - Advanced coding"},
        {"name": "mistral:latest", "size": "4.1GB", "description": "Mistral 7B - Fast and capable"},
        {"name": "mixtral:latest", "size": "26GB", "description": "Mixtral 8x7B - MoE model"},
        {"name": "phi4:latest", "size": "7.9GB", "description": "Microsoft Phi 4 - Compact but powerful"},
        {"name": "gemma2:latest", "size": "5.4GB", "description": "Google Gemma 2 - Efficient"},
        {"name": "codellama:latest", "size": "3.8GB", "description": "Meta's Code Llama - For coding"},
        {"name": "granite-code:latest", "size": "4.6GB", "description": "IBM Granite Code - Enterprise coding"},
    ]

def download_ollama_model(model_name):
    """Download/pull an Ollama model"""
    try:
        response = requests.post(
            f"{OLLAMA_HOST}/api/pull",
            json={"name": model_name},
            stream=True,
            timeout=None
        )
        return response
    except Exception as e:
        return None

def delete_ollama_model(model_name):
    """Delete an Ollama model"""
    try:
        response = requests.delete(
            f"{OLLAMA_HOST}/api/delete",
            json={"name": model_name},
            timeout=10
        )
        return response.status_code == 200
    except Exception as e:
        print(f"Error deleting model: {e}")
        return False

def get_ai_response(messages, model):
    """Get response from Ollama model"""
    try:
        print(f"[DEBUG] Sending request to {OLLAMA_HOST}/api/chat")
        print(f"[DEBUG] Model: {model}")
        print(f"[DEBUG] Messages count: {len(messages)}")
        
        response = requests.post(
            f"{OLLAMA_HOST}/api/chat",
            json={
                "model": model,
                "messages": messages,
                "stream": False
            },
            timeout=120
        )
        
        print(f"[DEBUG] Response status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"[DEBUG] Response data keys: {data.keys()}")
            if 'message' in data and 'content' in data['message']:
                return {"content": data['message']['content']}
            else:
                print(f"[DEBUG] Full response: {data}")
                return {"error": f"Unexpected response format: {data}"}
        
        print(f"[DEBUG] Error response: {response.text}")
        return {"error": f"Model response error: {response.status_code} - {response.text}"}
    
    except Exception as e:
        print(f"[DEBUG] Exception: {type(e).__name__}: {str(e)}")
        return {"error": f"Ollama error: {str(e)}. Make sure Ollama is running."}

# ------------------ Routes ------------------

@app.before_request
def check_root_user():
    if not is_root_registered():
        if request.endpoint not in ('register_root', 'static'):
            return redirect(url_for('register_root'))

@app.route('/')
def index():
    if not is_root_registered():
        return redirect(url_for('register_root'))
    return redirect(url_for('login'))

@app.route('/register_root', methods=['GET', 'POST'])
def register_root():
    if is_root_registered():
        return redirect(url_for('login'))
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        confirm_password = request.form['confirm_password']
        if password != confirm_password:
            flash('Passwords do not match!', 'danger')
        else:
            save_root_user(username, password)
            flash('Root user registered successfully!', 'success')
            return redirect(url_for('login'))
    return render_template('register_root.html', app_version=app_version)

@app.route('/register_user', methods=['GET', 'POST'])
def register_user():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        confirm_password = request.form['confirm_password']
        if password != confirm_password:
            flash('Passwords do not match!', 'danger')
        else:
            save_user(username, password)
            flash('User registered successfully!', 'success')
            return redirect(url_for('login'))
    return render_template('register_user.html', app_version=app_version)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        users = load_users()
        root_user = users[0] if users else None
        regular_users = users[1]['users'] if len(users) > 1 else []
        
        if root_user and username == root_user['root_user']:
            if check_password_hash(root_user['password_hash'], password):
                session['user_id'] = username
                session['is_root'] = True
                flash("Logged in as root.", "success")
                return redirect(url_for('dashboard'))
        
        for user in regular_users:
            if user['username'] == username and check_password_hash(user['password_hash'], password):
                session['user_id'] = username
                session['is_root'] = False
                flash("Logged in successfully.", "success")
                return redirect(url_for('dashboard'))
        
        flash("Invalid credentials.", "danger")
    return render_template('login.html', app_version=app_version)

@app.route('/dashboard')
@login_required
def dashboard():
    username = session.get('user_id', 'Unknown')
    role = "root" if session.get('is_root') else "user"
    
    chats = load_chats()
    user_chats = [chat for chat in chats if chat['created_by'] == username]
    
    # Get user preferences
    users = load_users()
    user_data = {}
    if not session.get('is_root'):
        for u in users[1]["users"]:
            if u["username"] == username:
                user_data = u
                break
    else:
        user_data = {"model_preference": "llama3.2:latest"}
    
    # Get Ollama models
    downloaded_models = get_ollama_models()
    available_models = get_available_ollama_models()
    
    # Filter out already downloaded models from available list
    downloaded_names = set(downloaded_models)
    available_models = [m for m in available_models if m['name'] not in downloaded_names]
    
    return render_template(
        'dashboard.html',
        username=username,
        role=role,
        user_chats=user_chats,
        user_data=user_data,
        downloaded_models=downloaded_models,
        available_models=available_models,
        app_version=app_version
    )

@app.route('/root_dashboard')
@login_required
def root_dashboard():
    if not session.get('is_root'):
        flash("Access denied", "danger")
        return redirect(url_for('dashboard'))
    
    users_data = load_users()
    user_list = users_data[1]['users'] if len(users_data) > 1 else []
    return render_template('root_dashboard.html', users=user_list, app_version=app_version)

@app.route('/remove_user', methods=['POST'])
@login_required
def remove_user_route():
    if not session.get('is_root'):
        flash("Access denied", "danger")
        return redirect(url_for('dashboard'))
    
    username = request.form['username']
    remove_user(username)
    flash('User removed successfully!', 'success')
    return redirect(url_for('root_dashboard'))

@app.route('/chat/new', methods=['POST'])
@login_required
def new_chat():
    username = session.get('user_id')
    chat_name = request.form.get('chat_name', 'New Chat').strip()
    model = request.form.get('model', '')
    
    # If no model specified, use first available downloaded model
    if not model:
        downloaded_models = get_ollama_models()
        model = downloaded_models[0] if downloaded_models else 'llama3.2:latest'
    
    new_chat = {
        'id': str(uuid.uuid4()),
        'name': chat_name,
        'created_at': datetime.now().isoformat(),
        'created_by': username,
        'messages': [],
        'model': model
    }
    
    chats = load_chats()
    chats.append(new_chat)
    save_chats(chats)
    
    flash('New chat created!', 'success')
    return redirect(url_for('view_chat', chat_id=new_chat['id']))

@app.route('/chat/<chat_id>')
@login_required
def view_chat(chat_id):
    username = session.get('user_id')
    chats = load_chats()
    chat = next((c for c in chats if c['id'] == chat_id), None)
    
    if not chat:
        flash("Chat not found.", "danger")
        return redirect(url_for('dashboard'))
    
    if chat['created_by'] != username:
        flash("Access denied.", "danger")
        return redirect(url_for('dashboard'))
    
    return render_template('chat.html', chat=chat, app_version=app_version)

@app.route('/chat/<chat_id>/message', methods=['POST'])
@login_required
def send_message(chat_id):
    username = session.get('user_id')
    chats = load_chats()
    chat = next((c for c in chats if c['id'] == chat_id), None)
    
    if not chat or chat['created_by'] != username:
        return jsonify({"error": "Chat not found"}), 404
    
    user_message = request.json.get('message', '').strip()
    if not user_message:
        return jsonify({"error": "Empty message"}), 400
    
    # Add user message
    chat['messages'].append({
        'id': str(uuid.uuid4()),
        'role': 'user',
        'content': user_message,
        'timestamp': datetime.now().isoformat()
    })
    
    # Prepare messages for AI
    ai_messages = [{"role": m['role'], "content": m['content']} for m in chat['messages']]
    
    # Get AI response
    model = chat.get('model', 'gpt-4')
    ai_result = get_ai_response(ai_messages, model)
    
    if 'error' in ai_result:
        return jsonify({"error": ai_result['error']}), 500
    
    # Add AI response
    ai_message = {
        'id': str(uuid.uuid4()),
        'role': 'assistant',
        'content': ai_result['content'],
        'timestamp': datetime.now().isoformat()
    }
    chat['messages'].append(ai_message)
    
    # Update chat name if it's the first message
    if len(chat['messages']) == 2:  # user + assistant
        chat['name'] = user_message[:50] + ('...' if len(user_message) > 50 else '')
    
    save_chats(chats)
    
    return jsonify({"message": ai_message})

@app.route('/chat/<chat_id>/rename', methods=['POST'])
@login_required
def rename_chat(chat_id):
    username = session.get('user_id')
    new_name = request.form.get('chat_name', '').strip()
    
    chats = load_chats()
    for chat in chats:
        if chat['id'] == chat_id and chat['created_by'] == username:
            chat['name'] = new_name or "Unnamed Chat"
            break
    
    save_chats(chats)
    flash("Chat renamed!", "success")
    return redirect(url_for('view_chat', chat_id=chat_id))

@app.route('/chat/<chat_id>/delete', methods=['POST'])
@login_required
def delete_chat(chat_id):
    username = session.get('user_id')
    chats = load_chats()
    chats = [c for c in chats if not (c['id'] == chat_id and c['created_by'] == username)]
    save_chats(chats)
    
    flash("Chat deleted successfully.", "success")
    return redirect(url_for('dashboard'))

@app.route('/chat/<chat_id>/clear', methods=['POST'])
@login_required
def clear_chat(chat_id):
    username = session.get('user_id')
    chats = load_chats()
    
    for chat in chats:
        if chat['id'] == chat_id and chat['created_by'] == username:
            chat['messages'] = []
            break
    
    save_chats(chats)
    flash("Chat history cleared.", "info")
    return redirect(url_for('view_chat', chat_id=chat_id))

@app.route('/model/download/<path:model_name>')
@login_required
def download_model(model_name):
    """Stream model download progress"""
    def generate():
        response = download_ollama_model(model_name)
        if response is None:
            yield f"data: {json.dumps({'error': 'Failed to start download'})}\n\n"
            return
        
        for line in response.iter_lines():
            if line:
                try:
                    data = json.loads(line)
                    yield f"data: {json.dumps(data)}\n\n"
                except json.JSONDecodeError:
                    continue
        
        yield f"data: {json.dumps({'status': 'complete'})}\n\n"
    
    return Response(stream_with_context(generate()), mimetype='text/event-stream')

@app.route('/model/delete/<path:model_name>', methods=['POST'])
@login_required
def delete_model(model_name):
    """Delete a downloaded model"""
    success = delete_ollama_model(model_name)
    if success:
        flash(f"Model '{model_name}' deleted successfully!", "success")
    else:
        flash(f"Failed to delete model '{model_name}'", "danger")
    return redirect(url_for('dashboard'))

@app.route('/models/list')
@login_required
def list_models():
    """API endpoint to get current models"""
    return jsonify({
        'downloaded': get_ollama_models(),
        'available': get_available_ollama_models()
    })

@app.route('/ollama/status')
@login_required
def ollama_status():
    """Check if Ollama is connected and responding"""
    try:
        response = requests.get(f"{OLLAMA_HOST}/api/tags", timeout=2)
        if response.status_code == 200:
            data = response.json()
            model_count = len(data.get('models', []))
            return jsonify({
                'connected': True,
                'status': 'online',
                'models': model_count,
                'host': OLLAMA_HOST
            })
        else:
            return jsonify({
                'connected': False,
                'status': 'error',
                'error': f'HTTP {response.status_code}'
            })
    except Exception as e:
        return jsonify({
            'connected': False,
            'status': 'offline',
            'error': str(e)
        })

@app.route('/settings', methods=['GET', 'POST'])
@login_required
def settings():
    username = session.get('user_id')
    users = load_users()
    
    if request.method == 'POST':
        model_preference = request.form.get('model_preference', 'llama3.2:latest')
        
        if session.get('is_root'):
            # Update root user preferences (you could extend this)
            flash("Settings updated!", "success")
        else:
            for user in users[1]['users']:
                if user['username'] == username:
                    user['model_preference'] = model_preference
                    break
            save_users(users)
            flash("Settings updated!", "success")
        
        return redirect(url_for('settings'))
    
    # Get current settings
    user_data = {}
    if not session.get('is_root'):
        for u in users[1]["users"]:
            if u["username"] == username:
                user_data = u
                break
    else:
        user_data = {"model_preference": "llama3.2:latest"}
    
    # Get downloaded models for settings
    downloaded_models = get_ollama_models()
    
    return render_template('settings.html', user_data=user_data, downloaded_models=downloaded_models, app_version=app_version)

@app.route('/logout')
@login_required
def logout():
    session.clear()
    flash("Logged out successfully.", "info")
    return redirect(url_for('login'))

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000, threaded=True)

