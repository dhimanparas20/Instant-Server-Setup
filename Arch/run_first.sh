#!/bin/bash
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script with sudo:"
    echo "sudo ./run_first_arch.sh"
    exit 1
fi

clear
echo "---------------------------------------------------------------------------------"
echo "                            Installing Dependencies                              "
echo "---------------------------------------------------------------------------------"
sleep 0.5
set -e

pacman -Syu --noconfirm
pacman -S --noconfirm curl git python python-pip python-virtualenv fuse tmate ufw bind net-tools htop btop networkmanager tlp linux-headers base-devel unzip wget

# yay for AUR packages (if not installed)
if ! command -v yay &> /dev/null; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd -
fi

yay -S --noconfirm lazydocker postgresql postgresql-libs postgresql-old-upgrade snapd pipx fastfetch

pipx ensurepath

# Enable snapd
systemctl enable --now snapd.socket
ln -s /var/lib/snapd/snap /snap || true

echo "---------------------------------------------------------------------------------"
echo "                            Installing Other Stuff                               "
echo "---------------------------------------------------------------------------------"
sleep 0.5
curl -LsSf https://astral.sh/uv/install.sh | sh
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

echo "---------------------------------------------------------------------------------"
echo "                         Installing from SNAP Store                              "
echo "---------------------------------------------------------------------------------"
sleep 0.5
snap install ngrok

echo "---------------------------------------------------------------------------------"
echo "                                 Installing Docker                               "
echo "---------------------------------------------------------------------------------"
sleep 0.5
pacman -S --noconfirm docker
systemctl enable --now docker
usermod -aG docker $USER

echo "---------------------------------------------------------------------------------"
echo "                                 Adding Git Configs                              "
echo "---------------------------------------------------------------------------------"
sleep 0.5
git config --global user.name "dhimanparas20"
git config --global user.email "dhimanparas20@gmail.com"
git config --global credential.helper cache
git config --global credential.helper store

echo "---------------------------------------------------------------------------------"
echo "                                    Reboot                                       "
echo "---------------------------------------------------------------------------------"
echo "after reboot proceed to 2nd step"
sleep 1
reboot
