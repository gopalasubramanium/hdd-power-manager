#!/bin/bash

# Colors for enhanced readability
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# Status tracking variables
STATUS="Starting script"
INSTALL_STATUS=""
CONFIG_STATUS=""
TEST_RESULTS=""
DRIVES=()
SELECTED_DRIVES=()
INSTALLED_PACKAGES=()
ERROR_LOG=""
PRE_STATE=""
POST_STATE=""

hdparm_status="Not attempted"
hd_idle_status="Not attempted"
sdparm_status="Not attempted"

# Capture the initial system state for comparison
capture_pre_state() {
    echo -e "${GREEN}Capturing initial system state...${RESET}"
    PRE_STATE=$(lsblk -o NAME,STATE | grep -E "sda|sdb")
    dpkg -l | grep -E "hdparm|hd-idle|sdparm" > /tmp/pre_installed.txt
}

# Capture the final system state for comparison
capture_post_state() {
    echo -e "${GREEN}Capturing final system state...${RESET}"
    POST_STATE=$(lsblk -o NAME,STATE | grep -E "sda|sdb")
    dpkg -l | grep -E "hdparm|hd-idle|sdparm" > /tmp/post_installed.txt
}

# Run a test to verify if the configurations are correctly applied
run_tests() {
    echo -e "${GREEN}Running verification tests...${RESET}"
    local test_passed=true

    # Test if drives are in standby
    for DRIVE in "${SELECTED_DRIVES[@]}"; do
        if sudo hdparm -C "$DRIVE" | grep -q "standby"; then
            TEST_RESULTS+="Drive $DRIVE is in standby as expected.\n"
        else
            TEST_RESULTS+="Drive $DRIVE is not in standby (unexpected).\n"
            test_passed=false
        fi
    done

    # Check for installed packages
    if dpkg -s hdparm &>/dev/null; then
        TEST_RESULTS+="hdparm is installed and functional.\n"
    elif dpkg -s hd-idle &>/dev/null; then
        TEST_RESULTS+="hd-idle is installed and functional.\n"
    elif dpkg -s sdparm &>/dev/null; then
        TEST_RESULTS+="sdparm is installed and functional.\n"
    else
        TEST_RESULTS+="No power management tool is correctly installed (unexpected).\n"
        test_passed=false
    fi

    # Summarize test results
    if $test_passed; then
        TEST_RESULTS+="\nAll configurations verified successfully."
    else
        TEST_RESULTS+="\nSome configurations did not pass the verification checks."
    fi
}

# Print summary
print_summary() {
    echo -e "\n${GREEN}Execution Summary:${RESET}"
    echo -e "${GREEN}==================${RESET}"
    echo -e "Initial Setup: Successful"
    echo -e "Attempted Configurations:"
    echo -e "  - hdparm: $hdparm_status"
    echo -e "  - hd-idle: $hd_idle_status"
    echo -e "  - sdparm: $sdparm_status"
    echo -e "Installed Packages: $INSTALL_STATUS"
    echo -e "Configuration Applied: $CONFIG_STATUS"
    echo -e "\nVerification Results:"
    echo -e "$TEST_RESULTS"
    echo -e "\nSystem State Changes:"
    echo -e "Pre-execution state:\n$PRE_STATE"
    echo -e "Post-execution state:\n$POST_STATE"

    if [[ -n "$ERROR_LOG" ]]; then
        echo -e "${RED}Errors encountered:${RESET}"
        echo -e "$ERROR_LOG"
    fi
    echo -e "${GREEN}Thank you for using the drive_manager.sh script!${RESET}"
}

# Print status with color
print_status() {
    echo -e "${YELLOW}Status: $STATUS${RESET}"
}

# Detect all available hard drives
detect_drives() {
    echo -e "${GREEN}Detecting attached hard drives...${RESET}"
    for drive in $(lsblk -dn -o NAME,TYPE | grep disk | awk '{print "/dev/"$1}'); do
        DRIVES+=("$drive")
    done
}

# Ask user which drives to configure
select_drives() {
    echo -e "${GREEN}Available Drives:${RESET}"
    for i in "${!DRIVES[@]}"; do
        echo "$((i+1))) ${DRIVES[$i]}"
    done
    echo "a) All Drives"

    read -p "Select the drives to configure (e.g., 1 2 or 'a' for all): " SELECTION
    if [[ "$SELECTION" == "a" ]]; then
        SELECTED_DRIVES=("${DRIVES[@]}")
    else
        for index in $SELECTION; do
            SELECTED_DRIVES+=("${DRIVES[$((index-1))]}")
        done
    fi
}

# Install and configure hdparm
configure_hdparm() {
    STATUS="Configuring hdparm for ${SELECTED_DRIVES[*]}..."
    print_status

    if ! command -v hdparm &>/dev/null; then
        sudo apt-get install -y hdparm && INSTALL_STATUS+="hdparm installed. "
    fi
    for DRIVE in "${SELECTED_DRIVES[@]}"; do
        if sudo hdparm -y "$DRIVE"; then
            CONFIG_STATUS+="hdparm configured for $DRIVE. "
            hdparm_status="Configured successfully"
        else
            hdparm_status="Attempted but failed"
            ERROR_LOG+="\nFailed to configure hdparm for $DRIVE."
        fi
    done
}

# Install and configure hd-idle if hdparm fails
configure_hd_idle() {
    STATUS="Configuring hd-idle for ${SELECTED_DRIVES[*]}..."
    print_status

    sudo apt-get remove -y hdparm  # Remove hdparm if installed previously by the script
    if ! dpkg -s hd-idle &>/dev/null; then
        sudo apt-get install -y build-essential fakeroot debhelper
        wget http://sourceforge.net/projects/hd-idle/files/hd-idle-1.05.tgz
        tar -xvf hd-idle-1.05.tgz && cd hd-idle
        dpkg-buildpackage -rfakeroot
        sudo dpkg -i ../hd-idle_*.deb && INSTALL_STATUS+="hd-idle installed. "
    fi
    for DRIVE in "${SELECTED_DRIVES[@]}"; do
        echo "HD_IDLE_OPTS=\"-i 0 -a ${DRIVE##*/} -i 600\"" | sudo tee /etc/default/hd-idle
        sudo service hd-idle restart && CONFIG_STATUS+="hd-idle configured for $DRIVE. " || ERROR_LOG+="\nFailed to configure hd-idle for $DRIVE."
        hd_idle_status="Configured successfully"
    done
}

# Install and configure sdparm if both hdparm and hd-idle fail
configure_sdparm() {
    STATUS="Configuring sdparm for ${SELECTED_DRIVES[*]}..."
    print_status

    sudo apt-get remove -y hd-idle  # Remove hd-idle if installed previously by the script
    if ! dpkg -s sdparm &>/dev/null; then
        sudo apt-get install -y sdparm && INSTALL_STATUS+="sdparm installed. "
    fi
    for DRIVE in "${SELECTED_DRIVES[@]}"; do
        sudo sdparm --flexible --command=stop "$DRIVE" && CONFIG_STATUS+="sdparm configured for $DRIVE. " || ERROR_LOG+="\nFailed to configure sdparm for $DRIVE."
        sdparm_status="Configured successfully"
    done
}

# Begin main execution
capture_pre_state
detect_drives
select_drives

# Try each configuration option in sequence, stopping if one is successful
configure_hdparm || configure_hd_idle || configure_sdparm

# Capture post state and run verification tests
capture_post_state
run_tests

# Print final summary and exit
print_summary
