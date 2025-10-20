# WAN 2.2 ComfyUI Setup for Vast.ai

Automated setup script for running **WAN Video 2.2 Image-to-Video (I2V-A14B)** on Vast.ai GPU instances with ComfyUI.

## 🎯 Overview

This script automatically:
- Downloads WAN 2.2 I2V-A14B models (~126GB total)
- Installs ComfyUI plugins (Kijai's WanVideoWrapper + VideoHelperSuite)
- Configures Python environment with all dependencies
- Launches ComfyUI ready for I2V generation

## 📋 Requirements

### Hardware (Vast.ai)
- **Recommended:** H100 (80GB) or H200 (141GB)
- **Minimum:** 80GB VRAM for FP16 models
- **Storage:** 150GB+ for models + workspace

### Software
- Docker image with ComfyUI pre-installed (e.g., `runpod/pytorch:2.1.0-py3.10-cuda12.1`)
- Port 8188 exposed for ComfyUI web interface

## 🚀 Setup Instructions

### 1. Get Hugging Face Token (Required)
WAN 2.2 models are gated and require authentication:
1. Visit https://huggingface.co/settings/tokens
2. Create a new token with "Read" access
3. Accept the model license at https://huggingface.co/Wan-AI/Wan2.2-I2V-A14B

### 2. Configure Vast.ai Template

**Option A: Interactive Setup (First Time)**
```bash
# On-start script
export HF_TOKEN="hf_YOUR_TOKEN_HERE"
export INIT_INTERACTIVE=1
/bin/bash /workspace/init.bash
```

**Option B: Auto-Start (After Testing)**
```bash
# On-start script
export HF_TOKEN="hf_YOUR_TOKEN_HERE"
/bin/bash /workspace/init.bash
```

### 3. Upload Script to Template
1. In Vast.ai, go to **Templates** → **Edit Template**
2. Under **Container Disk**, mount your startup script:
   - Source: Upload `init.bash`
   - Destination: `/workspace/init.bash`
3. Set execute permissions: `chmod +x /workspace/init.bash`

### 4. Launch Instance
1. Select an H100 or H200 instance
2. Use your configured template
3. Instance will auto-download models and start ComfyUI (~10-20 min first time)

## 🔐 Security & Access

### ComfyUI Has NO Built-in Authentication!
By default, anyone with your instance IP can access ComfyUI on port 8188.

**Secure Access Options:**

#### Option 1: SSH Tunnel (Recommended)
```bash
# On your local machine
ssh -L 8188:localhost:8188 root@<vast-instance-ip>
```
Then open http://localhost:8188 in your browser.

#### Option 2: Cloudflare Tunnel
```bash
# Inside the container
cloudflared tunnel --url http://localhost:8188 --no-autoupdate
```
Gives you a secure `https://random.trycloudflare.com` URL.

#### Option 3: Configure Vast.ai Firewall
- In Vast.ai, limit port 8188 to your IP only
- Still vulnerable if your IP changes

## 📦 Downloaded Models

The script downloads these files to `/workspace/ComfyUI/models/`:

| Component | Path | Size | Purpose |
|-----------|------|------|---------|
| High-noise Transformer | `diffusion_models/wan2.2_i2v_high_noise.safetensors` | ~57GB | Early denoising steps |
| Low-noise Transformer | `diffusion_models/wan2.2_i2v_low_noise.safetensors` | ~57GB | Refinement steps |
| Text Encoder | `text_encoders/umt5-xxl-enc-bf16.pth` | 11.4GB | Text prompt encoding |
| CLIP Vision | `clip_vision/siglip-so400m-patch14-384.safetensors` | ~1.5GB | Image conditioning |
| VAE | `vae/wan2.1_vae.pth` | 508MB | Latent decoding |

## 🎨 Using WAN 2.2 in ComfyUI

### Loading Models
1. Open ComfyUI at `http://<instance-ip>:8188`
2. Add nodes:
   - **WanVideoWrapper Model Loader** (from Kijai's nodes)
   - Load both high-noise and low-noise transformers
   - Load text encoder, CLIP, and VAE

### Image-to-Video Workflow
1. **Input Image** → CLIP Vision Encoder
2. **Text Prompt** (optional) → Text Encoder
3. **WanVideo Sampler** → Configure:
   - Resolution: 480p or 720p
   - Frames: 81 (default)
   - CFG scale: ~7.0
4. **VAE Decode** → Video output

Check the `workflows/` folder for example JSON files.

## 🔧 Configuration Options

### Environment Variables
- `HF_TOKEN`: Your Hugging Face access token (required)
- `INIT_INTERACTIVE=1`: Pause before starting ComfyUI (for debugging)

### Script Customization
Edit `init.bash` to:
- Change model download URLs
- Add custom ComfyUI plugins
- Sync workflows from your GitHub repo (see section 7 in script)
- Modify Python dependencies

## 🐛 Troubleshooting

### Models fail to download
- **Error:** `401 Unauthorized`
  - Check your HF_TOKEN is valid
  - Accept model license at https://huggingface.co/Wan-AI/Wan2.2-I2V-A14B
  
- **Error:** `Connection timeout`
  - Resume download: Script will skip already downloaded files
  - Or use `huggingface-cli download` manually

### Out of memory
- **80GB VRAM not enough?**
  - Try FP8 quantized models from https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled
  - Enable model offloading in ComfyUI settings

### ComfyUI won't start
- Check logs: `docker logs <container-id>`
- Verify entrypoint exists: `ls -la /workspace/ComfyUI/entrypoint.sh`
- Test interactive mode: `export INIT_INTERACTIVE=1`

## 📚 Resources

- **WAN 2.2 Docs:** https://github.com/Wan-Video/Wan2.2
- **Kijai's Plugin:** https://github.com/kijai/ComfyUI-WanVideoWrapper
- **ComfyUI Docs:** https://docs.comfy.org/
- **Vast.ai Guides:** https://vast.ai/docs/

## 🆚 WAN 2.1 vs 2.2

**WAN 2.2 Improvements:**
- Mixture-of-Experts (MoE) architecture → 27B params, only 14B active per step
- Better motion quality and aesthetic control
- Supports both 480p and 720p at 24fps
- More stable camera movements

**Note:** Your script was set up for WAN 2.1. I've updated it to WAN 2.2, which is the latest and recommended version as of October 2025.

## 💾 Saving Your Setup

Once models are downloaded and ComfyUI works:
1. In Vast.ai, **Save Instance as Template**
2. Name it: "WAN 2.2 + ComfyUI - H100"
3. Next spin-up will be instant (no re-download)

## 🔄 Updating Models

To update to newer WAN versions:
1. Edit `init.bash` URLs
2. Delete old model files in `/workspace/ComfyUI/models/`
3. Restart instance

## 📝 Notes

- **H100 vs H200:** Both are single GPUs (not clusters). H200 has more VRAM (141GB vs 80GB) but costs more.
- **FP16 vs FP8:** FP16 = full precision (better quality, 80GB VRAM). FP8 = quantized (faster, ~40GB VRAM, slight quality loss).
- **First run:** Expect 10-20 min for all downloads. Subsequent runs: instant if models cached.
