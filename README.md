
# 🖥️ Drive Power Management Script

This script automates hard drive power management on Linux-based systems (e.g., Raspberry Pi) by configuring drives to spin down when inactive, thereby extending drive lifespan.

## 📋 Features

- **Drive Detection**: Automatically detects connected drives and prompts the user for selection.
- **Power Management Configuration**:
  - Installs and configures `hdparm`, `hd-idle`, or `sdparm` for automatic spin-down.
- **System State Tracking**: Captures the initial and final states of drives to verify configuration success.
- **Rollback on Failure**: Cleans up by uninstalling packages if configuration fails.
- **Verification Tests**: Ensures configurations are applied and provides a detailed summary.

## ⚙️ Prerequisites

- **Root Access**: Run the script with root privileges.
- **Internet Connection**: Required to install missing packages.

## 🚀 Usage

1. **Download the Script**: Save the script to your desired location.
2. **Make the Script Executable**:
   ```bash
   chmod +x drive_manager.sh
   ```
3. **Run the Script with Root Privileges**:
   ```bash
   sudo ./drive_manager.sh
   ```

## 🛠️ Configuration Steps

1. **Update Repositories**: Ensures the latest package versions.
2. **Drive Detection and Selection**: Detects drives and prompts the user for selection.
3. **Install and Configure `hdparm`**: 
   - Installs and configures `hdparm` for standby, spindown, and cache settings. Fallback to `hd-idle` if incompatible.
4. **Install and Configure `hd-idle`**: 
   - Removes `hdparm` if installed by the script, then configures `hd-idle`.
5. **Install and Configure `sdparm`**: 
   - Uses `sdparm` as a last resort for spin-down configuration.
6. **Verification and Summary**: Verifies configurations and provides a summary with pre- and post-execution states.

## 🔧 Customization

- **Spin-down Time**: Customize spin-down times in the script functions.
- **Drive Selection**: Modify drive detection if using non-standard paths.

## 📜 License

This script is free for personal and commercial use, modification, and redistribution.

## ❤️ Support

If you found this project helpful, consider donating via PayPal: [gopalasubramanium@gmail.com](mailto:gopalasubramanium@gmail.com). Thank you for your support!
