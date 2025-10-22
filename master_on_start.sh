#!/bin/bash
set -e

# =================================================================
# --- VAST.AI MASTER ON-START SCRIPT (Corrected) ---
# =================================================================

echo "--- [CUSTOM] Starting Master Setup ---"

# 1. EXECUTE THE DEFAULT PROVISIONING SCRIPT
if [ -n "${PROVISIONING_SCRIPT}" ]; then
    echo "--- [CUSTOM] Executing default provisioning script... ---"
    wget -O /tmp/default_provisioning.sh "${PROVISIONING_SCRIPT}"
    bash /tmp/default_provisioning.sh
    echo "--- [CUSTOM] Default provisioning script finished. ---"
else
    echo "--- [CUSTOM] WARNING: No PROVISIONING_SCRIPT found. ---"
fi
echo

# 2. PREPARE SYSTEM FOR CUSTOM SCRIPTS
echo "--- [CUSTOM] Installing dos2unix... ---"
apt-get update > /dev/null 2>&1 && apt-get install -y dos2unix > /dev/null 2>&1
echo

# 3. DOWNLOAD AND EXECUTE SETUP SCRIPTS
echo "--- [CUSTOM] Downloading and running vast_setup.sh ---"
wget -O /workspace/vast_setup.sh https://raw.githubusercontent.com/mscln1/vast-WAN22-I2V/refs/heads/main/vast_setup.sh
dos2unix /workspace/vast_setup.sh && chmod +x /workspace/vast_setup.sh
/workspace/vast_setup.sh
echo

echo "--- [CUSTOM] Downloading and running install_sage_vast.sh ---"
wget -O /workspace/install_sage_vast.sh https://raw.githubusercontent.com/mscln1/vast-WAN22-I2V/refs/heads/main/install_sage_vast.sh
dos2unix /workspace/install_sage_vast.sh && chmod +x /workspace/install_sage_vast.sh
/workspace/install_sage_vast.sh
echo

# NOTE: The call to manual_start_comfy_sage.sh has been REMOVED.
# The main container entrypoint will handle starting ComfyUI.

echo "--- [CUSTOM] All custom scripts have been executed. ---"```

#### Step 2: Update the "On-start script" in Your Vast.ai Template

This is the most critical change. Replace your current on-start script with the following. This version launches your setup in the background (`&`) and then immediately proceeds to run the main entrypoint.

**Copy and paste this into your "On-start script" field:**

```bash
#!/bin/bash

# Launch our entire custom setup process in the background.
# The parentheses group the commands, and the '&' runs the group in the background.
(
  echo "--- LAUNCHER: Starting custom setup in the background... ---"
  wget -qO- https://raw.githubusercontent.com/mscln1/vast-WAN22-I2V/refs/heads/main/master_on_start.sh | bash
  echo "--- LAUNCHER: Background setup script has been kicked off. Check logs for progress. ---"
) &

# Now, execute the original container entrypoint in the foreground.
# This will start Jupyter, ComfyUI, etc., and keep the container running.
echo "--- LAUNCHER: Executing the main container entrypoint... ---"
exec /opt/instance-tools/bin/entrypoint.sh
