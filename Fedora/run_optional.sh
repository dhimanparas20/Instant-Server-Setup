#!/usr/bin/env zsh

# Strict mode for zsh
set -eu
set -o pipefail

# Error handler for zsh
trap 'echo -e "\e[31mError occurred at line $LINENO. Exiting.\e[0m"' ZERR

clear
echo "\n---------------------------------------------------------------------------------"
echo "                     Installing Optional Dependencies (Fedora)                   "
echo "---------------------------------------------------------------------------------"
sleep 0.5

export DNF_YUM_AUTO_YES=1

install_pkg_if_available() {
    local pkg="$1"

    if ! sudo dnf list --available "$pkg" &>/dev/null && ! rpm -q "$pkg" &>/dev/null; then
        echo -e "\n\e[33m------------------| Package '$pkg' not found on Fedora, skipping |----------------------\e[0m"
        return 0
    fi

    if rpm -q "$pkg" &>/dev/null; then
        echo -e "\n\e[32m------------------| $pkg already installed, skipping |----------------------\e[0m"
    else
        echo -e "\n\e[34m------------------| INSTALLING $pkg |----------------------\e[0m"
        sudo dnf install -y "$pkg"
    fi
}

PKGS=(
    nvtop
    grub-customizer
    gparted
    unzip
    fuse
    fuse-libs
)

for pkg in "${PKGS[@]}"; do
    install_pkg_if_available "$pkg"
done
echo -e "\n\e[32m| Base Optional Packages DONE |\e[0m\n"

echo "\n---------------------------------------------------------------------------------"
echo "                            Installing Other Stuff                               "
echo "---------------------------------------------------------------------------------"
sleep 0.5

# NVM + Node (per-user)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# Load nvm into this script session so `nvm install` works
if [ -s "$HOME/.nvm/nvm.sh" ]; then
    source "$HOME/.nvm/nvm.sh"
elif [ -s "/usr/share/nvm/init-nvm.sh" ]; then
    source "/usr/share/nvm/init-nvm.sh"
fi

nvm install node
echo -e "\n\e[32m| NVM + Node DONE |\e[0m\n"


echo "\n---------------------------------------------------------------------------------"
echo "                         Installing from SNAP Store                              "
echo "---------------------------------------------------------------------------------"
sleep 0.5

# Ensure snapd installed & configured (in case base script wasn't run)
if ! command -v snap &>/dev/null; then
    sudo dnf install -y snapd
    sudo systemctl enable --now snapd.socket || true
    [ -e /snap ] || sudo ln -s /var/lib/snapd/snap /snap || true
fi

SNAPS=(snap-store postman mpv zoom-client rpi-imager notepad-plus-plus)
for s in "${SNAPS[@]}"; do
    if snap list "$s" &>/dev/null; then
        echo -e "\n\e[32m------------------| snap '$s' already installed, skipping |----------------------\e[0m"
    else
        echo -e "\n\e[34m------------------| INSTALLING snap $s |----------------------\e[0m"
        sudo snap install "$s"
    fi
done

# Pycharm Community generally needs --classic, keep same behavior
if snap list pycharm-community &>/dev/null; then
    echo -e "\n\e[32m------------------| snap 'pycharm-community' already installed, skipping |----------------------\e[0m"
else
    echo -e "\n\e[34m------------------| INSTALLING snap pycharm-community |----------------------\e[0m"
    sudo snap install pycharm-community --classic
fi

echo -e "\n\e[32m| Installing From Snap Store DONE |\e[0m\n"


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
sudo ./install.sh -t window
cd ..
rm -rf Matrix-grub-theme
echo -e "\n\e[32m| GRUB Theme DONE |\e[0m\n"


echo "\n---------------------------------------------------------------------------------"
echo "===============================| TLP |==========================================="
sleep 0.5

# TLP is available in Fedora repos 
install_pkg_if_available tlp
install_pkg_if_available tlp-rdw

sudo systemctl start tlp || true
sudo systemctl enable tlp || true
sudo systemctl enable tlp-sleep || true
sudo systemctl restart tlp || true
sudo systemctl status tlp || true
tlp-stat -s || true
echo -e "\n\e[32m| TLP DONE |\e[0m\n"


echo "\n---------------------------------------------------------------------------------"
echo "=========================| PLATFORM TOOLS |======================================="
sleep 0.5

wget -q https://dl.google.com/android/repository/platform-tools-latest-linux.zip
unzip -o platform-tools-latest-linux.zip
rm -f platform-tools-latest-linux.zip
sudo mv -f platform-tools /opt/
sudo ln -sf /opt/platform-tools/adb /usr/local/bin/adb
sudo ln -sf /opt/platform-tools/fastboot /usr/local/bin/fastboot
echo -e "\n\e[32m| Android Platform Tools DONE |\e[0m\n"


echo "\n---------------------------------------------------------------------------------"
echo "============================| ARDUINO IDE |======================================"
sleep 0.5

wget -q https://downloads.arduino.cc/arduino-ide/arduino-ide_2.3.6_Linux_64bit.AppImage
chmod +x arduino-ide_2.3.6_Linux_64bit.AppImage
sudo mv arduino-ide_2.3.6_Linux_64bit.AppImage /opt/
sudo ln -sf /opt/arduino-ide_2.3.6_Linux_64bit.AppImage /usr/local/bin/arduino-ide
echo 'SUBSYSTEMS=="usb", ATTRS{idVendor}=="2341", GROUP="plugdev", MODE="0666"' | sudo tee /etc/udev/rules.d/99-arduino.rules >/dev/null
echo -e "\n\e[32m| Arduino IDE DONE |\e[0m\n"


echo "\n---------------------------------------------------------------------------------"
echo "==========================| Black Binary |======================================="
sleep 0.5

pipx install black
which black || echo "black not in PATH yet (open a new shell or ensure pipx bin dir is in PATH)"
echo -e "\n\e[32m| Black DONE |\e[0m\n"


echo "\n---------------------------------------------------------------------------------"
echo "=========================| MongoDB Compass |====================================="
sleep 0.5

# Use RPM package variant for RHEL/Fedora-like systems 
COMPASS_RPM="mongodb-compass-1.46.10.x86_64.rpm"
COMPASS_URL="https://downloads.mongodb.com/compass/${COMPASS_RPM}"

wget -q "$COMPASS_URL" -O "$COMPASS_RPM"
sudo dnf install -y "./$COMPASS_RPM" || sudo rpm -Uvh "./$COMPASS_RPM" || true
rm -f "$COMPASS_RPM"

echo -e "\n\e[32m| MongoDB Compass DONE (or best-effort) |\e[0m\n"


echo "\n---------------------------------------------------------------------------------"
echo "                                     DONE                                        "
echo "---------------------------------------------------------------------------------"
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
