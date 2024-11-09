
# Raspberry Pi Hard Drive Power Management Script

A simple and effective shell script to manage hard drive power settings on Raspberry Pi and similar Linux-based systems. This script installs and configures tools like `hdparm`, `hd-idle`, and `sdparm` to spin down hard drives automatically when they're not in use, helping extend the life of your USB or SATA drives by reducing wear from continuous operation.

## 📜 Purpose

Linux systems don’t always have built-in configurations to automatically manage hard drive spin-down settings. This script provides an automated way to install and configure the necessary tools to put your hard drive into standby mode when inactive, just like on Windows systems.

Whether you're running a media center, a backup server, or a lightweight home server on a Raspberry Pi, this script helps reduce power consumption and noise from idle hard drives, prolonging the drive's lifespan.

## 🛠 Updated Features and Installation Steps

The script uses three tools in sequence (`hdparm`, `hd-idle`, and `sdparm`) to configure each selected hard drive. Only packages not already installed on the system are installed, preventing interference with pre-existing software (like OpenMediaVault). A rollback feature removes only the packages installed by this script if it exits unexpectedly.

### New Features

- **Automatic Installation with Safety Checks**: Installs only necessary tools based on compatibility, ensuring no interference with pre-existing software.
- **Interactive Drive Selection**: Detects all attached drives and prompts the user to choose specific drives or apply settings to all detected drives.
- **Automatic Spin-down**: Configures idle spin-down time to 10 minutes by default, saving power and reducing drive wear.
- **Rollback Capability**: If the script exits prematurely, it rolls back any installed components while preserving pre-existing packages.
- **Detailed Summary**: Provides a detailed summary at the end, listing all configurations applied.

## ⚙️ Usage

1. **Download the Script**: Download or clone the repository to your Raspberry Pi or compatible device.
2. **Make the Script Executable**: 
   ```bash
   chmod +x drive_manager.sh
   ```
3. **Run the Script with Root Privileges**: 
   ```bash
   sudo ./drive_manager.sh
   ```

### Step-by-Step Walkthrough

1. **Update Repositories**: The script begins by updating the local repository list to ensure you have the latest package sources.
2. **Drive Detection and Selection**:
   - Detects all connected hard drives and prompts the user to select specific drives or choose to configure all drives.
3. **Install and Configure `hdparm` (if needed)**:
   - Installs `hdparm` and configures each selected drive to manage hard drive power settings.
   - If `hdparm` is not compatible, it proceeds to install `hd-idle`.
4. **Install and Configure `hd-idle` (as an alternative)**:
   - Removes `hdparm` if it was installed by this script, installs `hd-idle`, and configures each selected drive to spin down every 10 minutes.
5. **Install and Configure `sdparm` (last resort)**:
   - If both `hdparm` and `hd-idle` are incompatible, `sdparm` is installed and a cron job is set up to spin down each selected drive hourly.
6. **Rollback Mechanism**:
   - If the script exits unexpectedly, it removes only the packages it installed, preserving any pre-existing configurations and software.

## 🔄 Customization Options

- **Spin-down Time**: Modify the spin-down time for each tool in the script to suit your needs.
- **Custom Drives**: The script assumes the primary hard drive is located at `/dev/sda`. If using a different drive, replace `/dev/sda` with the correct device identifier.

## 📄 License

This script is free to use, modify, and distribute for personal and commercial projects. Feel free to share and improve the code for the community!

## ❤️ Support the Project

If you find this project useful and would like to support further development, consider donating via PayPal at [gopalasubramanium@gmail.com](mailto:gopalasubramanium@gmail.com). Thank you for your support!
