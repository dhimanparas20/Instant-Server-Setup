#!/usr/bin/env zsh
set -euo pipefail

# Error handler for zsh (ZERR instead of bash's ERR)
trap 'echo -e "\e[31mError occurred at line $LINENO. Exiting.\e[0m"' ZERR

GIT_USER="dhimanparas20"
GIT_EMAIL="dhimanparas20@gmail.com"

if [ "$(id -u)" -ne 0 ]; then
    echo -e "\e[31mPlease run this script with sudo:\e[0m"
    echo "sudo $0"
    exit 1
fi

clear
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                            Installing Dependencies                              \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5

export DEBIAN_FRONTEND=noninteractive

apt update -q
apt upgrade -yq
add-apt-repository -y universe

PKGS=(
    curl postgresql  postgresql-contrib git uidmap snapd python3 python3-pip pipx python3-venv
    fuse tmate libfuse2 ufw dnsutils neofetch net-tools htop btop network-manager tlp tlp-rdw
    software-properties-common "linux-headers-$(uname -r)"
)

for pkg in "${PKGS[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
        apt install -yq "$pkg"
    fi
done

pipx ensurepath

echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                            Installing Other Stuff                               \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
curl -LsSf https://astral.sh/uv/install.sh | bash
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                         Installing from SNAP Store                              \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5
snap install ngrok docker

# echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
# echo -e "\e[34m                                 Installing Docker                               \e[0m"
# echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
# sleep 0.5
# wget -q https://get.docker.com -O install-docker.sh
# chmod +x install-docker.sh
# zsh install-docker.sh
# rm install-docker.sh

# Add user to docker group
# groupadd -f docker
# usermod -aG docker "$SUDO_USER"

echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                                 Adding Git Configs                              \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5

git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_EMAIL"
git config --global credential.helper cache
git config --global credential.helper store

echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                                    DONE                                         \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 1
