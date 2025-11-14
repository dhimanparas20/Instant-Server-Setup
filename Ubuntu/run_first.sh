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
add-apt-repository universe
apt install -yq curl postgresql postgresql-contrib git uidmap snapd python3 python3-pip pipx python3-venv fuse tmate libfuse2 ufw dnsutils fastfetch net-tools htop btop network-manager tlp tlp-rdw linux-headers-$(uname -r)
pipx ensurepath

# Install Other Stuff
echo "---------------------------------------------------------------------------------"
echo "                            Installing Other Stuff                               "
echo "---------------------------------------------------------------------------------"
sleep 0.5
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash #Lazydocker
curl -LsSf https://astral.sh/uv/install.sh | sh                                                          # UV
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh                     # zoxide

# Install LazyDocker
echo "---------------------------------------------------------------------------------"
echo "                         Installing from SNAP Store                              "
echo "---------------------------------------------------------------------------------"
sleep 0.5
snap install ngrok
# snap install docker


# Install Docker
echo "---------------------------------------------------------------------------------"
echo "                                 Installing Docker                               "
echo "---------------------------------------------------------------------------------"
sleep 0.5
wget -q https://get.docker.com -O install-docker.sh
chmod +x install-docker.sh
./install-docker.sh
rm install-docker.sh
dockerd-rootless-setuptool.sh install


# Store git passwords and add user signature
echo "---------------------------------------------------------------------------------"
echo "                                 Adding Git Configs                              "
echo "---------------------------------------------------------------------------------"
sleep 0.5
git config --global user.name "dhimanparas20"
git config --global user.email "dhimanparas20@gmail.com"
git config --global credential.helper cache
git config --global credential.helper store\]


# Finally Rebooting
echo "---------------------------------------------------------------------------------"
echo "                                    Reboot                                       "
echo "---------------------------------------------------------------------------------"
echo "after reboot proceed to 2nd step"
#groupadd docker
#usermod -aG docker $USER
#newgrp docker
sleep 1
reboot
