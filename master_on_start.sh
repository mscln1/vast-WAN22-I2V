#!/bin/bash

# =================================================================
# --- VAST.AI MASTER ON-START SCRIPT ---
# =================================================================

# 1. EXECUTE THE ORIGINAL ENTRYPOINT SCRIPT
# This ensures the default container setup completes successfully before we add our modifications.
echo "--- Executing the default entrypoint.sh script... ---"
/bin/bash /opt/vast/entrypoint.sh # Using a more specific path is safer
echo "--- Default entrypoint finished. Starting custom setup... ---"
echo

# 2. CHECK FOR THE CIVITAI API TOKEN
# =================================================================
if [ -z "${CIVITAI_API_TOKEN}" ]; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "!!! WARNING: CIVITAI_API_TOKEN environment variable is not set.            !!!"
    echo "!!! Downloads from Civitai will likely fail. Please add it to the template.!!!"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
else
    echo "--> Civitai API token found. Proceeding with setup."
fi
echo

# 3. PREPARE THE SYSTEM
# =================================================================
echo "--> Updating package lists and installing dos2unix..."
apt-get update
apt-get install -y dos2unix
echo "--> System prepared."
echo

# 4. DOWNLOAD YOUR CUSTOM SCRIPTS
# =================================================================
# Replace these URLs with the raw URLs from your own GitHub repository
echo "--> Downloading custom setup scripts from GitHub..."
wget -O /workspace/install_sage_vast.sh https://raw.githubusercontent.com/mscln1/vast-WAN22-I2V/refs/heads/main/install_sage_vast.sh
wget -O /workspace/vast_setup.sh https://raw.githubusercontent.com/mscln1/vast-WAN22-I2V/refs/heads/main/vast_setup.sh
wget -O /workspace/manual_start_comfy_sage.sh https://raw.githubusercontent.com/mscln1/vast-WAN22-I2V/refs/heads/main/manual_start_comfy_sage.sh
echo "--> All scripts downloaded."
echo

# 5. FIX LINE ENDINGS AND MAKE EXECUTABLE
# =================================================================
echo "--> Fixing line endings and setting permissions..."
dos2unix /workspace/*.sh
chmod +x /workspace/*.sh
echo "--> Scripts are ready to execute."
echo

# 6. EXECUTE YOUR SCRIPTS IN ORDER
# =================================================================
echo "--- EXECUTING SCRIPT 1: vast_setup.sh ---"
/workspace/vast_setup.sh
echo

echo "--- EXECUTING SCRIPT 2: install_sage_vast.sh ---"
/workspace/install_sage_vast.sh
echo

echo "--- EXECUTING SCRIPT 3: manual_start_comfy_sage.sh ---"
# This script likely starts the final long-running process (ComfyUI).
/workspace/manual_start_comfy_sage.sh
echo

echo "--- CUSTOM SETUP COMPLETE ---"