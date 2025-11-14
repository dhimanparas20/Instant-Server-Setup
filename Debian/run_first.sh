#!/usr/bin/env bash
set -euo pipefail

trap 'echo -e "\e[31mError occurred at line $LINENO. Exiting.\e[0m"' ERR

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
# add-apt-repository universe

PKGS=(
    curl postgresql lazydocker postgresql-contrib git uidmap snapd python3 python3-pip pipx python3-venv
    fuse tmate libfuse2 ufw dnsutils fastfetch net-tools htop btop network-manager tlp tlp-rdw linux-headers-$(uname -r)
)
for pkg in "${PKGS[@]}"; do
    if ! dpkg -s $pkg &>/dev/null; then
        apt install -yq $pkg
    fi
done

pipx ensurepath

echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                            Installing Other Stuff                               \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5
curl -LsSf https://astral.sh/uv/install.sh | sh
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                         Installing from SNAP Store                              \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5
snap install ngrok

echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                                 Installing Docker                               \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5
wget -q https://get.docker.com -O install-docker.sh
chmod +x install-docker.sh
./install-docker.sh
rm install-docker.sh

# Add user to docker group
groupadd -f docker
usermod -aG docker $SUDO_USER

echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                                 Adding Git Configs                              \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5
git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_EMAIL"
git config --global credential.helper cache
git config --global credential.helper store

echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                                    Reboot                                       \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo "After reboot, proceed to 2nd step"
sleep 1
reboot
