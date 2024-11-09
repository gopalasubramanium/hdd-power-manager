#!/bin/bash

# Define a rollback function in case of incomplete execution
rollback() {
  echo "Rolling back changes..."
  # Remove installed packages
  sudo apt-get remove -y hdparm hd-idle sdparm
  # Remove any created cron jobs related to hd-idle and sdparm
  sudo crontab -l | grep -v "sdparm --command=stop /dev/sda" | sudo crontab -
  sudo crontab -l | grep -v "hd-idle" | sudo crontab -
  echo "Rollback completed."
  exit 1
}

# Trap any exit (error or manual) to run the rollback function
trap rollback EXIT

# Start installing required packages
echo "Updating repository list..."
sudo apt-get update

echo "Installing hdparm..."
sudo apt-get install -y hdparm || rollback

# Configure hdparm if installed successfully
echo "Configuring hdparm..."
sudo hdparm -y /dev/sda
sudo hdparm -I /dev/sda | grep 'Write cache' || rollback
sudo hdparm -B127 /dev/sda
echo "/dev/sda { write_cache = on; spindown_time = 120; }" | sudo tee -a /etc/hdparm.conf
sudo service hdparm restart

# Install and configure hd-idle if hdparm fails or as an alternative
echo "Removing hdparm and installing hd-idle..."
sudo apt-get remove -y hdparm
sudo apt-get install -y build-essential fakeroot debhelper || rollback
wget http://sourceforge.net/projects/hd-idle/files/hd-idle-1.05.tgz
tar -xvf hd-idle-1.05.tgz && cd hd-idle
dpkg-buildpackage -rfakeroot || rollback
sudo dpkg -i ../hd-idle_*.deb || rollback
echo "START_HD_IDLE=true" | sudo tee /etc/default/hd-idle
echo 'HD_IDLE_OPTS="-i 0 -a sda -i 600"' | sudo tee -a /etc/default/hd-idle
sudo service hd-idle restart

# Install and configure sdparm as a last resort
echo "Installing and configuring sdparm..."
sudo apt-get remove -y hd-idle
sudo apt-get install -y sdparm || rollback
sudo sdparm --flexible --command=stop /dev/sda || rollback
sudo crontab -l | { cat; echo "5 * * * * sdparm --command=stop /dev/sda"; } | sudo crontab -

# If everything went well, release the trap
trap - EXIT
echo "All configurations applied successfully!"
