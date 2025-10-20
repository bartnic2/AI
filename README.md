# WAN Video 2.2 - ComfyUI Automation

Automated setup for running **WAN Video 2.2 I2V-A14B** (Image-to-Video) on Vast.ai GPU rentals with ComfyUI.

## � What is WAN Video 2.2?

State-of-the-art open-source video generation model from Alibaba:
- **Image-to-Video:** Animate still images with text prompts
- **Resolution:** 480p or 720p @ 24fps
- **Architecture:** 27B parameter MoE (Mixture-of-Experts)
- **License:** Apache 2.0 (commercial use OK)

## 📁 Repository Structure

```
d:\AI\
├── startup/
│   ├── init.bash          # Automated setup script for Vast.ai
│   └── README.md          # Detailed setup documentation
├── workflows/
│   ├── Comfy_HunyuanVideo_I2V.json
│   ├── Hallett_Wan21_Exploding_Building_Tutorial.json
│   └── wan2.1_T2V_2.json
├── images/                # Sample images for testing
└── README.md              # This file
```

## 🚀 Quick Start

### Prerequisites
- Vast.ai account
- H100 or H200 GPU rental (80GB+ VRAM)
- Hugging Face account with token

### Setup Steps

1. **Get Hugging Face token:**
   - Visit https://huggingface.co/settings/tokens
   - Create "Read" token
   - Accept license: https://huggingface.co/Wan-AI/Wan2.2-I2V-A14B

2. **Configure Vast.ai template:**
   - Upload `startup/init.bash` to your instance
   - Set on-start command:
     ```bash
     export HF_TOKEN="hf_YOUR_TOKEN"; /bin/bash /workspace/init.bash
     ```

3. **Launch instance:**
   - First run: ~15 min (downloads models)
   - Access ComfyUI: `http://<instance-ip>:8188`

📖 **Full documentation:** See [`startup/README.md`](startup/README.md)

## 🎯 What This Repository Provides

### Automated Setup Script
The `startup/init.bash` script handles everything:
- ✅ Downloads WAN 2.2 models (~126GB)
- ✅ Installs ComfyUI plugins
- ✅ Configures Python environment
- ✅ Launches ComfyUI web interface

### Example Workflows
Pre-configured ComfyUI workflows in `workflows/`:
- Image-to-Video generation
- Text-to-Video generation  
- Advanced configurations with ControlNet

## 🔒 Security Note

⚠️ **ComfyUI has no built-in authentication!** Use one of these methods:

- **SSH Tunnel:** `ssh -L 8188:localhost:8188 root@<vast-ip>`
- **Cloudflare Tunnel:** `cloudflared tunnel --url http://localhost:8188`
- **IP Whitelist:** Configure in Vast.ai firewall

See [`startup/README.md`](startup/README.md) for detailed security setup

## � Models & Requirements

### Hardware
- **GPU:** H100 (80GB) or H200 (141GB) VRAM
- **Storage:** 150GB+ for models and workspace
- **Cost:** ~$2-4/hour on Vast.ai

### Downloaded Models (~126GB total)
| Component | Size | Purpose |
|-----------|------|---------|
| High-noise Transformer | 57GB | Early denoising (layout) |
| Low-noise Transformer | 57GB | Refinement (details) |
| Text Encoder (umt5-xxl) | 11.4GB | Text prompt encoding |
| CLIP Vision | 1.5GB | Image conditioning |
| VAE | 508MB | Latent decoding |

## 🛠️ Customization

The script is fully configurable. Common modifications:

**Use FP8 models (half the VRAM):**
```bash
# Edit startup/init.bash, replace download URLs:
https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/...
```

**Auto-sync workflows from GitHub:**
```bash
# Uncomment section 7 in startup/init.bash
WORKFLOW_REPO="https://github.com/youruser/yourrepo.git"
```

**Add custom ComfyUI plugins:**
```bash
# Add to section 5 in startup/init.bash
git clone https://github.com/author/plugin $PLUGIN_DIR/plugin
```

## 📚 Additional Resources

- **Official WAN 2.2:** https://github.com/Wan-Video/Wan2.2
- **Research Paper:** https://arxiv.org/abs/2503.20314
- **Hugging Face Models:** https://huggingface.co/Wan-AI
- **ComfyUI Docs:** https://docs.comfy.org/
- **Vast.ai Platform:** https://vast.ai/

## 💡 Tips & Tricks

- **Save as template:** After first successful run, save your Vast.ai instance as a template for instant future launches
- **FP8 for budget:** Use quantized models to run on cheaper GPUs (~40GB VRAM)
- **Batch generation:** Queue multiple prompts in ComfyUI to maximize GPU utilization
- **Monitor costs:** Stop instance immediately after use (models persist in template)

## 🤝 Contributing

Found improvements or created useful workflows? PRs welcome!

## � License

This setup script is MIT licensed. WAN 2.2 models use Apache 2.0 (see model repository for details).

---

**Questions?** Check the detailed docs in [`startup/README.md`](startup/README.md) or open an issue!
