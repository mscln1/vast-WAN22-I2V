#!/bin/bash

# SageAttention 2++ Installation Script for Vast.ai
# Usage: Run this AFTER your model setup script and BEFORE starting ComfyUI

echo "=== SageAttention 2++ Installation ==="

# Stop ComfyUI if running
# VAST.AI NOTE: The default port for the template is 18188.
# This script will attempt to stop the process on that port.
# Change this if you have customized the ComfyUI launch port.
echo "Stopping ComfyUI process..."
apt-get update -y
apt-get install -y psmisc
fuser -k 18188/tcp || true
sleep 5

echo "Installing SageAttention 2++..."
# VAST.AI CHANGE: The ComfyUI directory is located in /workspace
cd /workspace/ComfyUI

# Clone SageAttention repository, but only if it doesn't already exist
if [ ! -d "SageAttention" ]; then
    echo "Cloning SageAttention repository..."
    git clone https://github.com/thu-ml/SageAttention.git
fi
cd SageAttention

# Set compilation flags for faster build
export EXT_PARALLEL=4
export NVCC_APPEND_FLAGS="--threads 8"
export MAX_JOBS=32

# Install SageAttention using the virtual environment
echo "Compiling SageAttention (this may take 5-10 minutes)..."
# VAST.AI CHANGE: The Python executable is located at /venv/main/bin/python3
/venv/main/bin/python3 setup.py install

echo "=== SageAttention 2++ Installation Complete! ==="
echo ""
echo "To start ComfyUI with SageAttention support:"
# VAST.AI CHANGE: Updated paths for the start command
echo "cd /workspace/ComfyUI"
echo "/venv/main/bin/python3 main.py --use-sage-attention --listen --port 18188"
echo ""