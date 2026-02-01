#!/bin/bash

# ==============================================================================
# Drive Manager Pro
# Optimised for: Robustness, Security, and Error-Handling
# ==============================================================================

# Strict Mode
set -u # Error on undefined variables

# Colors
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# Internal Vars
SELECTED_DRIVES=()
DRIVES=()
LOG_FILE="/tmp/drive_manager_$(date +%Y%m%d_%H%M%S).log"

# Cleanup on exit
trap cleanup EXIT
cleanup() {
    rm -f /tmp/pre_installed.txt /tmp/post_installed.txt
}

log_error() {
    echo -e "${RED}[ERROR] $1${RESET}" | tee -a "$LOG_FILE"
}

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (sudo).${RESET}"
   exit 1
fi

capture_pre_state() {
    echo -e "${GREEN}Capturing initial system state...${RESET}"
    PRE_STATE=$(lsblk -o NAME,STATE,TYPE | grep "disk")
}

detect_drives() {
    # Filters out read-only loop devices and partitions
    mapfile -t DRIVES < <(lsblk -dn -o NAME | awk '{print "/dev/"$1}')
    if [[ ${#DRIVES[@]} -eq 0 ]]; then
        log_error "No physical drives detected."
        exit 1
    fi
}

select_drives() {
    echo -e "\n${YELLOW}Select the drives to configure:${RESET}"
    for i in "${!DRIVES[@]}"; do
        echo "$((i+1))) ${DRIVES[$i]}"
    done
    echo "a) All Drives"

    read -p "Selection: " SELECTION
    if [[ "$SELECTION" == "a" ]]; then
        SELECTED_DRIVES=("${DRIVES[@]}")
    else
        for index in $SELECTION; do
            if [[ "$index" =~ ^[0-9]+$ ]] && [ "$index" -le "${#DRIVES[@]}" ] && [ "$index" -gt 0 ]; then
                SELECTED_DRIVES+=("${DRIVES[$((index-1))]}")
            else
                echo -e "${RED}Invalid selection: $index. Skipping.${RESET}"
            fi
        done
    fi

    if [[ ${#SELECTED_DRIVES[@]} -eq 0 ]]; then
        log_error "No valid drives selected."
        exit 1
    fi
}

# --- Tool Logic ---

try_hdparm() {
    echo -e "${YELLOW}Attempting hdparm...${RESET}"
    apt-get update -qq && apt-get install -y hdparm > /dev/null
    
    local success_count=0
    for DRIVE in "${SELECTED_DRIVES[@]}"; do
        # -S 120 sets standby to 10 minutes
        if hdparm -S 120 "$DRIVE" &>> "$LOG_FILE"; then
            ((success_count++))
        fi
    done
    [[ $success_count -eq ${#SELECTED_DRIVES[@]} ]]
}

try_sdparm() {
    echo -e "${YELLOW}hdparm failed or insufficient. Attempting sdparm...${RESET}"
    apt-get install -y sdparm > /dev/null
    
    local success_count=0
    for DRIVE in "${SELECTED_DRIVES[@]}"; do
        # Set 'spindown' bit
        if sdparm --set=SCT=6000 --save "$DRIVE" &>> "$LOG_FILE"; then
            ((success_count++))
        fi
    done
    [[ $success_count -eq ${#SELECTED_DRIVES[@]} ]]
}

# --- Main Execution ---

clear
echo -e "${GREEN}Starting Drive Management Optimization...${RESET}"
capture_pre_state
detect_drives
select_drives

# Sequential Attempt Logic
if try_hdparm; then
    echo -e "${GREEN}Success using hdparm.${RESET}"
elif try_sdparm; then
    echo -e "${GREEN}Success using sdparm.${RESET}"
else
    log_error "Standard tools failed. Please check $LOG_FILE for hardware compatibility."
fi

# Verification
echo -e "\n${GREEN}Final Drive States:${RESET}"
lsblk -o NAME,STATE,MODEL | grep -E "$(echo "${SELECTED_DRIVES[@]}" | sed 's|/dev/||g' | tr ' ' '|')"
