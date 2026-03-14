#!/bin/bash
set -e

COMFYUI_DIR="/workspace/runpod-slim/ComfyUI"

if [ -z "$AZURE_STORAGE_ACCOUNT" ] || [ -z "$AZURE_STORAGE_KEY" ]; then
    echo "Error: AZURE_STORAGE_ACCOUNT and AZURE_STORAGE_KEY must be set."
    exit 1
fi

export RCLONE_CONFIG_AZURE_TYPE=azureblob
export RCLONE_CONFIG_AZURE_ACCOUNT=$AZURE_STORAGE_ACCOUNT
export RCLONE_CONFIG_AZURE_KEY=$AZURE_STORAGE_KEY

RCLONE_COMMON_FLAGS="--progress --size-only --multi-thread-streams 16 --transfers 8 --azureblob-upload-concurrency 64"

echo "Uploading models (checkpoints, vae, loras, etc.)..."
rclone sync $COMFYUI_DIR/models azure:models $RCLONE_COMMON_FLAGS

echo "Uploading input files..."
rclone sync $COMFYUI_DIR/input azure:input $RCLONE_COMMON_FLAGS

echo "Uploading output files..."
rclone sync $COMFYUI_DIR/output azure:output $RCLONE_COMMON_FLAGS

echo "Uploading workflows..."
rclone sync $COMFYUI_DIR/user/default/workflows azure:workflows $RCLONE_COMMON_FLAGS

echo "Azure sync complete."
