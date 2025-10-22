#!/bin/bash
set -e

echo "=== Custom Setup Starting (after default provisioning) ==="
echo ""

# Check for API token
if [ -z "${CIVITAI_API_TOKEN}" ]; then
    echo "!!! WARNING: CIVITAI_API_TOKEN not set"
else
    echo "✓ Civitai API token found"
fi
echo ""

# Install dos2unix
echo "→ Installing dos2unix..."
apt-get update > /dev/null 2>&1
apt-get install -y dos2unix > /dev/null 2>&1
echo ""

# Download scripts
echo "→ Downloading custom scripts..."
cd /workspace
wget -q -O vast_setup.sh https://raw.githubusercontent.com/mscln1/vast-WAN22-I2V/refs/heads/main/vast_setup.sh
wget -q -O install_sage_vast.sh https://raw.githubusercontent.com/mscln1/vast-WAN22-I2V/refs/heads/main/install_sage_vast.sh
wget -q -O manual_start_comfy_sage.sh https://raw.githubusercontent.com/mscln1/vast-WAN22-I2V/refs/heads/main/manual_start_comfy_sage.sh
echo ""

# Prepare scripts
echo "→ Preparing scripts..."
dos2unix *.sh 2>/dev/null
chmod +x *.sh
echo ""

# Execute scripts
echo "--- EXECUTING: vast_setup.sh ---"
./vast_setup.sh
echo ""

echo "--- EXECUTING: install_sage_vast.sh ---"
./install_sage_vast.sh
echo ""

echo "--- EXECUTING: manual_start_comfy_sage.sh ---"
./manual_start_comfy_sage.sh
echo ""

echo "=== Custom Setup Complete ==="