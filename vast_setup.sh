#!/bin/bash

# RTX 5090 - GGUF Q8 Models & Nodes Setup Script for VAST.AI
# Version: Sequential Base Models, Concurrent Node Setup, Sequential LoRAs
# Usage: Run this in the Vast.ai terminal after the instance has started.

# =================================================================
# --- HELPER FUNCTIONS ---
# =================================================================

# Original function for downloading base models
download_file() {
    URL="$1"
    OUTPUT_PATH="$2"
    echo "Downloading: $(basename "$OUTPUT_PATH")"
    # Using --quiet and --show-progress for a cleaner download bar
    wget --quiet --show-progress "$URL" -O "$OUTPUT_PATH"
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to download from $URL"
    fi
    echo
}

# New, more robust function specifically for the LoRA download section
download_and_check() {
    local url="$1"
    local description="$2"
    shift 2 # Removes the first two arguments, leaving the rest for wget

    echo "--> Downloading: $description"
    if ! wget --quiet --show-progress "$@" "$url"; then
        echo "!!! FAILED: $description"
        FAILED_DOWNLOADS+=("$description from $url")
        echo # Add a newline for readability
    else
        echo "    Done."
        echo # Add a newline for readability
    fi
}

clone_repo() {
    REPO_URL=$1
    DIR_NAME=$(basename "$REPO_URL" .git)
    if [ ! -d "$DIR_NAME" ]; then
        echo "Cloning $DIR_NAME..."
        git clone "$REPO_URL"
    else
        echo "$DIR_NAME already exists, skipping clone."
    fi
}

# =================================================================
# --- TASK-SPECIFIC FUNCTIONS ---
# =================================================================

# --- Task Function: Custom Nodes Setup (Cloning & Installation) ---
# This entire function will run as a single background job.
setup_custom_nodes() {
    echo "-> Starting parallel custom node cloning..."
    cd "${COMFYUI_BASE_PATH}/custom_nodes"

    # Clone all repositories in the background concurrently
    clone_repo https://github.com/city96/ComfyUI-GGUF.git &
    clone_repo https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git &
    clone_repo https://github.com/ltdrdata/was-node-suite-comfyui.git &
    clone_repo https://github.com/kijai/ComfyUI-WanVideoWrapper.git &
    clone_repo https://github.com/cubiq/ComfyUI_essentials.git &
    clone_repo https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git &
    clone_repo https://github.com/rgthree/rgthree-comfy.git &
    clone_repo https://github.com/kijai/ComfyUI-KJNodes.git &
    clone_repo https://github.com/Smirnov75/ComfyUI-mxToolkit.git &
    clone_repo https://github.com/LAOGOU-666/Comfyui-Memory_Cleanup.git &
    clone_repo https://github.com/orssorbit/ComfyUI-wanBlockswap.git &
    clone_repo https://github.com/phazei/ComfyUI-Prompt-Stash.git &
    clone_repo https://github.com/stduhpf/ComfyUI-WanMoeKSampler.git &
    clone_repo https://github.com/crystian/ComfyUI-Crystools.git &
    clone_repo https://github.com/willmiao/ComfyUI-Lora-Manager.git &

    # Wait for all clone jobs to finish before proceeding to install requirements
    wait
    echo "--- All repositories cloned. ---"

    echo "-> Installing node requirements..."
    for dir in ./*/; do
        if [ -f "$dir/requirements.txt" ]; then
            echo "Installing requirements for $(basename "$dir")"
            "$PYTHON_EXEC" -m pip install -r "$dir/requirements.txt"
        fi
    done
    echo "--- Custom node setup complete. ---"
}

# --- Task Function: Sequential Base Model Downloads ---
# This function will run in the foreground, downloading one file at a time.
download_base_models() {
    echo "-> Starting sequential base model downloads..."
    download_file "https://huggingface.co/QuantStack/Wan2.2-I2V-A14B-GGUF/resolve/main/HighNoise/Wan2.2-I2V-A14B-HighNoise-Q8_0.gguf" "${COMFYUI_BASE_PATH}/models/unet/Wan2.2-I2V-A14B-HighNoise-Q8_0.gguf"
    download_file "https://huggingface.co/QuantStack/Wan2.2-I2V-A14B-GGUF/resolve/main/LowNoise/Wan2.2-I2V-A14B-LowNoise-Q8_0.gguf" "${COMFYUI_BASE_PATH}/models/unet/Wan2.2-I2V-A14B-LowNoise-Q8_0.gguf"
    download_file "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" "${COMFYUI_BASE_PATH}/models/vae/wan_2.1_vae.safetensors"
    download_file "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" "${COMFYUI_BASE_PATH}/models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
    download_file "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors" "${COMFYUI_BASE_PATH}/models/vae/Wan2_1_VAE_bf16.safetensors"
    echo "--- Base model downloads complete. ---"
}

# =================================================================
# --- SCRIPT START ---
# =================================================================

echo "=== RTX 5090 GGUF Q8 Wan 2.2 I2V A14B Setup Script ==="

# --- Initial Configuration ---
COMFYUI_BASE_PATH="/workspace/ComfyUI"
PYTHON_EXEC="/venv/main/bin/python3"

# Create model directories if they don't exist
mkdir -p "${COMFYUI_BASE_PATH}/models/unet"
mkdir -p "${COMFYUI_BASE_PATH}/models/loras"
mkdir -p "${COMFYUI_BASE_PATH}/models/vae"
mkdir -p "${COMFYUI_BASE_PATH}/models/text_encoders"
mkdir -p "${COMFYUI_BASE_PATH}/custom_nodes"

# --- Concurrent Execution Phase ---
echo "--- Starting Concurrent Operations ---"
echo "1. Custom node setup (cloning & installing) will run in the background."
echo "2. Base models will download sequentially in the foreground."

# Start the entire custom node setup process in the background
setup_custom_nodes &
NODE_SETUP_PID=$! # Store the Process ID (PID) of the background job

# Run the sequential base model download process in the foreground
download_base_models

# --- Synchronization Point ---
echo "Base model downloads finished. Waiting for custom node setup to complete (if it's still running)..."
wait $NODE_SETUP_PID
echo "--- All concurrent tasks are complete. ---"


# =================================================================
# --- SEQUENTIAL LORA DOWNLOAD PHASE ---
# =================================================================
echo
echo "--- Starting Sequential Download of All LoRA Models ---"

# --- Configuration ---
LORA_DIR="${COMFYUI_BASE_PATH}/models/loras"
FAILED_DOWNLOADS=()

# 1. Create subdirectories for LoRA models
echo "Creating subdirectories..."
mkdir -p "$LORA_DIR/lightning"
mkdir -p "$LORA_DIR/camera"
mkdir -p "$LORA_DIR/trap"
mkdir -p "$LORA_DIR/moneyshot"
mkdir -p "$LORA_DIR/sex"
echo "Subdirectories are ready."
echo

# 2. Download all models sequentially
echo "--- Downloading Hugging Face LoRAs ---"
## These go in /loras/lightning
download_and_check "https://huggingface.co/lightx2v/Wan2.2-Lightning/resolve/main/Wan2.2-I2V-A14B-4steps-lora-rank64-Seko-V1/high_noise_model.safetensors" "Wan2.2-Lightning HIGH" -O "$LORA_DIR/lightning/Wan2.2-Lightning_I2V-A14B-4steps-lora_HIGH_fp16.safetensors"
download_and_check "https://huggingface.co/lightx2v/Wan2.2-Lightning/resolve/main/Wan2.2-I2V-A14B-4steps-lora-rank64-Seko-V1/low_noise_model.safetensors" "Wan2.2-Lightning LOW" -O "$LORA_DIR/lightning/Wan2.2-Lightning_I2V-A14B-4steps-lora_LOW_fp16.safetensors"
download_and_check "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/rCM/Wan_2_1_T2V_14B_rCM_lora_average_rank_83_bf16.safetensors" "Wan2.1_T2V_rCM" -O "$LORA_DIR/lightning/Wan21_T2V_14B_rCM_lora_average_rank_83_bf16.safetensors"
download_and_check "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Wan22_Lightx2v/Wan_2_2_I2V_A14B_HIGH_lightx2v_MoE_distill_lora_rank_64_bf16.safetensors" "Wan2.2_I2V_HIGH_MoE" -O "$LORA_DIR/lightning/Wan22_I2V_A14B_HIGH_lightx2v_MoE_distill_lora_rank_64_bf16.safetensors"

echo "--- Downloading Civitai LoRAs ---"
## These go in /loras/camera
download_and_check "https://civitai.com/api/download/models/2126538?token=${CIVITAI_API_TOKEN}" "Camera Tilt-up LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/camera"
download_and_check "https://civitai.com/api/download/models/2126493?token=${CIVITAI_API_TOKEN}" "Camera Tilt-up HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/camera"

## These go in /loras/trap
download_and_check "https://civitai.com/api/download/models/2321871?token=${CIVITAI_API_TOKEN}" "FutaTF HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/trap"
download_and_check "https://civitai.com/api/download/models/2321878?token=${CIVITAI_API_TOKEN}" "FutaTF LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/trap"

## These go in /loras/moneyshot
download_and_check "https://civitai.com/api/download/models/2221382?token=${CIVITAI_API_TOKEN}" "Wan22_Cum HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/moneyshot"
download_and_check "https://civitai.com/api/download/models/2221988?token=${CIVITAI_API_TOKEN}" "Wan22_Cum LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/moneyshot"
download_and_check "https://civitai.com/api/download/models/2277597?token=${CIVITAI_API_TOKEN}" "I2V_tongueout LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/moneyshot"
download_and_check "https://civitai.com/api/download/models/2277578?token=${CIVITAI_API_TOKEN}" "I2V_tongueout HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/moneyshot"
download_and_check "https://civitai.com/api/download/models/2290038?token=${CIVITAI_API_TOKEN}" "Wan22_Throat HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/moneyshot"
download_and_check "https://civitai.com/api/download/models/2290065?token=${CIVITAI_API_TOKEN}" "Wan22_Throat LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/moneyshot"
download_and_check "https://civitai.com/api/download/models/2235299?token=${CIVITAI_API_TOKEN}" "DR34MJOB HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/moneyshot"
download_and_check "https://civitai.com/api/download/models/2235288?token=${CIVITAI_API_TOKEN}" "DR34MJOB LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/moneyshot"
download_and_check "https://civitai.com/api/download/models/2152516?token=${CIVITAI_API_TOKEN}" "jfj-deepthroat HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/moneyshot"
download_and_check "https://civitai.com/api/download/models/2152583?token=${CIVITAI_API_TOKEN}" "jfj-deepthroat LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/moneyshot"
download_and_check "https://civitai.com/api/download/models/2193369?token=${CIVITAI_API_TOKEN}" "I2V Blowjob HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/moneyshot"
download_and_check "https://civitai.com/api/download/models/2193373?token=${CIVITAI_API_TOKEN}" "I2V Blowjob LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/moneyshot"
download_and_check "https://civitai.com/api/download/models/2087173?token=${CIVITAI_API_TOKEN}" "pworship HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/moneyshot"
download_and_check "https://civitai.com/api/download/models/2087124?token=${CIVITAI_API_TOKEN}" "pworship LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/moneyshot"
download_and_check "https://civitai.com/api/download/models/2178869?token=${CIVITAI_API_TOKEN}" "f4c3spl4sh LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/moneyshot"
download_and_check "https://civitai.com/api/download/models/2176450?token=${CIVITAI_API_TOKEN}" "f4c3spl4sh HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/moneyshot"
download_and_check "https://civitai.com/api/download/models/2122049?token=${CIVITAI_API_TOKEN}" "ultimatedeepthroat HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/moneyshot"
download_and_check "https://civitai.com/api/download/models/2191446?token=${CIVITAI_API_TOKEN}" "ultimatedeepthroat LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/moneyshot"
download_and_check "https://civitai.com/api/download/models/2164213?token=${CIVITAI_API_TOKEN}" "Double-Blowjob HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/moneyshot"
download_and_check "https://civitai.com/api/download/models/2164348?token=${CIVITAI_API_TOKEN}" "Double-Blowjob LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/moneyshot"

## These go in /loras/sex
download_and_check "https://civitai.com/api/download/models/2073605?token=${CIVITAI_API_TOKEN}" "NSFW-22 HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/sex"
download_and_check "https://civitai.com/api/download/models/2083303?token=${CIVITAI_API_TOKEN}" "NSFW-22 LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/sex"
download_and_check "https://civitai.com/api/download/models/2098405?token=${CIVITAI_API_TOKEN}" "pov_missionary HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/sex"
download_and_check "https://civitai.com/api/download/models/2098396?token=${CIVITAI_API_TOKEN}" "pov_missionary LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/sex"
download_and_check "https://civitai.com/api/download/models/2200389?token=${CIVITAI_API_TOKEN}" "pov-insertion (ZIP)" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/sex"
download_and_check "https://civitai.com/api/download/models/2298673?token=${CIVITAI_API_TOKEN}" "POV-Body-Cumshot HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/sex"
download_and_check "https://civitai.com/api/download/models/2298928?token=${CIVITAI_API_TOKEN}" "POV-Body-Cumshot LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/sex"
download_and_check "https://civitai.com/api/download/models/2190121?token=${CIVITAI_API_TOKEN}" "Anal-v1 HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/sex"
download_and_check "https://civitai.com/api/download/models/2190113?token=${CIVITAI_API_TOKEN}" "Anal-v1 LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/sex"
download_and_check "https://civitai.com/api/download/models/2249683?token=${CIVITAI_API_TOKEN}" "doggyslider HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/sex"
download_and_check "https://civitai.com/api/download/models/2249697?token=${CIVITAI_API_TOKEN}" "doggyslider LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/sex"

# 3. Unzip any downloaded archives
echo "--- Searching for and extracting .zip files ---"
find "$LORA_DIR" -type f -name "*.zip" | while read -r file; do
    echo "Found zip file: $file"
    unzip -o "$file" -d "$(dirname "$file")"
    if [ $? -eq 0 ]; then
        echo "Successfully unzipped. Deleting archive..."
        rm "$file"
    else
        echo "!!! Failed to unzip $file. The archive will not be deleted."
    fi
done
echo "Zip file processing complete."
echo

# 4. Report final status
echo "--- Download Summary ---"
if [ ${#FAILED_DOWNLOADS[@]} -ne 0 ]; then
    echo "The following downloads FAILED:"
    for item in "${FAILED_DOWNLOADS[@]}"; do
        echo "  - $item"
    done
else
    echo "All LoRA models were downloaded successfully."
fi
echo

# =================================================================
# --- FINAL INSTRUCTIONS ---
# =================================================================
echo "=== RTX 5090 GGUF Q8 Setup Complete! ==="
echo "Next steps:"
echo "1. Ensure you have already run the package alignment and SageAttention install scripts."
echo "2. Restart the ComfyUI container/process."
echo "3. Load your workflow and enjoy!"