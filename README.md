[![Watch the video](https://i3.ytimg.com/vi/JovhfHhxqdM/hqdefault.jpg)](https://www.youtube.com/watch?v=JovhfHhxqdM)

Run the latest ComfyUI. First start installs dependencies (takes a few minutes), then when you see this in the logs, ComfyUI is ready to be used: `[ComfyUI-Manager] All startup tasks have been completed.`

## Access

- `8188`: ComfyUI web UI
- `8080`: FileBrowser (admin / adminadmin12)
- `8888`: JupyterLab (token via `JUPYTER_PASSWORD`, root at `/workspace`)
- `22`: SSH (set `PUBLIC_KEY` or check logs for generated root password)

## Pre-installed custom nodes

- ComfyUI-Manager
- ComfyUI-KJNodes
- Civicomfy

## Source Code

Source code: [github.com/Kwizatz/comfyui-base-az-storage](https://github.com/Kwizatz/comfyui-base-az-storage)

## Custom Arguments

Edit `/workspace/runpod-slim/comfyui_args.txt` (one arg per line):

```
--max-batch-size 8
--preview-method auto
```

## Directory Structure

- `/workspace/runpod-slim/ComfyUI`: ComfyUI install
- `/workspace/runpod-slim/comfyui_args.txt`: ComfyUI args
- `/workspace/runpod-slim/filebrowser.db`: FileBrowser DB

## Azure Blob Storage (Persistent Storage)

Uses Azure Blob Storage to persist models, inputs, and outputs across pod restarts. Without it, all data is lost when the pod shuts down.

### Why Azure Blob Storage?

RunPod pods are **ephemeral** — local disk is wiped on every stop, restart, or spot preemption. RunPod Network Volumes offer persistence but are **region-locked** (limiting GPU choices), **fixed-size** (pay whether used or not), and **not portable** (tied to RunPod).

Azure Blob Storage is **provider-independent** (accessible from anywhere), has **no region lock** (grab the cheapest GPU in any datacenter), is **pay-per-use** (~$0.018/GB/month), scales to **5 PiB**, and **survives** crashes and preemptions with built-in redundancy. The trade-off is slightly longer startup as models download on each launch.

### Setup

1. **Create a Storage Account:** [Azure Portal](https://portal.azure.com) → Search "Storage accounts" → Create. Use Standard performance, LRS redundancy, region close to RunPod.

2. **Create Containers:** In the storage account → Data storage → Containers, create three **Private** containers: `models`, `input`, `output`.

3. **Get Access Key:** Security + networking → Access keys → Show Key 1. Copy the account name and key.

### Environment Variables

Set these when deploying a pod under **Environment Variables**:

| Variable | Required | Description |
|---|---|---|
| `AZURE_STORAGE_ACCOUNT` | **Yes** | Storage account name |
| `AZURE_STORAGE_KEY` | **Yes** | Storage access key |
| `AZURE_SYNC_INTERVAL` | No | Sync interval in seconds (default: `300`) |

### How Sync Works

- **Startup:** Downloads models, inputs, and outputs from Azure
- **Every 5 min:** Syncs input and output back to Azure
- **Shutdown:** Syncs everything back (requires graceful stop)

> Force-kills skip the shutdown sync. Periodic sync limits data loss to ~5 minutes.

### Uploading Models

Upload to the `models` container via [Azure Storage Explorer](https://azure.microsoft.com/products/storage/storage-explorer/), the Azure Portal, or CLI:

```bash
az storage blob upload --account-name <acct> --container-name models \
    --name checkpoints/model.safetensors --file ./model.safetensors
```

Use standard ComfyUI subdirectories: `checkpoints/`, `vae/`, `loras/`, `controlnet/`, `clip/`, `clip_vision/`, `embeddings/`, `upscale_models/`, `hypernetworks/`, `unet/`, `style_models/`.
