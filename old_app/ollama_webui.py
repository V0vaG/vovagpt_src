#!/usr/bin/env python3
"""
Ollama Web UI - ChatGPT-like interface for Ollama models
Supports both USB and System Ollama instances
"""

import os
import sys
import subprocess
import json
import requests
from pathlib import Path
from typing import List, Dict, Optional
import gradio as gr
import time

class OllamaWebUI:
    def __init__(self, models_dir: str = None, ollama_bin: str = None):
        self.models_dir = models_dir
        self.ollama_bin = ollama_bin
        self.server_process = None
        self.ollama_host = "http://localhost:11434"
        self.use_usb = bool(models_dir and ollama_bin)
        
    def start_server(self):
        """Start Ollama server if using USB mode"""
        if self.use_usb:
            env = os.environ.copy()
            env['OLLAMA_MODELS'] = self.models_dir
            env['OLLAMA_HOST'] = '0.0.0.0:11434'
            
            print(f"Starting Ollama server from USB...")
            print(f"Binary: {self.ollama_bin}")
            print(f"Models: {self.models_dir}")
            
            self.server_process = subprocess.Popen(
                [self.ollama_bin, 'serve'],
                env=env,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            time.sleep(3)  # Wait for server to start
            print("Server started!")
    
    def stop_server(self):
        """Stop Ollama server if running"""
        if self.server_process:
            print("Stopping Ollama server...")
            self.server_process.terminate()
            self.server_process.wait()
            print("Server stopped!")
    
    def get_models(self) -> List[Dict]:
        """Get list of available models"""
        try:
            response = requests.get(f"{self.ollama_host}/api/tags", timeout=5)
            if response.status_code == 200:
                data = response.json()
                return [model['name'] for model in data.get('models', [])]
            return []
        except Exception as e:
            print(f"Error getting models: {e}")
            return []
    
    def chat(self, message: str, history: List, model: str, system_prompt: str, temperature: float, max_tokens: int):
        """Send chat message to Ollama"""
        if not model:
            yield history + [(message, "⚠️ Please select a model first!")], ""
            return
        
        # Build conversation context
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        
        # Add history
        for human, assistant in history:
            messages.append({"role": "user", "content": human})
            messages.append({"role": "assistant", "content": assistant})
        
        # Add current message
        messages.append({"role": "user", "content": message})
        
        # Stream response
        try:
            response = requests.post(
                f"{self.ollama_host}/api/chat",
                json={
                    "model": model,
                    "messages": messages,
                    "stream": True,
                    "options": {
                        "temperature": temperature,
                        "num_predict": max_tokens
                    }
                },
                stream=True,
                timeout=120
            )
            
            assistant_message = ""
            for line in response.iter_lines():
                if line:
                    try:
                        data = json.loads(line)
                        if 'message' in data and 'content' in data['message']:
                            chunk = data['message']['content']
                            assistant_message += chunk
                            # Yield partial response for streaming effect
                            yield history + [(message, assistant_message)], ""
                    except json.JSONDecodeError:
                        continue
            
        except Exception as e:
            error_msg = f"❌ Error: {str(e)}\n\nMake sure Ollama is running and the model is available."
            yield history + [(message, error_msg)], ""
    
    def get_model_info(self, model: str) -> str:
        """Get model information"""
        if not model:
            return "No model selected"
        
        try:
            response = requests.post(
                f"{self.ollama_host}/api/show",
                json={"name": model},
                timeout=10
            )
            if response.status_code == 200:
                data = response.json()
                info = f"**Model:** {model}\n\n"
                
                if 'details' in data:
                    details = data['details']
                    info += f"**Family:** {details.get('family', 'N/A')}\n"
                    info += f"**Parameter Size:** {details.get('parameter_size', 'N/A')}\n"
                    info += f"**Quantization:** {details.get('quantization_level', 'N/A')}\n"
                
                if 'modelfile' in data:
                    info += f"\n**Modelfile:**\n```\n{data['modelfile'][:500]}...\n```"
                
                return info
            return f"Could not fetch info for {model}"
        except Exception as e:
            return f"Error: {str(e)}"
    
    def create_interface(self):
        """Create Gradio interface"""
        
        # Get available models
        models = self.get_models()
        if not models:
            models = ["No models found - check Ollama server"]
        
        # Custom CSS for ChatGPT-like appearance
        custom_css = """
        .gradio-container {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
        }
        .chat-message {
            padding: 1rem;
            border-radius: 0.5rem;
        }
        #component-0 {
            height: 100vh;
        }
        """
        
        with gr.Blocks(css=custom_css, title="Ollama Chat", theme=gr.themes.Soft()) as interface:
            gr.Markdown(
                f"""
                # 🤖 Ollama Chat Interface
                
                **Mode:** {'USB (Portable)' if self.use_usb else 'System'}
                {f'**Models Directory:** `{self.models_dir}`' if self.use_usb else ''}
                
                A ChatGPT-like interface for your local AI models powered by Ollama.
                """
            )
            
            with gr.Row():
                with gr.Column(scale=3):
                    # Chat interface
                    chatbot = gr.Chatbot(
                        label="Chat",
                        height=500,
                        show_label=False,
                        avatar_images=(None, "🤖"),
                        bubble_full_width=False
                    )
                    
                    with gr.Row():
                        msg = gr.Textbox(
                            label="Message",
                            placeholder="Type your message here... (Shift+Enter for new line)",
                            lines=2,
                            max_lines=10,
                            show_label=False,
                            scale=9
                        )
                        submit_btn = gr.Button("Send 📤", scale=1, variant="primary")
                    
                    with gr.Row():
                        clear_btn = gr.Button("🗑️ Clear Chat")
                        regenerate_btn = gr.Button("🔄 Regenerate")
                
                with gr.Column(scale=1):
                    # Settings panel
                    gr.Markdown("### ⚙️ Settings")
                    
                    model_dropdown = gr.Dropdown(
                        choices=models,
                        value=models[0] if models else None,
                        label="Select Model",
                        interactive=True
                    )
                    
                    refresh_models_btn = gr.Button("🔄 Refresh Models")
                    
                    system_prompt = gr.Textbox(
                        label="System Prompt",
                        placeholder="You are a helpful assistant...",
                        lines=3,
                        value=""
                    )
                    
                    temperature = gr.Slider(
                        minimum=0.0,
                        maximum=2.0,
                        value=0.7,
                        step=0.1,
                        label="Temperature",
                        info="Higher = more creative, Lower = more focused"
                    )
                    
                    max_tokens = gr.Slider(
                        minimum=128,
                        maximum=4096,
                        value=2048,
                        step=128,
                        label="Max Tokens",
                        info="Maximum response length"
                    )
                    
                    gr.Markdown("### 📊 Model Info")
                    model_info = gr.Markdown("Select a model to see details")
            
            # Event handlers
            def submit_message(message, history, model, sys_prompt, temp, max_tok):
                if not message.strip():
                    yield history, ""
                    return
                yield from self.chat(message, history, model, sys_prompt, temp, max_tok)
            
            def refresh_models():
                new_models = self.get_models()
                if not new_models:
                    new_models = ["No models found"]
                return gr.Dropdown(choices=new_models, value=new_models[0] if new_models else None)
            
            def update_model_info(model):
                return self.get_model_info(model)
            
            def get_default_system_prompt(model):
                """Get appropriate system prompt based on model"""
                if not model:
                    return ""
                
                model_lower = model.lower()
                
                # DeepSeek models
                if "deepseek" in model_lower:
                    return "You are DeepSeek Coder, an AI coding assistant created by DeepSeek. You excel at programming tasks, code explanation, debugging, and software development best practices."
                
                # Code-focused models
                elif any(x in model_lower for x in ["coder", "code", "starcoder", "codellama", "granite-code"]):
                    return "You are an expert programming assistant. Provide clear code examples, explanations, and follow best practices. Format code blocks properly and explain complex concepts."
                
                # Qwen models
                elif "qwen" in model_lower:
                    return "You are Qwen, a large language model created by Alibaba Cloud. You are multilingual and excel at various tasks including reasoning, coding, and creative writing."
                
                # Gemma models (Google)
                elif "gemma" in model_lower:
                    return "You are Gemma, an AI assistant created by Google. You provide helpful, accurate, and safe responses to user queries."
                
                # Llama models (Meta)
                elif "llama" in model_lower:
                    return "You are Llama, a large language model created by Meta. You are helpful, harmless, and honest. You provide detailed and accurate responses."
                
                # Mistral models
                elif "mistral" in model_lower:
                    return "You are Mistral, an AI assistant. You provide clear, accurate, and helpful responses to user questions."
                
                # Phi models (Microsoft)
                elif "phi" in model_lower:
                    return "You are Phi, a small but capable language model created by Microsoft. You provide concise, accurate, and helpful responses."
                
                # Granite models (IBM)
                elif "granite" in model_lower:
                    return "You are Granite, an enterprise AI assistant created by IBM. You excel at professional and technical tasks with accuracy and reliability."
                
                # Default for other models
                else:
                    return "You are a helpful AI assistant. Provide clear, accurate, and concise responses to user questions."
            
            def regenerate_last(history, model, sys_prompt, temp, max_tok):
                if not history:
                    yield history, ""
                    return
                last_message = history[-1][0]
                history = history[:-1]
                yield from self.chat(last_message, history, model, sys_prompt, temp, max_tok)
            
            # Wire up events
            submit_btn.click(
                submit_message,
                inputs=[msg, chatbot, model_dropdown, system_prompt, temperature, max_tokens],
                outputs=[chatbot, msg]
            )
            
            msg.submit(
                submit_message,
                inputs=[msg, chatbot, model_dropdown, system_prompt, temperature, max_tokens],
                outputs=[chatbot, msg]
            )
            
            clear_btn.click(lambda: ([], ""), outputs=[chatbot, msg])
            
            regenerate_btn.click(
                regenerate_last,
                inputs=[chatbot, model_dropdown, system_prompt, temperature, max_tokens],
                outputs=[chatbot, msg]
            )
            
            refresh_models_btn.click(refresh_models, outputs=model_dropdown)
            
            model_dropdown.change(
                lambda m: (update_model_info(m), get_default_system_prompt(m)),
                inputs=model_dropdown,
                outputs=[model_info, system_prompt]
            )
            
            # Load initial model info and system prompt
            interface.load(
                lambda: (self.get_model_info(models[0] if models else ""), get_default_system_prompt(models[0] if models else "")),
                outputs=[model_info, system_prompt]
            )
        
        return interface

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="Ollama Web UI")
    parser.add_argument("--models-dir", help="Path to models directory (USB mode)")
    parser.add_argument("--ollama-bin", help="Path to ollama binary (USB mode)")
    parser.add_argument("--port", type=int, default=7860, help="Port to run on (default: 7860)")
    parser.add_argument("--share", action="store_true", help="Create public share link")
    
    args = parser.parse_args()
    
    # Create UI instance
    ui = OllamaWebUI(models_dir=args.models_dir, ollama_bin=args.ollama_bin)
    
    try:
        # Start server if USB mode
        if ui.use_usb:
            ui.start_server()
        
        # Create and launch interface
        interface = ui.create_interface()
        
        print(f"\n{'='*60}")
        print(f"🚀 Ollama Web UI starting on http://localhost:{args.port}")
        print(f"{'='*60}\n")
        
        interface.launch(
            server_name="0.0.0.0",
            server_port=args.port,
            share=args.share,
            inbrowser=True
        )
        
    except KeyboardInterrupt:
        print("\n\nShutting down...")
    finally:
        ui.stop_server()

if __name__ == "__main__":
    main()

