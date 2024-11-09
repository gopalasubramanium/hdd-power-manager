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
DRIVES=()
INSTALLED_PACKAGES=()  # Tracks packages installed by the script

# Print status with color
print_status() {
    echo -e "${YELLOW}Status: $STATUS${RESET}"
}

# Print summary
print_summary() {
    echo -e "\n${GREEN}Execution Summary:${RESET}"
    echo -e "${GREEN}==================${RESET}"
    echo -e "Initial Setup: Successful"
    echo -e "Installed Packages: $INSTALL_STATUS"
    echo -e "Configuration Applied: $CONFIG_STATUS"
    echo -e "${GREEN}Thank you for using the drive_manager.sh script!${RESET}"
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

# Define a rollback function that only removes packages installed by this script
rollback() {
    echo -e "${RED}Rolling back changes...${RESET}"
    for package in "${INSTALLED_PACKAGES[@]}"; do
        echo -e "${RED}Removing $package...${RESET}"
        sudo apt-get remove -y "$package"
    done
    sudo crontab -l | grep -v "sdparm --command=stop" | sudo crontab -
    echo -e "${RED}Rollback completed.${RESET}"
    exit 1
}

# Trap any exit (error or manual) to run the rollback function
trap rollback EXIT

# Start installing required packages
STATUS="Updating repository list..."
print_status
sudo apt-get update || rollback

# Prompt user for drives selection
detect_drives
select_drives

# Loop through selected drives
for DRIVE in "${SELECTED_DRIVES[@]}"; do
    echo -e "${GREEN}Configuring power management for $DRIVE...${RESET}"

    STATUS="Installing hdparm..."
    print_status
    if ! dpkg -s hdparm >/dev/null 2>&1; then
        sudo apt-get install -y hdparm && INSTALL_STATUS="hdparm installed"
        INSTALLED_PACKAGES+=("hdparm")  # Track installation
    else
        echo -e "${YELLOW}hdparm is already installed; skipping installation.${RESET}"
    fi

    # Configure hdparm for the selected drive
    STATUS="Configuring hdparm for $DRIVE..."
    print_status
    sudo hdparm -y "$DRIVE" && CONFIG_STATUS="hdparm configured for $DRIVE"
    sudo hdparm -I "$DRIVE" | grep 'Write cache' || rollback
    sudo hdparm -B127 "$DRIVE"
    echo "$DRIVE { write_cache = on; spindown_time = 120; }" | sudo tee -a /etc/hdparm.conf
    sudo service hdparm restart

    # Install and configure hd-idle if hdparm fails or as an alternative
    STATUS="Removing hdparm and installing hd-idle..."
    print_status
    if [[ " ${INSTALLED_PACKAGES[@]} " =~ " hdparm " ]]; then
        sudo apt-get remove -y hdparm
        INSTALLED_PACKAGES=("${INSTALLED_PACKAGES[@]/hdparm}")
    fi
    if ! dpkg -s hd-idle >/dev/null 2>&1; then
        sudo apt-get install -y build-essential fakeroot debhelper || rollback
        wget http://sourceforge.net/projects/hd-idle/files/hd-idle-1.05.tgz
        tar -xvf hd-idle-1.05.tgz && cd hd-idle
        dpkg-buildpackage -rfakeroot || rollback
        sudo dpkg -i ../hd-idle_*.deb && INSTALL_STATUS="hd-idle installed"
        INSTALLED_PACKAGES+=("hd-idle")  # Track installation
    else
        echo -e "${YELLOW}hd-idle is already installed; skipping installation.${RESET}"
    fi
    echo "START_HD_IDLE=true" | sudo tee /etc/default/hd-idle
    echo "HD_IDLE_OPTS=\"-i 0 -a ${DRIVE##*/} -i 600\"" | sudo tee -a /etc/default/hd-idle
    sudo service hd-idle restart && CONFIG_STATUS="hd-idle configured for $DRIVE"

    # Install and configure sdparm as a last resort
    STATUS="Installing and configuring sdparm for $DRIVE..."
    print_status
    if [[ " ${INSTALLED_PACKAGES[@]} " =~ " hd-idle " ]]; then
        sudo apt-get remove -y hd-idle
        INSTALLED_PACKAGES=("${INSTALLED_PACKAGES[@]/hd-idle}")
    fi
    if ! dpkg -s sdparm >/dev/null 2>&1; then
        sudo apt-get install -y sdparm || rollback
        INSTALLED_PACKAGES+=("sdparm")  # Track installation
    else
        echo -e "${YELLOW}sdparm is already installed; skipping installation.${RESET}"
    fi
    sudo sdparm --flexible --command=stop "$DRIVE" || rollback
    sudo crontab -l | { cat; echo "5 * * * * sdparm --command=stop $DRIVE"; } | sudo crontab -
    INSTALL_STATUS="${INSTALL_STATUS}, sdparm installed"
    CONFIG_STATUS="${CONFIG_STATUS}, sdparm configured for $DRIVE"
done

# If everything went well, release the trap and print summary
trap - EXIT
print_summary
