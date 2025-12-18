#!/usr/bin/env zsh

# Strict mode for zsh
set -eu
set -o pipefail

# Error handler for zsh
trap 'echo -e "\e[31mError occurred at line $LINENO. Exiting.\e[0m"' ZERR


clear
echo "\n---------------------------------------------------------------------------------"
echo "                            Installing Dependencies                              "
echo "---------------------------------------------------------------------------------"
sleep 0.5

# Disable interactive prompts
export DEBIAN_FRONTEND=noninteractive

# The Basics (system-wide)
sudo add-apt-repository -y ppa:danielrichter2007/grub-customizer
sudo apt update -q
sudo apt install -yq grub-customizer nvtop gparted unzip libfuse2 fuse
sudo apt autoremove -y
echo -e "\n\e[32m| DONE |\e[0m\n"


echo "\n---------------------------------------------------------------------------------"
echo "                            Installing Other Stuff                               "
echo "---------------------------------------------------------------------------------"
sleep 0.5

# NVM + Node (per-user)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# Load nvm into this script session so `nvm install` works
if [ -s "$HOME/.nvm/nvm.sh" ]; then
    # shellcheck disable=SC1090
    source "$HOME/.nvm/nvm.sh"
elif [ -s "/usr/share/nvm/init-nvm.sh" ]; then
    # some distros put it here
    # shellcheck disable=SC1091
    source "/usr/share/nvm/init-nvm.sh"
fi

nvm install node
echo -e "\n\e[32m| DONE |\e[0m\n"


echo "\n---------------------------------------------------------------------------------"
echo "                         Installing from SNAP Store                              "
echo "---------------------------------------------------------------------------------"
sleep 0.5

# Optional GUI tools via snap
SNAPS=(snap-store postman mpv zoom-client rpi-imager notepad-plus-plus)
for s in "${SNAPS[@]}"; do
    if snap list "$s" &>/dev/null; then
        echo -e "\n\e[32m------------------| snap '$s' already installed, skipping |----------------------\e[0m"
    else
        echo -e "\n\e[34m------------------| INSTALLING snap $s |----------------------\e[0m"
        sudo snap install "$s"
    fi
done
# echo -e "\n\e[34m------------------| INSTALLING Pycharm Community $s |----------------------\e[0m"
# sudo snap install pycharm-community --classic
# echo -e "\n\e[32m| Installing From Snap Store DONE |\e[0m\n"


echo "\n---------------------------------------------------------------------------------"
echo "                              Installing GRUB THEME                              "
echo "---------------------------------------------------------------------------------"
sleep 0.5

if [ -d Matrix-grub-theme ]; then
    rm -rf Matrix-grub-theme
fi

git clone https://github.com/yeyushengfan258/Matrix-grub-theme.git
cd Matrix-grub-theme
chmod +x install.sh
# install script will change GRUB theme (needs root)
sudo ./install.sh -t window
cd ..
rm -rf Matrix-grub-theme
echo -e "\n\e[32m| DONE |\e[0m\n"

echo "\n---------------------------------------------------------------------------------"
echo "===============================| TLP |==========================================="
# TLP service management (system-wide)
sudo systemctl start tlp
sudo systemctl enable tlp
sudo systemctl restart tlp
sudo systemctl daemon-reload
sudo systemctl status tlp
tlp-stat -s
echo -e "\n\e[32m| DONE |\e[0m\n"

echo "\n---------------------------------------------------------------------------------"
echo "=========================| PLATFORM TOOLS |======================================="
wget -q https://dl.google.com/android/repository/platform-tools-latest-linux.zip
unzip -o platform-tools-latest-linux.zip
rm -f platform-tools-latest-linux.zip
sudo mv -f platform-tools /opt/
sudo ln -sf /opt/platform-tools/adb /usr/local/bin/adb
sudo ln -sf /opt/platform-tools/fastboot /usr/local/bin/fastboot
echo -e "\n\e[32m| DONE |\e[0m\n"

echo "\n---------------------------------------------------------------------------------"
echo "============================| ARDUINO IDE |======================================="
wget -q https://downloads.arduino.cc/arduino-ide/arduino-ide_2.3.6_Linux_64bit.AppImage
chmod +x arduino-ide_2.3.6_Linux_64bit.AppImage
sudo mv arduino-ide_2.3.6_Linux_64bit.AppImage /opt/
sudo ln -sf /opt/arduino-ide_2.3.6_Linux_64bit.AppImage /usr/local/bin/arduino-ide
echo 'SUBSYSTEMS=="usb", ATTRS{idVendor}=="2341", GROUP="plugdev", MODE="0666"' | sudo tee /etc/udev/rules.d/99-arduino.rules >/dev/null
echo -e "\n\e[32m| DONE |\e[0m\n"

echo "\n---------------------------------------------------------------------------------"
echo "==========================| Black Binary |======================================="
pipx install black
which black || echo "black not in PATH yet (open a new shell or ensure pipx bin dir is in PATH)"
echo -e "\n\e[32m| DONE |\e[0m\n"

echo "\n---------------------------------------------------------------------------------"
echo "=========================| Mongo DB Compass |====================================="
wget https://downloads.mongodb.com/compass/mongodb-compass_1.46.10_amd64.deb
sudo apt install -f -y
sudo dpkg -i mongodb-compass_1.46.10_amd64.deb
sudo apt install -f -y
rm -rf mongodb-compass_1.46.10_amd64.deb
echo -e "\n\e[32m| DONE |\e[0m\n"


echo "\n---------------------------------------------------------------------------------"
echo "                                     DONE                                         "
echo "----------------------------------------------------------------------------------"
echo "You can now:"
echo "  - open a new terminal for nvm/node & black to be on PATH,"
echo "  - or reboot later with: sudo reboot"
echo -ne "\nDo you want to reboot now? (y/yes to reboot): "
read answer

case "$answer" in
    y|Y|yes|YES)
        echo "Rebooting..."
        sudo reboot
        ;;
    *)
        echo "Skipping reboot. You can reboot later with: sudo reboot"
        ;;
esac
