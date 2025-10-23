#!/bin/bash
set -e


# =================================================================
# --- STEP 1: WAIT FOR THE OFFICIAL INSTALLATION TO COMPLETE ---
# We wait for the final file-based action of the provisioning script:
# the download of a checkpoint model. We do this by checking if the
# checkpoints directory is no longer empty.
# =================================================================

CHECKPOINTS_DIR="/workspace/ComfyUI/models/checkpoints"

echo "--- [CUSTOM] Waiting for the default ComfyUI installation to complete... ---"
echo "--- [CUSTOM] (Will proceed once a model appears in '${CHECKPOINTS_DIR}') ---"

# This loop will continue as long as the checkpoints directory is empty.
# 'ls -A' lists all files including hidden ones. If it produces any output,
# the directory is not empty, and the loop stops.
while [ -z "$(ls -A ${CHECKPOINTS_DIR} 2>/dev/null)" ]; do
  # Sleep for 3 seconds between checks.
  sleep 3
done

echo "✓ [CUSTOM] Default ComfyUI installation is 100% complete. Proceeding with custom setup."
echo

print_art() {
cat << 'EOF'


 -----------------:----:--:-:-:------------**+=#%%+----------------------------- 
 -----------:--:----------------:--:--:==::==:-#-####=-:--:-=:--:--:--:--:--:--- 
 ----------=--:::::::--:-----------==-=*#+::=%-:#%##=+#+----+:------------------ 
 -------==--:::::::::::::-:-------====:::#**::%==%*+%*+=#--=+:------------------ 
 ====-===-===-----:::::::::-:------:-=-=-==:#::*:=+#=%+*=#-++.:----------------- 
 ---==============--::::::::-::===-::::---=:-=:---+++#++#*==+::=-----=========== 
 =-===*###*++++==---:::::::::-::==*-:.:::::::----=*++++*#%==+.:================= 
 =-==#@@@@#**+====---:::::::::::-::=:........::::-####**%%++=:::================ 
 ===+#@@@@#*+===------::::::--::--:-.:::::::-=*##%%%@@%*@#++=:::================ 
 ==+*#%@%##*+++==========---==-=-=::.:::::::-=+###%%%@%%%%===:::========++++++++ 
 *####%%######*******####=-######=:: .::-:-++++*##%%%@@%%#++=::.-=============== 
 ###*##%%##*+. :=.  - =-:===++*##. .:::..::==*+-===-==*@%#*+-::::########******* 
 *#++*##@%#*    : ..===:==::::=+#: .:::.. ...:---:.+.:+@@=##-::::*************** 
 ##+=+=###**:   .-= :=.- -:=-.=+#. -:.........#@*::-=%@@@##*:::::=############## 
 ###====+*++=-  :.:-=+:-==-=.:=###..-:....::::#@@@#*##%@#++=:::::.############## 
 %%%%=-=-==--=+: .  .:+:.:-.-+%%%%%%::::::::.:#@@@%%####+*++.:::::%%%%%%%%%%%%%% 
 @@@@@@=---::==:::*=#.:-: :=@@@@@@@@:...:::::.:*+#@@%###*+++::::::=@@@@@@@@@@@@@ 
 @@@@@@@@@--:::      : -=@@@@@@%-   .....:....::@@@@%###*===:::::::@@@@@@@@@@@@@ 
 @@@@@@@@@@@@@@@%#%@@@@@@@#       ............::..:#%##......::::::@@@@@@@@@@@@@ 
 @@@@@@@@@@@@@@@@@@@@@@*           ..........:--=**###@=.      .....:.::=#@@@@@@ 
 @@@@@@@@@@@@@@@@@@@*              ..... ......:=*###%@*         ...........*  . 
 @@@@@@@@@@@@@@@*                  .. . .  ...::+*####%.         . .    .......  
 @@@@@@=@@.#==                     ... ..........=####=                .. ...... 
 @@@:%@ :                           ... .......:+*=**=.                  ....... 
 #:+   : :                           ... .....:::==+=                    . ..... 
       *%%%%%%+                       .........::-=-                     ....... 
   .   .+:-=+*##%%%@@@#.               .....::.:::-                            . 
   . .   :   .:::+#@%#%%%@            :#+:..::::::                               
   . .            =*#%##%%@@@@@@=  :%=.::   :=-:                                 
                 .:-##%%%@@@%%%%@#-::.:                                          
      :          .:*####%@@@%#*#@:::.                                       . .. 
                 .:*#%#%%%%%@%@@@@#:                                             
 ......        ..:+#%%::#%%%#:====%%.                                         .. 
 ------       =::=###-..-+%%#... ..                                           .  
 -----        ::-=#=    :=*%%:                                                 . 
 =-==        ..:=#:      :-#%%                                                   
 +==:         .*#:       .:=#.                                                   
 *==         .-:                                                      .          
 **:                                                                  #*         
 ==:@@@@                               @@@.                          :=+:        
 %%@@@%% %%%   %%%   %@@@+     %@@@    @@@   *@@@@  %%%     %%%  -@@@*    %%% #% 
  :@@=  %@@.   @@@ @@@  *** -@@@  @@@  @@@ @@@   @@@ @@@  -@@@ @@@.  @@@ @@@@@@@ 
  @@@   @@@   @@@   @@@@@@@ @@@@@@@@@@#@@  @@@@@%@@:  @@@@@@  *@@@@@@@@@ @@@     
  @@@   @@@@@@@@@ #@@@@@@@@  @@@@@@@@ @@@ @@@@@@@@@   .@@@@    @@@@@@@@  @@%     
                                                      @@@+                       
                                                    @@%                          
                                                                                 




EOF
echo "========================================================================================"
}

# --- SCRIPT START ---

# --- Initial Configuration ---
COMFYUI_BASE_PATH="/workspace/ComfyUI"
PYTHON_EXEC="/venv/main/bin/python3"

# --- NEW: Wait for the default ComfyUI installation to complete ---
echo "→ [CUSTOM] Waiting for the default ComfyUI installation to finish..."
while [ ! -f "${COMFYUI_BASE_PATH}/main.py" ]; do
  sleep 2
done
echo "✓ [CUSTOM] Default ComfyUI installation detected. Proceeding with custom setup."
echo

print_art
echo "=== [CUSTOM] Master Setup Initializing... ==="
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
wget -q -O vast_setup.sh https://raw.githubusercontent.com/mscln1/vast-WAN22-I2V/refs/heads/main/vast_setup.sh
wget -q -O install_sage_vast.sh https://raw.githubusercontent.com/mscln1/vast-WAN22-I2V/refs/heads/main/install_sage_vast.sh
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

echo "=== Custom Setup Complete ==="
print_art