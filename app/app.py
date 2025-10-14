from flask import Flask, render_template, redirect, request, url_for, flash, session, jsonify
import json
import os
from werkzeug.security import generate_password_hash, check_password_hash
from functools import wraps
import uuid
from datetime import datetime
import openai
from anthropic import Anthropic

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'your_secret_key_change_in_production')
app_version = os.getenv('VERSION', '1.0.0')

# Set up paths
alias = "chat"
HOME_DIR = os.path.expanduser("~")
FILES_PATH = os.path.join(HOME_DIR, "script_files", alias)
DATA_DIR = os.path.join(FILES_PATH, "data")
USERS_FILE = os.path.join(DATA_DIR, 'users.json')
CHATS_FILE = os.path.join(DATA_DIR, 'chats.json')

# Ensure the directory exists
os.makedirs(DATA_DIR, exist_ok=True)

# AI Configuration
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY', '')
ANTHROPIC_API_KEY = os.getenv('ANTHROPIC_API_KEY', '')

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

def get_ai_response(messages, model="gpt-4"):
    """Get response from AI model"""
    try:
        if model.startswith("gpt"):
            if not OPENAI_API_KEY:
                return {"error": "OpenAI API key not configured"}
            
            openai.api_key = OPENAI_API_KEY
            response = openai.ChatCompletion.create(
                model=model,
                messages=messages,
                temperature=0.7,
                max_tokens=2000
            )
            return {"content": response.choices[0].message.content}
        
        elif model.startswith("claude"):
            if not ANTHROPIC_API_KEY:
                return {"error": "Anthropic API key not configured"}
            
            client = Anthropic(api_key=ANTHROPIC_API_KEY)
            # Convert messages format for Claude
            system_msg = next((m["content"] for m in messages if m["role"] == "system"), None)
            user_messages = [m for m in messages if m["role"] != "system"]
            
            response = client.messages.create(
                model=model,
                max_tokens=2000,
                system=system_msg if system_msg else "",
                messages=user_messages
            )
            return {"content": response.content[0].text}
        
        else:
            return {"error": "Unknown model"}
    
    except Exception as e:
        return {"error": str(e)}

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
    return render_template('register_root.html')

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
    return render_template('register_user.html')

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
        user_data = {"model_preference": "gpt-4"}
    
    return render_template(
        'dashboard.html',
        username=username,
        role=role,
        user_chats=user_chats,
        user_data=user_data
    )

@app.route('/root_dashboard')
@login_required
def root_dashboard():
    if not session.get('is_root'):
        flash("Access denied", "danger")
        return redirect(url_for('dashboard'))
    
    users_data = load_users()
    user_list = users_data[1]['users'] if len(users_data) > 1 else []
    return render_template('root_dashboard.html', users=user_list)

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
    
    new_chat = {
        'id': str(uuid.uuid4()),
        'name': chat_name,
        'created_at': datetime.now().isoformat(),
        'created_by': username,
        'messages': [],
        'model': request.form.get('model', 'gpt-4')
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
    
    return render_template('chat.html', chat=chat)

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

@app.route('/settings', methods=['GET', 'POST'])
@login_required
def settings():
    username = session.get('user_id')
    users = load_users()
    
    if request.method == 'POST':
        model_preference = request.form.get('model_preference', 'gpt-4')
        
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
        user_data = {"model_preference": "gpt-4"}
    
    return render_template('settings.html', user_data=user_data)

@app.route('/logout')
@login_required
def logout():
    session.clear()
    flash("Logged out successfully.", "info")
    return redirect(url_for('login'))

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000, threaded=True)

