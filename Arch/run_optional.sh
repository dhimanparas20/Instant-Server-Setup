#!/usr/bin/env zsh

# Strict mode for zsh
set -eu
set -o pipefail

# Error handler for zsh
trap 'echo -e "\e[31mError occurred at line $LINENO. Exiting.\e[0m"' ZERR

clear
echo "---------------------------------------------------------------------------------"
echo "                     Installing Optional Dependencies (Arch)                     "
echo "---------------------------------------------------------------------------------"
sleep 0.5

export PACMAN="sudo pacman --noconfirm"

install_pkg_if_available() {
    local pkg="$1"

    if pacman -Qi "$pkg" &>/dev/null; then
        echo -e "\n\e[32m------------------| $pkg already installed, skipping |----------------------\e[0m"
        return 0
    fi

    if pacman -Si "$pkg" &>/dev/null; then
        echo -e "\n\e[34m------------------| INSTALLING $pkg |----------------------\e[0m"
        sudo pacman -S --noconfirm "$pkg"
    else
        echo -e "\n\e[33m------------------| Package '$pkg' not found in Arch repos, skipping |----------------------\e[0m"
    fi
}

PKGS=(
    nvtop
    grub-customizer   # may be AUR; will be skipped if not in official repos
    gparted
    unzip
)

for pkg in "${PKGS[@]}"; do
    install_pkg_if_available "$pkg"
done

echo -e "\n\e[32m| Base Optional Packages DONE |\e[0m\n"

echo "---------------------------------------------------------------------------------"
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

echo "---------------------------------------------------------------------------------"
echo "                         Installing from SNAP Store                              "
echo "---------------------------------------------------------------------------------"
sleep 0.5

# Ensure snapd installed & configured (in case base script wasn't run)
if ! command -v snap &>/dev/null; then
    install_pkg_if_available snapd
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

# Pycharm Community via snap
if snap list pycharm-community &>/dev/null; then
    echo -e "\n\e[32m------------------| snap 'pycharm-community' already installed, skipping |----------------------\e[0m"
else
    echo -e "\n\e[34m------------------| INSTALLING snap pycharm-community |----------------------\e[0m"
    sudo snap install pycharm-community --classic
fi

echo -e "\n\e[32m| Installing From Snap Store DONE |\e[0m\n"

echo "---------------------------------------------------------------------------------"
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

echo "---------------------------------------------------------------------------------"
echo "===============================| TLP |==========================================="
sleep 0.5

install_pkg_if_available tlp
install_pkg_if_available tlp-rdw

sudo systemctl start tlp || true
sudo systemctl enable tlp || true
sudo systemctl enable tlp-sleep || true
sudo systemctl restart tlp || true
sudo systemctl status tlp || true
tlp-stat -s || true
echo -e "\n\e[32m| TLP DONE |\e[0m\n"

echo "---------------------------------------------------------------------------------"
echo "=========================| PLATFORM TOOLS |======================================="
sleep 0.5

wget -q https://dl.google.com/android/repository/platform-tools-latest-linux.zip
unzip -o platform-tools-latest-linux.zip
rm -f platform-tools-latest-linux.zip
sudo mv -f platform-tools /opt/
sudo ln -sf /opt/platform-tools/adb /usr/local/bin/adb
sudo ln -sf /opt/platform-tools/fastboot /usr/local/bin/fastboot
echo -e "\n\e[32m| Android Platform Tools DONE |\e[0m\n"

echo "---------------------------------------------------------------------------------"
echo "============================| ARDUINO IDE |======================================"
sleep 0.5

wget -q https://downloads.arduino.cc/arduino-ide/arduino-ide_2.3.6_Linux_64bit.AppImage
chmod +x arduino-ide_2.3.6_Linux_64bit.AppImage
sudo mv arduino-ide_2.3.6_Linux_64bit.AppImage /opt/
sudo ln -sf /opt/arduino-ide_2.3.6_Linux_64bit.AppImage /usr/local/bin/arduino-ide
echo 'SUBSYSTEMS=="usb", ATTRS{idVendor}=="2341", GROUP="plugdev", MODE="0666"' | sudo tee /etc/udev/rules.d/99-arduino.rules >/dev/null
echo -e "\n\e[32m| Arduino IDE DONE |\e[0m\n"

echo "---------------------------------------------------------------------------------"
echo "==========================| Black Binary |======================================="
sleep 0.5

# pipx from system (python-pipx)
if command -v pipx &>/dev/null; then
    pipx install black
else
    echo "pipx not found, installing black with pip --user as fallback"
    python -m pip install --user black || true
fi

which black || echo "black not in PATH yet (open a new shell or ensure local bin dir is in PATH)"
echo -e "\n\e[32m| Black DONE |\e[0m\n"

echo "---------------------------------------------------------------------------------"
echo "=========================| MongoDB Compass |====================================="
sleep 0.5

echo "MongoDB Compass is not installed automatically on Arch in this script."
echo "You can grab the latest Linux build (AppImage or tar) from the official site:"
echo "  https://www.mongodb.com/try/download/compass"
echo -e "\n\e[33m[NOTE]\e[0m Install it manually if you need the GUI."
echo -e "\n\e[32m| MongoDB Compass step SKIPPED (manual) |\e[0m\n"

echo "---------------------------------------------------------------------------------"
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
