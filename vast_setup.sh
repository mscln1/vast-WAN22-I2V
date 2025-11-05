#!/bin/bash

# MODIFIED SECTION: Read environment variable to decide which models to download
# Defaults to "wan" if the variable is not set.
MODEL_SETS="${MODEL_SETS:-wan}"
echo "✓ Model sets to download based on MODEL_SETS variable: $MODEL_SETS"
echo

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
    # Using --quiet for clean output
    wget --quiet "$URL" -O "$OUTPUT_PATH"
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
    if ! wget --quiet "$@" "$url"; then
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
    clone_repo https://github.com/yolain/ComfyUI-Easy-Use.git &
    clone_repo https://github.com/ltdrdata/ComfyUI-Impact-Pack.git &
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
    clone_repo https://github.com/lrzjason/Comfyui-QwenEditUtils.git &
	clone_repo https://github.com/ClownsharkBatwing/RES4LYF.git &
    clone_repo https://github.com/yuvraj108c/ComfyUI-Rife-Tensorrt &
    clone_repo https://github.com/fuselayer/comfyui-ez-dl &
    clone_repo https://github.com/nunchaku-tech/ComfyUI-nunchaku &
    clone_repo https://github.com/Clybius/ComfyUI-Extra-Samplers &
    clone_repo https://github.com/kijai/ComfyUI-MMAudio &
    clone_repo https://github.com/numz/ComfyUI-SeedVR2_VideoUpscaler &


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
download_wan_models() {
    echo "-> Starting sequential base model downloads..."
    download_file "https://huggingface.co/QuantStack/Wan2.2-I2V-A14B-GGUF/resolve/main/HighNoise/Wan2.2-I2V-A14B-HighNoise-Q8_0.gguf" "${COMFYUI_BASE_PATH}/models/diffusion_models/Wan2.2-I2V-A14B-HighNoise-Q8_0.gguf"
    download_file "https://huggingface.co/QuantStack/Wan2.2-I2V-A14B-GGUF/resolve/main/LowNoise/Wan2.2-I2V-A14B-LowNoise-Q8_0.gguf" "${COMFYUI_BASE_PATH}/models/diffusion_models/Wan2.2-I2V-A14B-LowNoise-Q8_0.gguf"
    download_file "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" "${COMFYUI_BASE_PATH}/models/vae/wan_2.1_vae.safetensors"
    download_file "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" "${COMFYUI_BASE_PATH}/models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
    download_file "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors" "${COMFYUI_BASE_PATH}/models/vae/Wan2_1_VAE_bf16.safetensors"
    echo "--- Base model downloads complete. ---"
}

download_qwen_models() {
    echo "-> Starting sequential Qwen base model downloads..."
    mkdir -p "${COMFYUI_BASE_PATH}/models/loras/qwen"
    # NOTE: Replace these with the actual Qwen model URLs and paths you need
    download_file "https://huggingface.co/QuantStack/Qwen-Image-Edit-2509-GGUF/resolve/main/Qwen-Image-Edit-2509-Q8_0.gguf" "${COMFYUI_BASE_PATH}/models/diffusion_models/Qwen-Image-Edit-2509-Q8_0.gguf"
    download_file "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors" "${COMFYUI_BASE_PATH}/models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"
    download_file "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors" "${COMFYUI_BASE_PATH}/models/vae/qwen_image_vae.safetensors"
    # download_file "https://huggingface.co/nunchaku-tech/nunchaku-qwen-image-edit-2509/blob/main/svdq-fp4_r128-qwen-image-edit-2509.safetensors" "${COMFYUI_BASE_PATH}/models/diffusion_models/svdq-fp4_r128-qwen-image-edit-2509.safetensors"
    download_file "https://huggingface.co/lightx2v/Qwen-Image-Lightning/resolve/main/Qwen-Image-Edit-2509/Qwen-Image-Edit-2509-Lightning-4steps-V1.0-bf16.safetensors" "${COMFYUI_BASE_PATH}/models/loras/qwen/Qwen-Image-Edit-2509-Lightning-4steps-V1.0-bf16.safetensors"
    download_file "https://huggingface.co/lightx2v/Qwen-Image-Lightning/resolve/main/Qwen-Image-Edit-2509/Qwen-Image-Edit-2509-Lightning-8steps-V1.0-bf16.safetensors" "${COMFYUI_BASE_PATH}/models/loras/qwen/Qwen-Image-Edit-2509-Lightning-8steps-V1.0-bf16.safetensors"
    echo "--- Qwen base model downloads complete. ---"
}

# =================================================================
# --- SCRIPT START ---
# =================================================================

echo "=== RTX 5090 GGUF Q8 Wan 2.2 I2V A14B Setup Script ==="

# --- Initial Configuration ---
COMFYUI_BASE_PATH="/workspace/ComfyUI"
PYTHON_EXEC="/venv/main/bin/python3"

# Create model directories if they don't exist
# mkdir -p "${COMFYUI_BASE_PATH}/models/diffusion_models"
# mkdir -p "${COMFYUI_BASE_PATH}/models/loras"
# mkdir -p "${COMFYUI_BASE_PATH}/models/vae"
# mkdir -p "${COMFYUI_BASE_PATH}/models/text_encoders"
# mkdir -p "${COMFYUI_BASE_PATH}/custom_nodes"

# --- Concurrent Execution Phase ---
echo "--- Starting Concurrent Operations ---"
echo "1. Custom node setup (cloning & installing) will run in the background."
echo "2. Base models will download sequentially in the foreground."

# Start the entire custom node setup process in the background
setup_custom_nodes &
NODE_SETUP_PID=$! # Store the Process ID (PID) of the background job

# Conditionally download model sets
if [[ "$MODEL_SETS" == *"wan"* ]]; then
    download_wan_models
fi

if [[ "$MODEL_SETS" == *"qwen"* ]]; then
    download_qwen_models
fi

# --- Synchronization Point ---
echo "Base model downloads finished. Waiting for custom node setup to complete (if it's still running)..."
wait $NODE_SETUP_PID
echo "--- All concurrent tasks are complete. ---"


# =================================================================
# --- SEQUENTIAL LORA DOWNLOAD PHASE ---
# =================================================================
# Conditional Wan LoRA downloads
if [[ "$MODEL_SETS" == *"wan"* ]]; then
    echo
    echo "--- Starting Sequential Download of WAN-specific LoRA Models ---"



    # --- Configuration ---
    mkdir -p "${COMFYUI_BASE_PATH}/models/loras/wan22"
    LORA_DIR="${COMFYUI_BASE_PATH}/models/loras/wan22"
    FAILED_DOWNLOADS=()

    # 1. Create subdirectories for WAN LoRA models
    echo "Creating subdirectories..."
    mkdir -p "$LORA_DIR/lightning"
    mkdir -p "$LORA_DIR/camera"
    mkdir -p "$LORA_DIR/futa"
    mkdir -p "$LORA_DIR/oral"
    mkdir -p "$LORA_DIR/sex"
    mkdir -p "$LORA_DIR/general"
    echo "Subdirectories are ready."
    echo

    # 2. Download all models sequentially
    echo "--- Downloading Hugging Face LoRAs ---"
    ## These go in /loras/lightning
    download_and_check "https://huggingface.co/lightx2v/Wan2.2-Lightning/resolve/main/Wan2.2-I2V-A14B-4steps-lora-rank64-Seko-V1/high_noise_model.safetensors" "Wan2.2-Lightning HIGH" -O "$LORA_DIR/lightning/Wan2.2-Lightning_I2V-A14B-4steps-lora_HIGH_fp16.safetensors"
    download_and_check "https://huggingface.co/lightx2v/Wan2.2-Lightning/resolve/main/Wan2.2-I2V-A14B-4steps-lora-rank64-Seko-V1/low_noise_model.safetensors" "Wan2.2-Lightning LOW" -O "$LORA_DIR/lightning/Wan2.2-Lightning_I2V-A14B-4steps-lora_LOW_fp16.safetensors"
    download_and_check "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/rCM/Wan_2_1_T2V_14B_720p_rCM_lora_average_rank_94_bf16.safetensors" "Wan2.1_T2V_rCM" -O "$LORA_DIR/lightning/Wan_2_1_T2V_14B_720p_rCM_lora_average_rank_94_bf16.safetensors"
    download_and_check "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Wan22_Lightx2v/Wan_2_2_I2V_A14B_HIGH_lightx2v_MoE_distill_lora_rank_64_bf16.safetensors" "Wan2.2_I2V_HIGH_MoE" -O "$LORA_DIR/lightning/Wan22_I2V_A14B_HIGH_lightx2v_MoE_distill_lora_rank_64_bf16.safetensors"

    echo "--- Downloading Civitai LoRAs ---"
    
    ## these go in loras/general
    download_and_check "https://civitai.com/api/download/models/2295670?token=${CIVITAI_API_TOKEN}" "WAN2.2_SmartphoneSnapshotPhotoReality_v5_by-AI_Characters_high+low_noise" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/general"
    
    ## These go in /loras/camera
    download_and_check "https://civitai.com/api/download/models/2126538?token=${CIVITAI_API_TOKEN}" "Camera Tilt-up LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/camera"
    download_and_check "https://civitai.com/api/download/models/2126493?token=${CIVITAI_API_TOKEN}" "Camera Tilt-up HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/camera"
    download_and_check "https://huggingface.co/dx8152/Qwen-Edit-2509-Multiple-angles/blob/main/%E5%A4%9A%E8%A7%92%E5%BA%A6.safetensors" "Qwen-Edit-2509-Multiple-angles-多角度" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/camera"

    ## These go in /loras/futa
    download_and_check "https://civitai.com/api/download/models/2321871?token=${CIVITAI_API_TOKEN}" "FutaTF HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/futa"
    download_and_check "https://civitai.com/api/download/models/2321878?token=${CIVITAI_API_TOKEN}" "FutaTF LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/futa"

    ## These go in /loras/oral
    download_and_check "https://civitai.com/api/download/models/2221382?token=${CIVITAI_API_TOKEN}" "Wan22_Cum HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/oral"
    download_and_check "https://civitai.com/api/download/models/2221988?token=${CIVITAI_API_TOKEN}" "Wan22_Cum LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/oral"
    download_and_check "https://civitai.com/api/download/models/2277597?token=${CIVITAI_API_TOKEN}" "I2V_tongueout LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/oral"
    download_and_check "https://civitai.com/api/download/models/2277578?token=${CIVITAI_API_TOKEN}" "I2V_tongueout HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/oral"
    download_and_check "https://civitai.com/api/download/models/2290038?token=${CIVITAI_API_TOKEN}" "Wan22_Throat HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/oral"
    download_and_check "https://civitai.com/api/download/models/2290065?token=${CIVITAI_API_TOKEN}" "Wan22_Throat LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/oral"
    download_and_check "https://civitai.com/api/download/models/2235299?token=${CIVITAI_API_TOKEN}" "DR34MJOB HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/oral"
    download_and_check "https://civitai.com/api/download/models/2235288?token=${CIVITAI_API_TOKEN}" "DR34MJOB LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/oral"
    download_and_check "https://civitai.com/api/download/models/2152516?token=${CIVITAI_API_TOKEN}" "jfj-deepthroat HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/oral"
    download_and_check "https://civitai.com/api/download/models/2152583?token=${CIVITAI_API_TOKEN}" "jfj-deepthroat LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/oral"
    download_and_check "https://civitai.com/api/download/models/2193369?token=${CIVITAI_API_TOKEN}" "I2V Blowjob HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/oral"
    download_and_check "https://civitai.com/api/download/models/2193373?token=${CIVITAI_API_TOKEN}" "I2V Blowjob LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/oral"
    download_and_check "https://civitai.com/api/download/models/2087173?token=${CIVITAI_API_TOKEN}" "pworship HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/oral"
    download_and_check "https://civitai.com/api/download/models/2087124?token=${CIVITAI_API_TOKEN}" "pworship LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/oral"
    download_and_check "https://civitai.com/api/download/models/2178869?token=${CIVITAI_API_TOKEN}" "f4c3spl4sh LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/oral"
    download_and_check "https://civitai.com/api/download/models/2176450?token=${CIVITAI_API_TOKEN}" "f4c3spl4sh HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/oral"
    download_and_check "https://civitai.com/api/download/models/2122049?token=${CIVITAI_API_TOKEN}" "ultimatedeepthroat HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/oral"
    download_and_check "https://civitai.com/api/download/models/2191446?token=${CIVITAI_API_TOKEN}" "ultimatedeepthroat LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/oral"
    download_and_check "https://civitai.com/api/download/models/2164213?token=${CIVITAI_API_TOKEN}" "Double-Blowjob HIGH" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/oral"
    download_and_check "https://civitai.com/api/download/models/2164348?token=${CIVITAI_API_TOKEN}" "Double-Blowjob LOW" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/oral"


    ## These go in /loras/sex
    download_and_check "https://civitai.com/api/download/models/2195862?token=${CIVITAI_API_TOKEN}" "W22_NSFW_Posing_Nude_i2v_HN_v1" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/NSFW"
    download_and_check "https://civitai.com/api/download/models/2195866?token=${CIVITAI_API_TOKEN}" "W22_NSFW_Posing_Nude_i2v_LN_v1" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/NSFW"
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
    download_and_check "https://civitai.com/api/download/models/2273468?token=${CIVITAI_API_TOKEN}" "slop_twerk_HighNoise_merged3_7_v2" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/sex"
    download_and_check "https://civitai.com/api/download/models/2273467?token=${CIVITAI_API_TOKEN}" "slop_twerk_LowNoise_merged3_7_v2" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/sex"


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
        echo "All WAN LoRA models were downloaded successfully."
    fi
    echo
fi # This 'fi' closes the conditional block for WAN LoRAs

if [[ "$MODEL_SETS" == *"qwen"* ]]; then
    echo
    echo "--- Starting Sequential Download of qwen-specific LoRA Models ---"



    # --- Configuration ---
    mkdir -p "${COMFYUI_BASE_PATH}/models/loras/qwen"
    mkdir -p "${COMFYUI_BASE_PATH}/models/loras/qwen/general"
    mkdir -p "${COMFYUI_BASE_PATH}/models/loras/qwen/nsfw"
    LORA_DIR="${COMFYUI_BASE_PATH}/models/loras/qwen"
    FAILED_DOWNLOADS=()

    # 2. Download all models sequentially

    echo "--- Downloading Civitai qwen LoRAs ---"
    ## These go in /loras/qwen/general

    download_and_check "https://civitai.com/api/download/models/2270374?token=${CIVITAI_API_TOKEN}" "Samsung" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/general"
    download_and_check "https://civitai.com/api/download/models/2256755?token=${CIVITAI_API_TOKEN}" "consistence_edit_v2" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/general"
    download_and_check "https://civitai.com/api/download/models/2179228?token=${CIVITAI_API_TOKEN}" "qwen_image_snapchat" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/general"
    download_and_check "https://civitai.com/api/download/models/2196278?token=${CIVITAI_API_TOKEN}" "clothes_tryon_qwen-edit-lora" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/general"
    download_and_check "https://civitai.com/api/download/models/2289403?token=${CIVITAI_API_TOKEN}" "Qwen-Image_SmartphoneSnapshotPhotoReality_v4_by-AI_Characters_TRIGGER$amateur photo$" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/general"

    ## These go in /loras/qwen/nsfw
    download_and_check "https://civitai.com/api/download/models/2183622?token=${CIVITAI_API_TOKEN}" "QWEN_jtn_barbell" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/nsfw"
    download_and_check "https://civitai.com/api/download/models/2160909?token=${CIVITAI_API_TOKEN}" "ghostnipples1" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/nsfw"
    download_and_check "https://civitai.com/api/download/models/2217791?token=${CIVITAI_API_TOKEN}" "[QWEN] Send Nudes Pro - Beta v1" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/nsfw"
    download_and_check "https://civitai.com/api/download/models/2310533?token=${CIVITAI_API_TOKEN}" "QwenSnofs1_1" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/nsfw"
    download_and_check "https://civitai.com/api/download/models/2105899?token=${CIVITAI_API_TOKEN}" "qwen_MCNL_v1.0" --user-agent="Mozilla/5.0" --content-disposition -P "$LORA_DIR/nsfw"

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
        echo "All qwen LoRA models were downloaded successfully."
    fi
    echo
fi # This 'fi' closes the conditional block for qwen LoRAs


# =================================================================
# --- FINAL INSTRUCTIONS ---
# =================================================================
echo "=== Custom Vast Setup Complete! ==="
echo "Next steps:"
echo "1. Ensure you have already run the package alignment and SageAttention install scripts."
echo "2. Restart the ComfyUI container/process."
echo "3. Load your workflow and enjoy!"