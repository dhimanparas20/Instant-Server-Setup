#!/bin/bash
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script with sudo:"
    echo "sudo ./run_first_fedora.sh"
    exit 1
fi

clear
echo "---------------------------------------------------------------------------------"
echo "                            Installing Dependencies                              "
echo "---------------------------------------------------------------------------------"
sleep 0.5
set -e

dnf update -y
dnf install -y curl postgresql-server postgresql-contrib git python3 python3-pip python3-virtualenv fuse tmate ufw bind-utils net-tools htop btop NetworkManager tlp kernel-devel unzip wget

# Enable and initialize postgresql
systemctl enable --now postgresql
postgresql-setup --initdb

# Enable snapd
dnf install -y snapd
systemctl enable --now snapd.socket
ln -s /var/lib/snapd/snap /snap || true

# pipx and fastfetch
pip3 install --user pipx
pipx ensurepath
dnf install -y fastfetch

# LazyDocker (from COPR)
dnf copr enable atim/lazydocker -y
dnf install -y lazydocker

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
dnf install -y docker
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
