
# Raspberry Pi Hard Drive Power Management Script

A simple and effective shell script to manage hard drive power settings on Raspberry Pi and similar Linux-based systems. This script installs and configures tools like `hdparm`, `hd-idle`, and `sdparm` to spin down hard drives automatically when they're not in use, helping extend the life of your USB or SATA drives by reducing wear from continuous operation.

## 📜 Purpose

Linux systems don’t always have built-in configurations to automatically manage hard drive spin-down settings. This script provides an automated way to install and configure the necessary tools to put your hard drive into standby mode when inactive, just like on Windows systems.

Whether you're running a media center, a backup server, or a lightweight home server on a Raspberry Pi, this script helps reduce power consumption and noise from idle hard drives, prolonging the drive's lifespan.

## 🛠 Tools and Installation Steps

The script uses three tools:
- **hdparm**: A common utility for configuring hard drive parameters.
- **hd-idle**: An alternative for drives not compatible with `hdparm`.
- **sdparm**: A last-resort option for spinning down drives if other tools fail.

The script runs in sequence, first attempting to use `hdparm`, then `hd-idle`, and finally `sdparm`. Each tool is only installed and configured if the previous one does not work for the given setup.

### Features

- **Automatic Installation**: The script installs only necessary tools based on compatibility, ensuring minimal setup.
- **Automatic Spin-down**: Configures idle spin-down time to 10 minutes by default, saving power and reducing drive wear.
- **Rollback Capability**: If the script exits prematurely, it automatically rolls back any installed components and configurations to restore the system to its pre-execution state.

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
2. **Install `hdparm`**:
   - Installs `hdparm` and attempts to configure it to manage hard drive power settings.
   - If the drive supports `hdparm`, it configures a spin-down time and enables write caching.
3. **Install `hd-idle`** (if `hdparm` fails):
   - Removes `hdparm`, installs `hd-idle`, and configures it to spin down the drive every 10 minutes.
4. **Install `sdparm`** (as a last resort):
   - If both `hdparm` and `hd-idle` are incompatible, `sdparm` is installed, and a cron job is set up to spin down the drive hourly.

### Rollback Mechanism

If the script exits unexpectedly, it rolls back all installed packages and configurations, ensuring no unwanted settings or software remain.

## 🔄 Customization Options

- **Spin-down Time**: Modify the spin-down time for each tool in the script to suit your needs.
- **Custom Drives**: The script assumes the primary hard drive is located at `/dev/sda`. If using a different drive, replace `/dev/sda` with the correct device identifier.

## 📄 License

This script is free to use, modify, and distribute for personal and commercial projects. Feel free to share and improve the code for the community!

## ❤️ Support the Project

If you find this project useful and would like to support further development, consider donating via PayPal at [gopalasubramanium@gmail.com](mailto:gopalasubramanium@gmail.com). Thank you for your support!
