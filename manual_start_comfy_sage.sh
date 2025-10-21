#!/bin/bash

# ComfyUI Startup Script with SageAttention Support for VAST.AI (Robust Version)
# This script kills processes on common ComfyUI ports before starting.

echo "=== Starting ComfyUI with SageAttention Support ==="

# VAST.AI CHANGE: Kill processes on BOTH common ports to ensure a clean start.
echo "Stopping any existing ComfyUI processes on ports 18188 and 8188..."
fuser -k 18188/tcp || true
fuser -k 8188/tcp || true
sleep 3

# Navigate to the ComfyUI directory
echo "Navigating to /workspace/ComfyUI..."
cd /workspace/ComfyUI

# Start ComfyUI with SageAttention enabled
echo "Starting ComfyUI with SageAttention..."
echo "ComfyUI will be available at: http://localhost:18188"
echo ""
echo "Press Ctrl+C in the terminal to stop ComfyUI"

# Launch our custom instance on port 18188
/venv/main/bin/python3 main.py --use-sage-attention --listen --port 18188 --enable-cors-header