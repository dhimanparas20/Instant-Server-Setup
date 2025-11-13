#!/bin/bash
# The script must be run using sudo
# The script also sets up some configurations wherever needed

# Check if the script is run with sudo
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script with sudo:"
    echo "sudo ./run_optional.sh"
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
apt install -yq nvtop grub-customizer gparted

# Install Other Stuff
echo "---------------------------------------------------------------------------------"
echo "                            Installing Other Stuff                               "
echo "---------------------------------------------------------------------------------"
sleep 0.5
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash                          # nvm
nvm install node

# Install LazyDocker
echo "---------------------------------------------------------------------------------"
echo "                         Installing from SNAP Store                              "
echo "---------------------------------------------------------------------------------"
sleep 0.5
snap install snap-store postman mpv zoom-client rpi-imager PyCharm-community notepad-plus-plus
# snap install docker



# Store git passwords and add user signature
echo "---------------------------------------------------------------------------------"
echo "                                 Adding Git Configs                              "
echo "---------------------------------------------------------------------------------"
sleep 0.5
git config --global user.name "dhimanparas20"
git config --global user.email "dhimanparas20@gmail.com"
git config --global credential.helper cache
git config --global credential.helper store\]


echo "---------------------------------------------------------------------------------"
echo "                              Installing GRUB THEME                              "
echo "---------------------------------------------------------------------------------"
sleep 0.5
git clone https://github.com/yeyushengfan258/Matrix-grub-theme.git
cd Matrix-grub-theme
chmod +x install.sh
./install.sh -t window
cd ..
rm -rf Matrix-grub-theme

echo "---------------------------------------------------------------------------------"
echo "                          Starting of installed Packages                         "
echo "---------------------------------------------------------------------------------"
sleep 0.5
echo "===============================| TLP |============================================"
# nano /etc/tlp.conf
systemctl start tlp
systemctl enable tlp
systemctl enable tlp-sleep
systemctl restart tlp
status tlp
tlp-stat -s

echo "=========================| PLATFORM TOOLS |========================================"
wget https://dl.google.com/android/repository/platform-tools-latest-linux.zip
unzip -o platform-tools-latest-linux.zip
mv -f platform-tools /opt/
ln -sf /opt/platform-tools/adb /usr/local/bin/adb
ln -sf /opt/platform-tools/fastboot /usr/local/bin/fastboot

echo "=========================| ARDUINO IDE |========================================"
wget https://downloads.arduino.cc/arduino-ide/arduino-ide_2.3.6_Linux_64bit.AppImage
chmod +x arduino-ide_2.3.6_Linux_64bit.AppImage
mv arduino-ide_2.3.6_Linux_64bit.AppImage /opt/
ln -sf /opt/arduino-ide_2.3.6_Linux_64bit.AppImage /usr/local/bin/arduino-ide
echo 'SUBSYSTEMS=="usb", ATTRS{idVendor}=="2341", GROUP="plugdev", MODE="0666"' | sudo tee /etc/udev/rules.d/99-arduino.rules

echo "=========================| Black Binary |========================================"
pipx install black
which black
