#!/usr/bin/env bash
set -euo pipefail

#############################################
# Offline AI USB Toolkit (Linux, x86_64)
# - Hardware-aware color rating (Green/Yellow/Red)
# - Swapfile wizard + auto prompt for heavy models
# - Offline install of Ollama
# - USB<->System selective transfer (import/sync)
# - Online updates for Ollama and models
# - Online check & optional update for models
#############################################

# ---------- Model Catalog ----------
# Format: "model:tag|[Hardware] Storage Size, RAM Needed"
# [CPU]     = Works on older CPU (like X230) with 4-8GB RAM
# [CPU/GPU] = Needs GPU or strong CPU with 12-32GB RAM+SWAP
# [GPU]     = Requires GPU with 12GB+ VRAM
CATALOG=(
  # ===== TINY MODELS (CPU-Friendly: <2GB) =====
  "deepseek-coder:1.3b|[CPU] 0.8GB Storage, 4-8GB RAM"
  "gemma2:2b|[CPU] 1.6GB Storage, 4-8GB RAM"
  "qwen2.5-coder:1.5b|[CPU] 1.5GB Storage, 6-12GB RAM"
  "qwen2:1.5b|[CPU] 1.5GB Storage, 6-12GB RAM"
  "granite-code:3b|[CPU] 2.2GB Storage, 6-12GB RAM"
  
  # ===== SMALL MODELS (CPU-OK: 3-4GB) =====
  "starcoder2:3b|[CPU] 2.2GB Storage, 8-16GB RAM"
  "qwen2.5-coder:3b|[CPU] 2.2GB Storage, 8-16GB RAM"
  "stable-code:3b|[CPU/GPU] 2.2GB Storage, 8-16GB RAM"
  "phi3.5:3.8b-mini-instruct|[CPU] 2.8GB Storage, 8-16GB RAM"
  "stable-code:3b-instruct|[CPU/GPU] 2.2GB Storage, 8-16GB RAM"
  "gemma2:4b|[CPU/GPU] 3.2GB Storage, 8-16GB RAM"
  "qwen2:4b|[CPU/GPU] 3.2GB Storage, 12-24GB RAM"
  
  # ===== MEDIUM MODELS (GPU/SWAP Needed: 7-8GB) =====
  "qwen2.5-coder:7b|[CPU/GPU] 5.2GB Storage, 16-32GB RAM"
  "codellama:7b|[CPU/GPU] 5.2GB Storage, 16-32GB RAM"
  "codellama:7b-instruct|[CPU/GPU] 5.2GB Storage, 16-32GB RAM"
  "starcoder2:7b|[CPU/GPU] 5.2GB Storage, 16-32GB RAM"
  "mistral:7b|[CPU/GPU] 5.2GB Storage, 16-32GB RAM"
  "llama2:7b|[CPU/GPU] 5.2GB Storage, 16-32GB RAM"
  "llama3.1:8b|[CPU/GPU] 6GB Storage, 16-32GB RAM"
  "granite-code:8b|[CPU/GPU] 6GB Storage, 16-32GB RAM"
  
  # ===== LARGE MODELS (GPU Required: 12GB+) =====
  "gemma2:12b|[GPU] 9GB Storage, 24-48GB RAM"  
)

# Defaults (for convenience - not required)
MODEL_A="deepseek-coder:1.3b"
MODEL_B="starcoder2:3b"

# URLs
OLLAMA_TARBALL_URL_LINUX_AMD64="https://github.com/ollama/ollama/releases/latest/download/ollama-linux-amd64.tgz"

# Paths (USB)
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
USB_ROOT="$SCRIPT_DIR"
CACHE_DIR="$USB_ROOT/offline_cache"
BIN_DIR="$USB_ROOT/bin"
MODELS_DIR="$USB_ROOT/models"         # OLLAMA_MODELS על ה-USB
TARBALL_DIR="$CACHE_DIR/ollama"
EXPORT_DIR="$USB_ROOT/exports"        # .ollama exports
TARBALL_PATH="$TARBALL_DIR/ollama-linux-amd64.tgz"

mkdir -p "$CACHE_DIR" "$BIN_DIR" "$MODELS_DIR" "$TARBALL_DIR" "$EXPORT_DIR"

# ---------- ANSI Colors ----------
C_RESET=$'\033[0m'
C_GREEN=$'\033[1;32m'
C_YELLOW=$'\033[1;33m'
C_ORANGE=$'\033[38;5;208m'
C_RED=$'\033[1;31m'
C_BLUE=$'\033[1;34m'

info(){ echo -e "${C_BLUE}[INFO]${C_RESET} $*"; }
ok(){   echo -e "${C_GREEN}[DONE]${C_RESET} $*"; }
warn(){ echo -e "${C_YELLOW}[WARN]${C_RESET} $*"; }
err(){  echo -e "${C_RED}[ERR ]${C_RESET} $*" >&2; }
require_cmd(){ command -v "$1" >/dev/null 2>&1 || { err "'$1' is required but not installed."; exit 1; } }

ARCH="$(uname -m || true)"
if [[ "$ARCH" != "x86_64" && "$ARCH" != "amd64" ]]; then
  warn "Detected architecture $ARCH. This script is designed for x86_64 (like X230)."
fi

USB_OLLAMA_BIN="$BIN_DIR/ollama"

# ---------- Hardware Probe ----------
MEM_TOTAL_GB=0; SWAP_TOTAL_GB=0; CPU_CORES=1; CPU_FLAGS=""
HAS_AVX=0; HAS_AVX2=0; CPU_CLASS="old"
GPU_TYPE="none"; GPU_VRAM_GB=0

get_hw(){
  MEM_TOTAL_GB=$(awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo 2>/dev/null || echo 0)
  SWAP_TOTAL_GB=$(awk '/SwapTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo 2>/dev/null || echo 0)
  CPU_CORES=$(nproc 2>/dev/null || echo 1)
  CPU_FLAGS=$(LC_ALL=C lscpu 2>/dev/null | awk -F: '/Flags/ {print $2}' | xargs || echo "")
  [[ "$CPU_FLAGS" =~ (^|[[:space:]])avx($|[[:space:]]) ]] && HAS_AVX=1
  [[ "$CPU_FLAGS" =~ (^|[[:space:]])avx2($|[[:space:]]) ]] && HAS_AVX2=1
  CPU_CLASS="old"; (( HAS_AVX2 == 1 )) && CPU_CLASS="modern"

  if command -v nvidia-smi >/dev/null 2>&1; then
    GPU_TYPE="nvidia"
    GPU_VRAM_GB=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -n1 | awk '{printf "%.0f", $1/1024}')
  elif command -v rocm-smi >/dev/null 2>&1; then
    GPU_TYPE="amd"
    GPU_VRAM_GB=$(rocm-smi --showmeminfo vram 2>/dev/null | awk '/Total VRAM/ {print $4}' | head -n1)
    [[ -z "$GPU_VRAM_GB" ]] && GPU_VRAM_GB=0
  else
    GPU_TYPE="none"; GPU_VRAM_GB=0
  fi
}
get_hw

# ---------- Size helpers ----------
model_size_from_tag() {
  local tag="$1"
  if [[ "$tag" =~ ([_:/-]|^)1\.3b([_:/-]|$)|([_:/-]|^)1\.5b([_:/-]|$)|([_:/-]|^)3b([_:/-]|$)|([_:/-]|^)3\.8b([_:/-]|$) ]]; then
    echo "small"
  elif [[ "$tag" =~ ([_:/-]|^)7b([_:/-]|$) ]]; then
    echo "mid"
  elif [[ "$tag" =~ ([_:/-]|^)8b([_:/-]|$)|([_:/-]|^)9b([_:/-]|$)|([_:/-]|^)10b([_:/-]|$) ]]; then
    echo "big"
  else
    echo "mid"
  fi
}

# ---------- Model information generator ----------
get_model_info() {
  local tag="$1"
  local model_name="${tag%%:*}"
  local model_tag="${tag##*:}"
  [[ "$model_name" == "$model_tag" ]] && model_tag="latest"
  
  # Extract model type and size info
  local model_type="General"
  local model_size="Unknown"
  
  # Determine model type and size
  if [[ "$model_name" =~ coder|codellama|starcoder|stable-code|granite-code ]]; then
    model_type="Code"
  elif [[ "$model_name" =~ instruct|chat ]]; then
    model_type="Chat"
  fi
  
  # Extract size from model name (check both name and tag)
  # Order matters: check larger numbers first to avoid partial matches
  if [[ "$model_name" =~ 12b ]] || [[ "$model_tag" =~ 12b ]]; then
    model_size="12B"
  elif [[ "$model_name" =~ 1\.7b ]] || [[ "$model_tag" =~ 1\.7b ]]; then
    model_size="1.7B"
  elif [[ "$model_name" =~ 1\.5b ]] || [[ "$model_tag" =~ 1\.5b ]]; then
    model_size="1.5B"
  elif [[ "$model_name" =~ 1\.3b ]] || [[ "$model_tag" =~ 1\.3b ]]; then
    model_size="1.3B"
  elif [[ "$model_name" =~ 3\.8b ]] || [[ "$model_tag" =~ 3\.8b ]]; then
    model_size="3.8B"
  elif [[ "$model_name" =~ 8b ]] || [[ "$model_tag" =~ 8b ]]; then
    model_size="8B"
  elif [[ "$model_name" =~ 7b ]] || [[ "$model_tag" =~ 7b ]]; then
    model_size="7B"
  elif [[ "$model_name" =~ 4b ]] || [[ "$model_tag" =~ 4b ]]; then
    model_size="4B"
  elif [[ "$model_name" =~ 3b ]] || [[ "$model_tag" =~ 3b ]]; then
    model_size="3B"
  elif [[ "$model_name" =~ 2b ]] || [[ "$model_tag" =~ 2b ]]; then
    model_size="2B"
  elif [[ "$model_name" =~ 1b ]] || [[ "$model_tag" =~ 1b ]]; then
    model_size="1B"
  fi
  
  # Add special notes
  local notes=""
  if [[ "$model_name" =~ deepseek ]]; then
    notes=" | Chinese optimized"
  elif [[ "$model_name" =~ qwen ]]; then
    notes=" | Multilingual"
  elif [[ "$model_name" =~ phi3\.5 ]]; then
    notes=" | Microsoft"
  elif [[ "$model_name" =~ gemma ]]; then
    notes=" | Google"
  elif [[ "$model_name" =~ llama3\.1 ]]; then
    notes=" | Meta"
  elif [[ "$model_name" =~ mistral ]]; then
    notes=" | French company"
  elif [[ "$model_name" =~ granite-code ]]; then
    notes=" | IBM"
  fi
  
  echo "${model_type} ${model_size}${notes}"
}

# ---------- Heuristics per model -> color verdict ----------
rate_model() {
  local tag="$1"
  local size; size="$(model_size_from_tag "$tag")"

  local need_swap=0; local color desc
  if [[ "$size" == "small" ]]; then
    if (( MEM_TOTAL_GB >= 8 )); then color="$C_GREEN"; desc="Fast on CPU"
    else color="$C_YELLOW"; desc="Works but slow"; fi
  elif [[ "$size" == "mid" ]]; then
    need_swap=4
    if   (( GPU_VRAM_GB >= 6 )); then color="$C_GREEN"; desc="GPU recommended"
    elif (( MEM_TOTAL_GB >= 16 )) || (( MEM_TOTAL_GB >= 12 && SWAP_TOTAL_GB >= need_swap )); then color="$C_YELLOW"; desc="Possible on CPU (SWAP recommended)"
    else color="$C_ORANGE"; desc="Heavy for old CPU (add SWAP)"; fi
  else
    need_swap=8
    if   (( GPU_VRAM_GB >= 8 )); then color="$C_YELLOW"; desc="GPU preferred (VRAM≥8GB)"
    elif (( MEM_TOTAL_GB >= 16 && SWAP_TOTAL_GB >= need_swap )); then color="$C_ORANGE"; desc="On the edge for CPU"
    else color="$C_RED"; desc="Not recommended for this hardware"; fi
  fi

  if [[ "$color" != "$C_GREEN" && "$CPU_CLASS" == "modern" && $CPU_CORES -ge 8 && $MEM_TOTAL_GB -ge 16 ]]; then
    [[ "$color" == "$C_YELLOW" ]] && { color="$C_GREEN"; desc="Reasonable on strong CPU"; }
    [[ "$color" == "$C_ORANGE" ]] && { color="$C_YELLOW"; desc="Possible on strong CPU"; }
  fi
  (( HAS_AVX == 0 )) && desc="$desc; very slow without AVX"
  echo -e "${color}${desc}${C_RESET}"
}

print_hw_summary(){
  echo "---- Detected System Capabilities ----"
  echo "RAM: ${MEM_TOTAL_GB}GB | SWAP: ${SWAP_TOTAL_GB}GB | CPU cores: ${CPU_CORES} | AVX: ${HAS_AVX} AVX2: ${HAS_AVX2}"
  if [[ "$GPU_TYPE" == "none" ]]; then
    echo "GPU: none"
  else
    echo "GPU: ${GPU_TYPE}, VRAM: ${GPU_VRAM_GB}GB"
  fi
  if (( SWAP_TOTAL_GB == 0 )); then
    echo -e "SWAP status: ${C_RED}No SWAP active — recommended for 7B+ models${C_RESET}"
  elif (( SWAP_TOTAL_GB < 4 )); then
    echo -e "SWAP status: ${C_YELLOW}${SWAP_TOTAL_GB}GB — can be increased for better performance${C_RESET}"
  else
    echo -e "SWAP status: ${C_GREEN}${SWAP_TOTAL_GB}GB${C_RESET}"
  fi
  echo "Legend: ${C_GREEN}✓ Green${C_RESET}=CPU-friendly, ${C_YELLOW}⚠ Yellow${C_RESET}=Needs SWAP/GPU, ${C_RED}✗ Red${C_RESET}=GPU required"
  echo "---------------------------------------"
}

# ---------- Swapfile Wizard ----------
create_swapfile_wizard(){
  if [[ $EUID -ne 0 ]]; then
    warn "Creating SWAP requires sudo. Attempting to request permissions..."
    sudo true || { err "No sudo permissions. Cancelling."; return; }
  fi

  local suggest_gb=0
  if   (( MEM_TOTAL_GB < 8 ));  then suggest_gb=8
  elif (( MEM_TOTAL_GB < 12 )); then suggest_gb=8
  elif (( MEM_TOTAL_GB < 16 )); then suggest_gb=8
  else suggest_gb=4
  fi
  (( SWAP_TOTAL_GB == 0 )) && suggest_gb=8

  echo
  info "Swapfile Creation Wizard (Offline)"
  echo "Current: RAM=${MEM_TOTAL_GB}GB, SWAP=${SWAP_TOTAL_GB}GB"
  read -r -p "Recommended size ~${suggest_gb}GB. Change? (Enter to confirm / number in GB): " size_in
  local SIZE_GB="${size_in:-$suggest_gb}"
  [[ "$SIZE_GB" =~ ^[0-9]+$ ]] || { err "Invalid size."; return; }
  (( SIZE_GB > 0 )) || { err "Size must be >0."; return; }

  local SWAPFILE="/swapfile"
  read -r -p "Swapfile path (default: /swapfile): " path_in
  [[ -n "${path_in:-}" ]] && SWAPFILE="$path_in"

  echo
  warn "This will create ${SIZE_GB}GB SWAP at ${SWAPFILE}."
  read -r -p "Continue? (yes/no): " go
  [[ "$go" =~ ^[Yy][Ee]?[Ss]?$ ]] || { warn "Cancelled."; return; }

  info "Creating SWAP..."
  sudo fallocate -l "${SIZE_GB}G" "$SWAPFILE" || { info "fallocate failed; trying dd (slow)"; sudo dd if=/dev/zero of="$SWAPFILE" bs=1M count=$((SIZE_GB*1024)) status=progress; }
  sudo chmod 600 "$SWAPFILE"
  sudo mkswap "$SWAPFILE"
  sudo swapon "$SWAPFILE"
  ok "SWAP activated. Status:"
  free -h || true

  echo
  read -r -p "Add to /etc/fstab for automatic activation? (yes/no): " fstab_ans
  if [[ "$fstab_ans" =~ ^[Yy][Ee]?[Ss]?$ ]]; then
    local entry="$SWAPFILE none swap sw 0 0"
    if ! grep -qF "$entry" /etc/fstab 2>/dev/null; then
      echo "$entry" | sudo tee -a /etc/fstab >/dev/null
      ok "Added to /etc/fstab"
    else
      warn "Already exists in /etc/fstab"
    fi
  fi

  get_hw
  print_hw_summary
}

# ---------- Precheck: suggest swap for heavy models ----------
precheck_swap_for_model() {
  local tag="$1"
  local size; size="$(model_size_from_tag "$tag")"
  local need_swap=0
  case "$size" in
    small) need_swap=0 ;;
    mid)   need_swap=4 ;;
    big)   need_swap=8 ;;
  esac
  (( GPU_VRAM_GB >= 6 )) && return 0
  if (( need_swap > 0 )) && (( SWAP_TOTAL_GB < need_swap )); then
    echo
    warn "Model '$tag' recommends at least ${need_swap}GB SWAP (current: ${SWAP_TOTAL_GB}GB)."
    read -r -p "Create/increase SWAP now? (yes/no): " ans
    if [[ "$ans" =~ ^[Yy][Ee]?[Ss]?$ ]]; then
      create_swapfile_wizard
      get_hw
    else
      warn "Continuing without additional SWAP — may be slow/run out of memory."
    fi
  fi
}

# ---------- Ollama on USB ----------
download_ollama(){
  require_cmd curl
  info "Downloading Ollama (Linux amd64) to USB..."
  mkdir -p "$TARBALL_DIR"
  curl -fL "$OLLAMA_TARBALL_URL_LINUX_AMD64" -o "$TARBALL_PATH"
  ok "Saved: $TARBALL_PATH"
  info "Extracting binary for USB usage..."
  tmpdir="$(mktemp -d)"
  tar -xzf "$TARBALL_PATH" -C "$tmpdir"
  [[ -f "$tmpdir/bin/ollama" ]] || { err "'bin/ollama' not found in tarball."; exit 1; }
  mv "$tmpdir/bin/ollama" "$USB_OLLAMA_BIN"; chmod +x "$USB_OLLAMA_BIN"; rm -rf "$tmpdir"
  ok "Ollama ready: $USB_OLLAMA_BIN"
}

ensure_usb_ollama(){ [[ -x "$USB_OLLAMA_BIN" ]] || { err "Missing $USB_OLLAMA_BIN. Run 1) Download Ollama"; exit 1; }; }

# ---------- Shared table display function (DRY) ----------
display_models_table() {
  local -n model_list=$1  # Pass array by reference
  local show_requirements=${2:-true}  # Optional: show requirements column (default true)
  
  if [[ "$show_requirements" == "true" ]]; then
    # Full table with requirements
    echo "╔════╤══════════════════════════════╤════════════════════════════════════════╤══════════════════════════════════╗"
    echo "║ #  │ Model Name                   │ Requirements                           │ Model Info                       ║"
    echo "╟────┼──────────────────────────────┼────────────────────────────────────────┼──────────────────────────────────╢"
  else
    # Simple table without requirements
    echo "╔════╤══════════════════════════════╤══════════════════════════════════════╗"
    echo "║ #  │ Model Name                   │ Model Info                           ║"
    echo "╟────┼──────────────────────────────┼──────────────────────────────────────╢"
  fi
  
  local i=1
  for model_entry in "${model_list[@]}"; do
    # Handle catalog format (with |) or simple model names
    local name info
    if [[ "$model_entry" =~ \| ]]; then
      name="${model_entry%%|*}"
      info="${model_entry##*|}"
    else
      name="$model_entry"
      # Look up requirements from catalog if showing requirements
      if [[ "$show_requirements" == "true" ]]; then
        for catalog_entry in "${CATALOG[@]}"; do
          [[ "$catalog_entry" =~ ^[[:space:]]*# ]] && continue
          local cat_name="${catalog_entry%%|*}"
          if [[ "$cat_name" == "$name" ]]; then
            info="${catalog_entry##*|}"
            break
          fi
        done
      fi
    fi
    
    local model_info; model_info="$(get_model_info "$name")"
    
    if [[ "$show_requirements" == "true" && -n "$info" ]]; then
      # Color-code the requirements based on hardware type and add symbols
      local color_start="" color_end="" symbol=""
      if [[ "$info" =~ ^\[CPU\] ]]; then
        color_start=$'\033[32m'  # Green
        color_end=$'\033[0m'
        symbol="✓"  # Checkmark for easy to run
      elif [[ "$info" =~ ^\[CPU/GPU\] ]]; then
        color_start=$'\033[33m'  # Yellow
        color_end=$'\033[0m'
        symbol="⚠"  # Warning symbol
      elif [[ "$info" =~ ^\[GPU\] ]]; then
        color_start=$'\033[31m'  # Red
        color_end=$'\033[0m'
        symbol="✗"  # X mark for difficult
      fi
      
      # Add symbol to info if present
      local info_display="$info"
      if [[ -n "$symbol" ]]; then
        info_display="$symbol $info"
      fi
      
      # Calculate padding for colored text (38 chars for requirements column)
      local info_len=${#info_display}
      local padding=$((38 - info_len))
      local spaces=""
      for ((p=0; p<padding; p++)); do spaces+=" "; done
      
      # Calculate padding for model info column
      local model_info_len=${#model_info}
      local model_info_padding=$((32 - model_info_len))
      local model_info_spaces=""
      for ((p=0; p<model_info_padding; p++)); do model_info_spaces+=" "; done
      
      # Print row with requirements
      printf "║ %-2d │ %-28s │ %s%s%s%s │ %s%s ║\n" "$i" "$name" "$color_start" "$info_display" "$color_end" "$spaces" "$model_info" "$model_info_spaces"
    else
      # Simple row without requirements
      local model_info_len=${#model_info}
      local model_info_padding=$((36 - model_info_len))
      local model_info_spaces=""
      for ((p=0; p<model_info_padding; p++)); do model_info_spaces+=" "; done
      
      printf "║ %-2d │ %-28s │ %s%s ║\n" "$i" "$name" "$model_info" "$model_info_spaces"
    fi
    ((i++))
  done
  
  if [[ "$show_requirements" == "true" ]]; then
    echo "╚════╧══════════════════════════════╧════════════════════════════════════════╧══════════════════════════════════╝"
  else
    echo "╚════╧══════════════════════════════╧══════════════════════════════════════╝"
  fi
}

# ---------- Catalog UI (with colors) ----------
show_catalog(){
  print_hw_summary
  echo ""
  
  # Filter out comment lines from catalog
  local filtered_catalog=()
  for row in "${CATALOG[@]}"; do
    [[ "$row" =~ ^[[:space:]]*# ]] && continue
    filtered_catalog+=("$row")
  done
  
  display_models_table filtered_catalog true
  echo ""
  echo "Enter model numbers (comma-separated), e.g.: 1,3,7 or 'q' to cancel"
}

# ---------- Model ops ----------
pull_model_to_usb(){
  local model="$1"
  ensure_usb_ollama
  precheck_swap_for_model "$model"
  info "Starting temporary server for model download..."
  OLLAMA_MODELS="$MODELS_DIR" "$USB_OLLAMA_BIN" serve >/dev/null 2>&1 &
  local SERVEPID=$!
  sleep 2
  info "Downloading '$model' to USB (OLLAMA_MODELS=$MODELS_DIR)..."
  OLLAMA_MODELS="$MODELS_DIR" "$USB_OLLAMA_BIN" pull "$model"
  kill "$SERVEPID" 2>/dev/null || true
  ok "Model saved to USB."
}

list_usb_models_raw(){ 
  ensure_usb_ollama
  OLLAMA_MODELS="$MODELS_DIR" "$USB_OLLAMA_BIN" serve >/dev/null 2>&1 &
  local SERVEPID=$!
  sleep 1
  OLLAMA_MODELS="$MODELS_DIR" "$USB_OLLAMA_BIN" list 2>/dev/null | awk 'NR>1{print $1}'
  kill "$SERVEPID" 2>/dev/null || true
}

download_from_catalog(){
  show_catalog
  read -r -p "Selection: " selection
  [[ -n "${selection:-}" ]] || { warn "No models selected."; return; }
  IFS=',' read -r -a arr <<< "$selection"
  for idx in "${arr[@]}"; do
    local n="$(echo "$idx" | xargs)"
    [[ "$n" =~ ^[0-9]+$ ]] || { warn "Skipping: $n"; continue; }
    (( n>=1 && n<=${#CATALOG[@]} )) || { warn "Out of range: $n"; continue; }
    local name="${CATALOG[$((n-1))]%%|*}"
    pull_model_to_usb "$name"
  done
}

download_by_name(){ read -r -p "Model name (e.g. qwen2.5-coder:3b): " M; [[ -n "${M:-}" ]] && pull_model_to_usb "$M" || warn "No name entered."; }

# ---------- Offline install & selective import ----------
install_ollama_offline(){
  [[ -f "$TARBALL_PATH" ]] || { err "No tarball: $TARBALL_PATH (run option 1 first)"; exit 1; }
  if [[ $EUID -ne 0 ]]; then warn "sudo required for installation."; sudo true || { err "No sudo"; exit 1; }; fi
  info "Installing /usr/local/bin/ollama and systemd service..."
  tmpdir="$(mktemp -d)"; tar -xzf "$TARBALL_PATH" -C "$tmpdir"
  sudo install -m 0755 "$tmpdir/bin/ollama" /usr/local/bin/ollama; rm -rf "$tmpdir"
  sudo mkdir -p /var/lib/ollama
  sudo chown -R "$USER:$USER" /var/lib/ollama
  sudo chmod -R 755 /var/lib/ollama
  sudo bash -c 'cat > /etc/systemd/system/ollama.service' <<EOF
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
  sudo systemctl daemon-reload; sudo systemctl enable ollama; sudo systemctl start ollama
  ok "Ollama installed and started."
  selective_import
}

copy_model_to_system(){
  local model="$1"
  info "Copying '$model' from USB to system..."
  
  # Extract model name and tag
  local model_name="${model%%:*}"
  local model_tag="${model##*:}"
  [[ "$model_name" == "$model_tag" ]] && model_tag="latest"
  
  # Check if model exists on USB
  if [[ ! -d "$MODELS_DIR/manifests/registry.ollama.ai/$model_name" ]] && \
     [[ ! -d "$MODELS_DIR/manifests/registry.ollama.ai/library/$model_name" ]]; then
    err "Model '$model' not found on USB."
    return 1
  fi
  
  # Use rsync to copy model files (preserves structure)
  info "Syncing model files to /var/lib/ollama..."
  sudo mkdir -p /var/lib/ollama/{manifests,blobs}
  
  # Copy manifests
  if [[ -d "$MODELS_DIR/manifests/registry.ollama.ai/$model_name" ]]; then
    sudo rsync -a "$MODELS_DIR/manifests/registry.ollama.ai/$model_name" /var/lib/ollama/manifests/registry.ollama.ai/ 2>/dev/null || true
  fi
  if [[ -d "$MODELS_DIR/manifests/registry.ollama.ai/library/$model_name" ]]; then
    sudo rsync -a "$MODELS_DIR/manifests/registry.ollama.ai/library/$model_name" /var/lib/ollama/manifests/registry.ollama.ai/library/ 2>/dev/null || true
  fi
  
  # Copy all blobs (safer to copy all since tracking dependencies is complex)
  sudo rsync -a "$MODELS_DIR/blobs/" /var/lib/ollama/blobs/ 2>/dev/null || true
  
  # Fix permissions
  sudo chown -R "$USER:$USER" /var/lib/ollama
  
  ok "Model '$model' copied to system."
}

selective_import(){
  echo; info "Selective model import wizard (USB -> system):"
  
  if [[ $EUID -ne 0 ]]; then
    warn "Model import requires sudo for copying to /var/lib/ollama."
    sudo true || { err "No sudo permissions. Cancelling."; return; }
  fi
  
  local models; models="$(list_usb_models_raw || true)"
  if [[ -z "$models" ]]; then warn "No models on USB."; return; fi
  print_hw_summary
  echo ""
  mapfile -t L <<< "$models"
  display_models_table L true
  echo
  read -r -p "Select numbers to import (comma-separated) or 'all': " selection
  if [[ "${selection:-}" == "all" ]]; then
    info "Copying all models (using full sync for efficiency)..."
    sudo mkdir -p /var/lib/ollama
    sudo rsync -a "$MODELS_DIR/" /var/lib/ollama/
    sudo chown -R "$USER:$USER" /var/lib/ollama
    sudo systemctl restart ollama 2>/dev/null || true
    ok "All models imported."; return
  fi
  [[ -n "${selection:-}" ]] || { warn "No models selected."; return; }
  IFS=',' read -r -a arr <<< "$selection"
  for idx in "${arr[@]}"; do
    local n="$(echo "$idx" | xargs)"
    [[ "$n" =~ ^[0-9]+$ ]] || { warn "Skipping: $n"; continue; }
    (( n>=1 && n<=${#L[@]} )) || { warn "Out of range: $n"; continue; }
    local model="${L[$((n-1))]}"
    copy_model_to_system "$model"
  done
  sudo chown -R "$USER:$USER" /var/lib/ollama
  sudo systemctl restart ollama 2>/dev/null || true
  ok "Import completed. Ollama service restarted."
}

# ---------- List downloaded models ----------
list_downloaded_models(){
  echo
  echo "Choose source to list models from:"
  echo "1) USB models"
  echo "2) System models"
  echo "3) Both"
  read -r -p "Choice [1/2/3]: " choice
  
  case "${choice:-1}" in
    1)
      ensure_usb_ollama
      local models; models="$(list_usb_models_raw || true)"
      if [[ -z "$models" ]]; then
        warn "No models found on USB."
        return
      fi
      print_hw_summary
      echo ""
      echo "=== USB Models ==="
      mapfile -t L <<< "$models"
      display_models_table L true
      ;;
    2)
      if ! command -v ollama &>/dev/null; then
        warn "Ollama not installed on system."
        return
      fi
      local models; models="$(ollama list 2>/dev/null | awk 'NR>1{print $1}')"
      if [[ -z "$models" ]]; then
        warn "No models found on system."
        return
      fi
      print_hw_summary
      echo ""
      echo "=== System Models ==="
      mapfile -t L <<< "$models"
      display_models_table L true
      ;;
    3)
      # Show both
      local usb_models system_models
      ensure_usb_ollama
      usb_models="$(list_usb_models_raw || true)"
      if command -v ollama &>/dev/null; then
        system_models="$(ollama list 2>/dev/null | awk 'NR>1{print $1}')"
      fi
      
      print_hw_summary
      
      if [[ -n "$usb_models" ]]; then
        echo ""
        echo "=== USB Models ==="
        mapfile -t L <<< "$usb_models"
        display_models_table L true
      else
        echo ""
        warn "No models found on USB."
      fi
      
      if [[ -n "$system_models" ]]; then
        echo ""
        echo "=== System Models ==="
        mapfile -t L <<< "$system_models"
        display_models_table L true
      else
        echo ""
        warn "No models found on system."
      fi
      ;;
    *)
      warn "Invalid choice."
      ;;
  esac
}

# ---------- Launch & run ----------
launch_ollama_and_run(){
  echo
  echo "Choose execution source:"
  echo "1) System (systemd /var/lib/ollama)"
  echo "2) USB (temporary server; OLLAMA_MODELS=$MODELS_DIR)"
  read -r -p "Choice [1/2]: " choice
  local SERVEPID=""
  local use_usb=0
  case "${choice:-1}" in
    2)
      ensure_usb_ollama
      info "Starting temporary server from USB..."
      OLLAMA_MODELS="$MODELS_DIR" "$USB_OLLAMA_BIN" serve >/dev/null 2>&1 &
      SERVEPID=$!
      sleep 2
      use_usb=1
      ;;
  esac

  print_hw_summary
  info "Checking available models in selected source..."
  local models
  if (( use_usb == 1 )); then
    models="$(OLLAMA_MODELS="$MODELS_DIR" "$USB_OLLAMA_BIN" list 2>/dev/null | awk 'NR>1{print $1}')"
  else
    # Check if ollama service is running (system mode)
    if ! systemctl is-active --quiet ollama 2>/dev/null; then
      err "Ollama service is not running!"
      info "Checking service status..."
      systemctl status ollama --no-pager -l 2>&1 | head -20 || true
      echo
      warn "Try fixing with: sudo systemctl restart ollama"
      warn "Or check logs with: journalctl -u ollama -n 50"
      return
    fi
    models="$(ollama list 2>/dev/null | awk 'NR>1{print $1}')"
  fi
  
  if [[ -z "$models" ]]; then
    warn "No available models found." ; [[ -n "$SERVEPID" ]] && kill "$SERVEPID" 2>/dev/null || true; return
  fi
  echo ""
  mapfile -t L <<< "$models"
  display_models_table L true
  echo
  read -r -p "Select model to run (number): " sel
  [[ "$sel" =~ ^[0-9]+$ ]] || { warn "Invalid selection."; [[ -n "$SERVEPID" ]] && kill "$SERVEPID" 2>/dev/null || true; return; }
  (( sel>=1 && sel<=${#L[@]} )) || { warn "Out of range."; [[ -n "$SERVEPID" ]] && kill "$SERVEPID" 2>/dev/null || true; return; }
  local model="${L[$((sel-1))]}"

  # Suggest SWAP if needed before running heavy model
  precheck_swap_for_model "$model"

  echo; info "Running '$model' (Ctrl+C to exit)..."
  if (( use_usb == 1 )); then
    OLLAMA_MODELS="$MODELS_DIR" "$USB_OLLAMA_BIN" run "$model" || true
  else
    ollama run "$model" || true
  fi
  [[ -n "$SERVEPID" ]] && kill "$SERVEPID" 2>/dev/null || true
}

# ---------- Updates ----------
update_ollama_online() {
  require_cmd curl
  info "Downloading latest Ollama version (Linux amd64)..."
  mkdir -p "$TARBALL_DIR"
  curl -fL "$OLLAMA_TARBALL_URL_LINUX_AMD64" -o "$TARBALL_PATH"
  ok "Tarball updated: $TARBALL_PATH"

  info "Updating binary on USB..."
  tmpdir="$(mktemp -d)"
  tar -xzf "$TARBALL_PATH" -C "$tmpdir"
  [[ -f "$tmpdir/bin/ollama" ]] || { err "'bin/ollama' not found in tarball."; rm -rf "$tmpdir"; return 1; }
  mv "$tmpdir/bin/ollama" "$USB_OLLAMA_BIN"; chmod +x "$USB_OLLAMA_BIN"; rm -rf "$tmpdir"
  ok "Updated ollama on USB: $USB_OLLAMA_BIN"

  echo
  read -r -p "Also update local system (if installed)? (yes/no): " ans
  if [[ "$ans" =~ ^[Yy][Ee]?[Ss]?$ ]]; then
    if [[ $EUID -ne 0 ]]; then sudo true || { warn "No sudo; skipping system update."; return 0; }; fi
    tmp2="$(mktemp -d)"; tar -xzf "$TARBALL_PATH" -C "$tmp2"
    sudo install -m 0755 "$tmp2/bin/ollama" /usr/local/bin/ollama
    rm -rf "$tmp2"
    sudo systemctl daemon-reload 2>/dev/null || true
    sudo systemctl restart ollama 2>/dev/null || true
    ok "Updated system ollama and restarted."
  fi
}

update_models_online_from_catalog() {
  show_catalog
  read -r -p "Select numbers to update (comma-separated), or empty to cancel: " selection
  [[ -z "${selection:-}" ]] && { warn "Cancelled."; return; }
  IFS=',' read -r -a arr <<< "$selection"
  for idx in "${arr[@]}"; do
    n="$(echo "$idx" | xargs)"
    [[ "$n" =~ ^[0-9]+$ ]] || { warn "Skipping: $n"; continue; }
    (( n>=1 && n<=${#CATALOG[@]} )) || { warn "Out of range: $n"; continue; }
    name="${CATALOG[$((n-1))]%%|*}"
    pull_model_to_usb "$name"
  done
  ok "Catalog update completed."
}

update_models_online_existing_usb() {
  ensure_usb_ollama
  models="$(list_usb_models_raw || true)"
  if [[ -z "$models" ]]; then warn "No existing models found on USB."; return; fi
  echo "== Existing Models on USB =="
  i=1; mapfile -t L <<< "$models"
  for m in "${L[@]}"; do printf "%2d) %s\n" "$i" "$m"; ((i++)); done
  echo
  read -r -p "Select numbers to update (comma-separated), or 'all': " selection
  if [[ "${selection:-}" == "all" ]]; then
    for m in "${L[@]}"; do
      pull_model_to_usb "$m"
    done
    ok "All USB models updated."
    return
  fi
  [[ -z "${selection:-}" ]] && { warn "Cancelled."; return; }
  IFS=',' read -r -a arr <<< "$selection"
  for idx in "${arr[@]}"; do
    n="$(echo "$idx" | xargs)"
    [[ "$n" =~ ^[0-9]+$ ]] || { warn "Skipping: $n"; continue; }
    (( n>=1 && n<=${#L[@]} )) || { warn "Out of range: $n"; continue; }
    m="${L[$((n-1))]}"
    pull_model_to_usb "$m"
  done
  ok "Selected models updated."
}

# Check (and optionally update) models online – shows current digest then pulls if you confirm
check_models_updates_online() {
  ensure_usb_ollama
  models="$(list_usb_models_raw || true)"
  if [[ -z "$models" ]]; then warn "No models on USB to check."; return; fi
  echo "== Check for updates (online) for USB models =="
  i=1; mapfile -t L <<< "$models"
  for m in "${L[@]}"; do printf "%2d) %s\n" "$i" "$m"; ((i++)); done
  echo
  read -r -p "Select numbers to check (comma-separated), or 'all': " selection
  selected=()
  if [[ "${selection:-}" == "all" ]]; then
    selected=("${L[@]}")
  elif [[ -n "${selection:-}" ]]; then
    IFS=',' read -r -a arr <<< "$selection"
    for idx in "${arr[@]}"; do
      n="$(echo "$idx" | xargs)"
      [[ "$n" =~ ^[0-9]+$ ]] || { warn "Skipping: $n"; continue; }
      (( n>=1 && n<=${#L[@]} )) || { warn "Out of range: $n"; continue; }
      selected+=("${L[$((n-1))]}")
    done
  else
    warn "Cancelled."; return
  fi

  for m in "${selected[@]}"; do
    echo
    info "Showing local version (digest) for $m:"
    OLLAMA_MODELS="$MODELS_DIR" "$USB_OLLAMA_BIN" show "$m" 2>/dev/null || true
    read -r -p "Try to pull update for $m now? (yes/no): " upd
    if [[ "$upd" =~ ^[Yy][Ee]?[Ss]?$ ]]; then
      pull_model_to_usb "$m"
    fi
  done
  ok "Check/update completed."
}

# ---------- Offline sync USB -> system ----------
sync_usb_models_to_system() {
  if [[ $EUID -ne 0 ]]; then
    warn "Syncing to system requires sudo."
    sudo true || { err "No sudo; cancelling."; return; }
  fi
  if [[ ! -d "$MODELS_DIR" || -z "$(ls -A "$MODELS_DIR" 2>/dev/null || true)" ]]; then
    warn "No models found on USB to sync."
    return
  fi
  info "Syncing USB -> /var/lib/ollama (including updates)..."
  sudo mkdir -p /var/lib/ollama
  sudo rsync -a --delete "$MODELS_DIR"/ /var/lib/ollama/
  sudo chown -R "$USER:$USER" /var/lib/ollama
  sudo systemctl restart ollama 2>/dev/null || true
  ok "Sync completed. Ollama service restarted."
}

# ---------- Launch Web UI ----------
launch_webui(){
  local webui_script="$USB_ROOT/ollama_webui.py"
  
  if [[ ! -f "$webui_script" ]]; then
    err "Web UI script not found: $webui_script"
    return 1
  fi
  
  # Check for Python
  if ! command -v python3 &>/dev/null; then
    err "Python 3 is not installed. Please install python3."
    return 1
  fi
  
  echo
  echo "Choose Web UI mode:"
  echo "1) System (use system Ollama)"
  echo "2) USB (portable mode)"
  read -r -p "Choice [1/2]: " choice
  
  local use_usb=0
  case "${choice:-1}" in
    2) use_usb=1 ;;
  esac
  
  # Check/install dependencies
  info "Checking Python dependencies..."
  if ! python3 -c "import gradio" 2>/dev/null; then
    warn "Gradio not installed. Attempting to install..."
    
    # Try installing without --user first (works in virtualenv)
    if python3 -m pip install gradio requests 2>/dev/null; then
      ok "Dependencies installed successfully!"
    # If that fails, try with --user flag
    elif python3 -m pip install --user gradio requests 2>/dev/null; then
      ok "Dependencies installed successfully!"
    else
      echo
      err "Failed to install dependencies automatically."
      echo
      echo "Please install manually using ONE of these commands:"
      echo "  1) pip3 install gradio requests"
      echo "  2) pip install gradio requests"
      echo "  3) python3 -m pip install gradio requests"
      echo
      read -r -p "Press Enter to continue after installing, or Ctrl+C to cancel..."
      
      # Check again
      if ! python3 -c "import gradio" 2>/dev/null; then
        err "Dependencies still not found. Exiting."
        return 1
      fi
    fi
  fi
  
  echo
  info "Starting Web UI..."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🌐 Web interface will open in your browser"
  echo "📍 Default URL: http://localhost:7860"
  echo "🛑 Press Ctrl+C to stop the server"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo
  
  if (( use_usb == 1 )); then
    ensure_usb_ollama
    info "Running in USB mode..."
    python3 "$webui_script" --models-dir "$MODELS_DIR" --ollama-bin "$USB_OLLAMA_BIN"
  else
    info "Running in System mode..."
    python3 "$webui_script"
  fi
}

# ---------- Menu ----------
while true; do
  echo
  echo "================== Offline AI USB Toolkit =================="
  echo "USB: $USB_ROOT"
  echo "Models dir (USB): $MODELS_DIR"
  echo
  echo "1)  Download Ollama (to USB)"
  echo "2)  Download models (catalog; multi-select, colored)"
  echo "3)  Download model by name"
  echo "4)  List downloaded models (USB/System)"
  echo "5)  Install Ollama (offline) + selective import"
  echo "6)  Launch Ollama (choose source & model; colored)"
  echo "7)  Launch Web UI (ChatGPT-like interface)"
  echo "8)  Import models (selective USB -> system)"
  echo "9)  Optimize memory (create swapfile)"
  echo "10) Update Ollama (online)"
  echo "11) Update models on USB (online)"
  echo "12) Sync USB -> system (offline)"
  echo "13) Check models for updates (online)"
  echo "q)  Quit"
  echo "============================================================"
  read -r -p "Select: " opt
  case "${opt:-}" in
    1)  download_ollama ;;
    2)  download_from_catalog ;;
    3)  download_by_name ;;
    4)  list_downloaded_models ;;
    5)  install_ollama_offline ;;
    6)  launch_ollama_and_run ;;
    7)  launch_webui ;;
    8)  selective_import ;;
    9)  create_swapfile_wizard ;;
    10) update_ollama_online ;;
    11) echo; echo "Choose model update mode:"
        echo "1) From catalog (multi-select, with color rating)"
        echo "2) From existing USB models"
        read -r -p "Choice [1/2]: " uopt
        case "${uopt:-1}" in
          2) update_models_online_existing_usb ;;
          *) update_models_online_from_catalog ;;
        esac
        ;;
    12) sync_usb_models_to_system ;;
    13) check_models_updates_online ;;
    q|Q) echo "Bye!"; exit 0 ;;
    *)  warn "Invalid selection." ;;
  esac
done

