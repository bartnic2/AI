# WAN 2.2 ComfyUI Setup Script

Automated initialization script for running **WAN Video 2.2 I2V-A14B** on Vast.ai with ComfyUI.

## 📁 Files in This Directory

- **`init.bash`** - Main startup script (run on Vast.ai instance boot)
- **`README.md`** - This documentation file

## 🚀 Quick Start

### 1. Get Hugging Face Token
1. Visit https://huggingface.co/settings/tokens
2. Click "Create new token" and set type to "Read" access
3. Copy the token value (starts with `hf_`) for use in env vars below
4. Visit https://huggingface.co/Wan-AI/Wan2.2-I2V-A14B
5. Click "Agree and access repository"

### 2. Create Vast.ai Template

**Step-by-step:**

1. **Go to Vast.ai** → Templates → Create New Template (or edit existing ComfyUI template)

2. **Select Base Image:**
   - Use a ComfyUI-ready Docker image, e.g.:
   - `runpod/pytorch:2.1.0-py3.10-cuda12.1`
   - Or any image with Python 3.10+ and CUDA 12.1+

3. **Set Environment Variables:**
   Click "Add Environment Variable" and add:
   
   | Name | Value |
   |------|-------|
   | `HF_TOKEN` | Paste your `hf_...` token here |
   | `INIT_INTERACTIVE` | `1` (for first run debugging) |

4. **Set On-start Script:**
   In the "On-start Script" text box, paste:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/bartnic2/AI/main/startup/init.bash | bash
   ```

5. **Configure Storage:**
   - **Container disk size:** Set to **200 GB** minimum
   - Models need ~126GB, rest for workspace

6. **Set Launch Mode:**
   - For first run: **"Interactive Shell Server, SSH"**
   - Allows you to monitor progress and debug if needed

7. **Expose Ports:**
   - Ensure port **8188** is exposed (for ComfyUI web interface)

8. **Save Template:**
   - Name it: "WAN 2.2 ComfyUI - Auto Setup"
   - Save for future use

### 3. Launch Instance

1. **Select GPU:**
   - Filter for: H100 (80GB) or H200 (141GB)
   - Recommended: H100 (best value for WAN 2.2)

2. **Choose your template** from dropdown

3. **Click "Rent"**

4. **Monitor Progress:**
   - SSH into instance: `ssh root@<instance-ip>`
   - Watch setup: Script will show progress of downloads
   - Expected time: 15-20 minutes first run

5. **Access ComfyUI:**
   - Once script completes, ComfyUI auto-starts
   - Browse to: `http://<instance-ip>:8188`
   - Or use SSH tunnel: `ssh -L 8188:localhost:8188 root@<instance-ip>`

6. **After Success:**
   - **Remove** `INIT_INTERACTIVE=1` from environment variables
   - In Vast.ai: **"Save Instance as Template"**
   - Name: "WAN 2.2 + ComfyUI (Ready)"
   - Future launches: ~30 seconds (models cached!)

## 📦 What the Script Does

1. **Creates directories** for models in `/workspace/ComfyUI/models/`
2. **Downloads WAN 2.2 models** (~126GB):
   - High-noise transformer (57GB)
   - Low-noise transformer (57GB)
   - Text encoder (11.4GB)
   - CLIP Vision (1.5GB)
   - VAE (508MB)
3. **Installs ComfyUI plugins**:
   - ComfyUI-WanVideoWrapper (Kijai's wrapper)
   - VideoHelperSuite (video utilities)
4. **Installs Python dependencies**:
   - PyTorch + CUDA 12.1
   - Transformers, accelerate, etc.
   - Flash Attention (optional)
5. **Launches ComfyUI** on port 8188

## 🔧 Configuration

### Environment Variables (Set in Vast.ai Template)

| Variable | Required | Value | Description |
|----------|----------|-------|-------------|
| `HF_TOKEN` | ✅ Yes | `hf_xxx...` | Your Hugging Face access token |
| `INIT_INTERACTIVE` | ❌ No | `1` | Set to pause before starting ComfyUI (for debugging) |

**Where to set:** In Vast.ai template config → "Environment Variables" section

### Script Customization

Edit `init.bash` to customize:

**Model sources** (lines 42-68):
```bash
download_if_missing "https://huggingface.co/Wan-AI/..." "$DIFF_DIR/..."
```

**Plugin selection** (lines 77-100):
```bash
git clone https://github.com/kijai/ComfyUI-WanVideoWrapper ...
```

**Python packages** (lines 103-112):
```bash
pip install torch torchvision torchaudio ...
```

**Workflow sync** (lines 114-123):
Uncomment to auto-sync workflows from your GitHub repo.

## 🔐 Security

⚠️ **ComfyUI has NO authentication by default!**

### Secure Access Methods

**Option 1: SSH Tunnel** (recommended)
```bash
ssh -L 8188:localhost:8188 root@<vast-ip>
# Then browse to http://localhost:8188
```

**Option 2: Cloudflare Tunnel**
```bash
cloudflared tunnel --url http://localhost:8188 --no-autoupdate
```

**Option 3: Vast.ai Firewall**
- Configure IP whitelist in Vast.ai dashboard
- Limit port 8188 to your IP only

## 🐛 Troubleshooting

### Download Failures

**Error: `401 Unauthorized`**
```
Solution: 
1. Check HF_TOKEN is set correctly in Vast.ai Environment Variables
2. Verify token is valid: https://huggingface.co/settings/tokens
3. Visit https://huggingface.co/Wan-AI/Wan2.2-I2V-A14B
4. Click "Agree and access repository"
```

**Error: `HF_TOKEN not set`**
```
Solution:
1. In Vast.ai template, go to Environment Variables section
2. Add: HF_TOKEN = hf_YOUR_TOKEN_HERE
3. Restart instance
```

**Error: `Connection timeout`**
```
Solution: Script auto-resumes (skips existing files)
Just re-run: /bin/bash /workspace/init.bash
```

### Out of Memory

**80GB VRAM not enough?**
```
Solution 1: Use FP8 models
wget https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/...

Solution 2: Enable model offloading in ComfyUI settings
```

### ComfyUI Won't Start

**Check entrypoint exists:**
```bash
ls -la /workspace/ComfyUI/entrypoint.sh
```

**View logs:**
```bash
docker logs <container-id>
tail -f /workspace/ComfyUI/comfyui.log
```

**Test interactive mode:**
```bash
export INIT_INTERACTIVE=1
/bin/bash /workspace/init.bash
# Then manually: /workspace/ComfyUI/entrypoint.sh
```

## 📊 Model Details

### WAN 2.2 I2V-A14B Architecture

**Mixture-of-Experts (MoE):**
- **Total params:** 27B
- **Active per step:** 14B (~14B VRAM)
- **High-noise expert:** Steps 1-15 (layout, composition)
- **Low-noise expert:** Steps 16-30 (details, refinement)

Both models are **required** and loaded together in ComfyUI.

### Downloaded Files

```
/workspace/ComfyUI/models/
├── diffusion_models/
│   ├── wan2.2_i2v_high_noise.safetensors  (57GB)
│   └── wan2.2_i2v_low_noise.safetensors   (57GB)
├── text_encoders/
│   └── umt5-xxl-enc-bf16.pth              (11.4GB)
├── clip_vision/
│   └── siglip-so400m-patch14-384.safetensors (1.5GB)
└── vae/
    └── wan2.1_vae.pth                     (508MB)
```

## 🎨 Using in ComfyUI

1. Open ComfyUI: `http://<vast-ip>:8188`
2. Load workflow from `../workflows/` folder
3. Or create new workflow:
   - **WanVideoWrapper Model Loader**
   - **Load Image** → CLIP Vision
   - **Text Prompt** → Text Encoder  
   - **WanVideo Sampler** (480p or 720p, 81 frames)
   - **VAE Decode** → Save Video

## 📚 Resources

- **WAN 2.2 Paper:** https://arxiv.org/abs/2503.20314
- **Official Repo:** https://github.com/Wan-Video/Wan2.2
- **Kijai's Wrapper:** https://github.com/kijai/ComfyUI-WanVideoWrapper
- **ComfyUI Docs:** https://docs.comfy.org/
- **Hugging Face Models:** https://huggingface.co/Wan-AI

## 💾 Saving Your Setup

After first successful run:

1. In Vast.ai: **Save Instance as Template**
2. Name: "WAN 2.2 + ComfyUI - H100"
3. Next launches: Instant startup (models cached in template)

## 🔄 Updating

To upgrade to newer WAN versions:

1. Check for new models: https://huggingface.co/Wan-AI
2. Update URLs in `init.bash` (lines 42-68)
3. Delete old models: `rm -rf /workspace/ComfyUI/models/diffusion_models/*`
4. Re-run: `/bin/bash /workspace/init.bash`

## 📝 Notes

- **H100:** 80GB VRAM, $2-3/hr on Vast.ai
- **H200:** 141GB VRAM, $4-6/hr (overkill for WAN 2.2)
- **FP16:** Full precision, best quality, 80GB VRAM
- **FP8:** Quantized, 2x faster, ~40GB VRAM, 95% quality

First download takes 10-20 minutes depending on connection speed.
