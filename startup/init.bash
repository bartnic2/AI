#!/bin/bash
set -e

# Uncomment to enable interactive mode (pauses before starting ComfyUI)
# INIT_INTERACTIVE=1

echo "=== WAN Video 2.2 I2V-A14B Setup for ComfyUI ==="
echo "Target GPU: H100/H200 (80GB+ VRAM)"

# --- 1. Define model directories ---
BASE_DIR="/workspace/ComfyUI/models"
DIFF_DIR="$BASE_DIR/diffusion_models"
VAE_DIR="$BASE_DIR/vae"
TEXT_DIR="$BASE_DIR/text_encoders"
CLIP_DIR="$BASE_DIR/clip_vision"

mkdir -p "$DIFF_DIR" "$VAE_DIR" "$TEXT_DIR" "$CLIP_DIR"

# --- 2. Set Hugging Face token (REQUIRED for gated models) ---
# Option A: Set token directly in script (REPLACE WITH YOUR ACTUAL TOKEN)
# export HF_TOKEN="hf_your_actual_token_here"

# Option B: Token is already set by Vast.ai on-start script (recommended)
# In your Vast.ai template: export HF_TOKEN="..." before calling this script

if [ -z "$HF_TOKEN" ]; then
    echo "WARNING: HF_TOKEN not set. You may need it for gated WAN models."
    echo "Get token from: https://huggingface.co/settings/tokens"
    echo ""
    echo "To fix: Either uncomment and set HF_TOKEN above, or set it in Vast.ai on-start script"
fi

# --- 3. Download helper function ---
download_if_missing () {
    local url="$1"
    local dest="$2"
    if [ ! -f "$dest" ]; then
        echo "Downloading $(basename "$dest")..."
        if [ -n "$HF_TOKEN" ]; then
            wget -q --show-progress --header="Authorization: Bearer $HF_TOKEN" -O "$dest" "$url"
        else
            wget -q --show-progress -O "$dest" "$url"
        fi
    else
        echo "✓ $(basename "$dest") already exists, skipping."
    fi
}

# --- 4. Download WAN 2.2 I2V-A14B Models ---
echo ""
echo "Downloading WAN 2.2 I2V-A14B models (this may take a while)..."

# Main transformer models (MoE architecture - two experts)
# High-noise expert for early denoising steps
download_if_missing "https://huggingface.co/Wan-AI/Wan2.2-I2V-A14B/resolve/main/high_noise_model/diffusion_pytorch_model.safetensors" \
    "$DIFF_DIR/wan2.2_i2v_high_noise.safetensors"

# Low-noise expert for refinement steps
download_if_missing "https://huggingface.co/Wan-AI/Wan2.2-I2V-A14B/resolve/main/low_noise_model/diffusion_pytorch_model.safetensors" \
    "$DIFF_DIR/wan2.2_i2v_low_noise.safetensors"

# Text Encoder (umt5-xxl in bfloat16)
download_if_missing "https://huggingface.co/Wan-AI/Wan2.2-I2V-A14B/resolve/main/models_t5_umt5-xxl-enc-bf16.pth" \
    "$TEXT_DIR/umt5-xxl-enc-bf16.pth"

# CLIP Vision Encoder (from Google subfolder)
download_if_missing "https://huggingface.co/Wan-AI/Wan2.2-I2V-A14B/resolve/main/google/siglip-so400m-patch14-384/model.safetensors" \
    "$CLIP_DIR/siglip-so400m-patch14-384.safetensors"

# VAE (still using 2.1 VAE)
download_if_missing "https://huggingface.co/Wan-AI/Wan2.2-I2V-A14B/resolve/main/Wan2.1_VAE.pth" \
    "$VAE_DIR/wan2.1_vae.pth"

echo ""
echo "✓ All models downloaded!"

# --- 5. Install ComfyUI plugins ---
PLUGIN_DIR="/workspace/ComfyUI/custom_nodes"
mkdir -p "$PLUGIN_DIR"

echo ""
echo "Installing ComfyUI plugins..."

# Kijai's WanVideoWrapper - most actively maintained, supports WAN 2.2
if [ ! -d "$PLUGIN_DIR/ComfyUI-WanVideoWrapper" ]; then
    echo "Installing ComfyUI-WanVideoWrapper..."
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper "$PLUGIN_DIR/ComfyUI-WanVideoWrapper"
    cd "$PLUGIN_DIR/ComfyUI-WanVideoWrapper"
    pip install -r requirements.txt
    cd -
else
    echo "✓ ComfyUI-WanVideoWrapper already installed"
fi

# Video helper utilities
if [ ! -d "$PLUGIN_DIR/ComfyUI-VideoHelperSuite" ]; then
    echo "Installing VideoHelperSuite..."
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite "$PLUGIN_DIR/ComfyUI-VideoHelperSuite"
    cd "$PLUGIN_DIR/ComfyUI-VideoHelperSuite"
    pip install -r requirements.txt
    cd -
else
    echo "✓ VideoHelperSuite already installed"
fi

# --- 6. Install Python dependencies ---
echo ""
echo "Installing Python dependencies..."
pip install --upgrade pip
# CUDA 12.1 PyTorch (adjust if your image uses different CUDA version)
pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu121
pip install transformers sentencepiece accelerate opencv-python pillow huggingface-hub

# Flash Attention (optional but recommended for speed)
pip install flash-attn --no-build-isolation || echo "⚠ Flash-attn install failed (not critical)"

# --- 7. (Optional) Load custom workflows from repo ---
# Uncomment and configure to auto-sync your custom workflows
# echo ""
# echo "Syncing custom workflows from GitHub..."
# WORKFLOW_REPO="https://github.com/<youruser>/<yourrepo>.git"
# WORKFLOW_TEMP="/tmp/workflow_sync"
# git clone "$WORKFLOW_REPO" "$WORKFLOW_TEMP"
# mkdir -p /workspace/ComfyUI/user/default/workflows
# cp "$WORKFLOW_TEMP/workflows/"*.json /workspace/ComfyUI/user/default/workflows/ || true
# cp "$WORKFLOW_TEMP/models/loras/"*.safetensors /workspace/ComfyUI/models/loras/ || true
# rm -rf "$WORKFLOW_TEMP"

# --- 8. Interactive shell or auto-start? ---
# Set INIT_INTERACTIVE=1 to pause before launching ComfyUI (for debugging/tweaking)
if [ "$INIT_INTERACTIVE" = "1" ]; then
    echo ""
    echo "=== INTERACTIVE MODE ==="
    echo "Init complete. Dropping to shell. Run 'entrypoint.sh' to start ComfyUI."
    exec /bin/bash
fi

# --- 9. Start ComfyUI ---
echo ""
echo "=== Starting ComfyUI ==="
echo "Access via: http://<vast-instance-ip>:8188"
echo "Tunnel securely: ssh -L 8188:localhost:8188 root@<instance-ip>"
echo ""
exec /workspace/ComfyUI/entrypoint.sh
