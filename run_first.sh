#!/bin/bash
# The script must be run using sudo
# The script also sets up some configurations wherever needed

# Check if the script is run with sudo
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script with sudo:"
    echo "sudo ./run_first.sh"
    exit 1
fi

# Start
clear
echo "---------------------------------------------------------------------------------"
echo "                            Installing Dependencies                              "
echo "---------------------------------------------------------------------------------"
sleep 0.5
set -e

# Disable interactive prompts
export DEBIAN_FRONTEND=noninteractive

# The Basics
apt update -q
apt upgrade -yq
apt install -yq curl postgresql postgresql-contrib git snapd python3 python3-pip python3-venv ufw dnsutils neofetch net-tools htop network-manager

# Install LazyDocker
clear
echo "---------------------------------------------------------------------------------"
echo "                            Installing LazyDocker                                "
echo "---------------------------------------------------------------------------------"
sleep 0.5
curl -sSL https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository | sudo bash
apt install -yq lazydocker

# Install Docker
clear
echo "---------------------------------------------------------------------------------"
echo "                                 Installing Docker                               "
echo "---------------------------------------------------------------------------------"
sleep 0.5
wget -q https://get.docker.com -O install-docker.sh
chmod +x install-docker.sh
./install-docker.sh
rm install-docker.sh

# Store git passwords and add user signature
clear
echo "---------------------------------------------------------------------------------"
echo "                                 Adding Git Configs                              "
echo "---------------------------------------------------------------------------------"
sleep 0.5
git config --global user.name "dhimanparas20"
git config --global user.email "dhimanparas20@gmail.com"
git config --global credential.helper cache
git config --global credential.helper store

# Clone Full Repo
clear
echo "---------------------------------------------------------------------------------"
echo "                           Downloading next Script                               "
echo "---------------------------------------------------------------------------------"
sleep 0.5
wget -q https://raw.githubusercontent.com/dhimanparas20/Instant-Server-Setup/main/run_second.sh
wget -q https://raw.githubusercontent.com/dhimanparas20/Instant-Server-Setup/main/dockerAlias.sh
chmod +x run_second.sh

# Finally Rebooting
clear
echo "---------------------------------------------------------------------------------"
echo "                                    Reboot                                       "
echo "---------------------------------------------------------------------------------"
echo "after reboot proceed to 2nd step"
sleep 1
reboot
