#!/usr/bin/env zsh

# Strict mode for zsh
set -eu
set -o pipefail

# Error handler for zsh
trap 'echo -e "\e[31mError occurred at line $LINENO. Exiting.\e[0m"' ZERR

GIT_USER="dhimanparas20"
GIT_EMAIL="dhimanparas20@gmail.com"

# Path to this script (for dockerAlias.sh, if you still use local one somewhere)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# User's zshrc
ZSHRC_FILE="$HOME/.zshrc"

clear
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                         Installing Dependencies (Fedora)                        \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5

export DNF_YUM_AUTO_YES=1

# Base system update
sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf -y update
#sudo dnf install -y  curl postgresql postgresql-contrib git uidmap snapd python3 python3-pip python3-pipx python3-virtualenv fuse fuse-libs tmateufw bind-utils dnsutils equivalent fastfetch net-tools htop btop NetworkManager tlp tlp-rdw kernel-headers kernel-devel

# Helper: install rpm/dnf package if available
install_pkg_if_available() {
    local pkg="$1"

    # Check if package exists in repos
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

# Debian-style package set mapped to Fedora equivalents where needed
PKGS=(
    curl
    postgresql
    postgresql-contrib
    git
    snapd
    python3
    python3-pip
    pipx
    python3-virtualenv
    tmate
    ufw
    bind-utils       # dnsutils equivalent
    fastfetch
    net-tools
    htop
    btop
    NetworkManager
    tlp
    tlp-rdw
    kernel-headers
    kernel-devel
)

for pkg in "${PKGS[@]}"; do
    install_pkg_if_available "$pkg"
done

echo -e "\n\e[32m| Base Packages DONE |\e[0m\n"

# Ensure pipx bin dir is exported to PATH and available for this session
python3 -m pip install --user pipx >/dev/null 2>&1 || true
python3 -m pipx ensurepath || pipx ensurepath || true

echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                        Enabling snapd (Fedora specifics)                        \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5

# snapd enablement on Fedora: install + enable + classic support symlink 
if ! command -v snap &>/dev/null; then
    sudo dnf install -y snapd
fi

# Enable snapd socket (if not already)
sudo systemctl enable --now snapd.socket || true

# Classic snap support
if [ ! -e /snap ]; then
    sudo ln -s /var/lib/snapd/snap /snap || true
fi

echo -e "\n\e[32m| snapd DONE |\e[0m\n"

echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                            Installing Other Stuff                               \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5

# Lazydocker
curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

# uv
curl -LsSf https://astral.sh/uv/install.sh | bash

# zoxide
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

echo -e "\n\e[32m| Lazydocker + uv + zoxide DONE |\e[0m\n"

echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                         Installing from SNAP Store                              \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5

SNAPS=(ngrok)
for s in "${SNAPS[@]}"; do
    if snap list "$s" &>/dev/null; then
        echo -e "\n\e[32m------------------| snap '$s' already installed, skipping |----------------------\e[0m"
    else
        echo -e "\n\e[34m------------------| INSTALLING snap $s |----------------------\e[0m"
        sudo snap install "$s"
    fi
done

echo -e "\n\e[32m| Snap Apps DONE |\e[0m\n"

echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                                 Adding Git Configs                              \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5

git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_EMAIL"
git config --global credential.helper cache
git config --global credential.helper store

echo -e "\n\e[32m| Git Config DONE |\e[0m\n"

echo -e "\n\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                                 Installing Docker                               \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5
curl -fsSL https://get.docker.com | bash
dockerd-rootless-setuptool.sh install
echo -e "\n\e[32m| DONE |\e[0m\n"


echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                         Cloning oh-my-zsh Extensions                            \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
mkdir -p "$ZSH_CUSTOM"/{plugins,themes}

clone_if_missing() {
    local repo="$1"
    local dest="$2"

    if [ -d "$dest" ]; then
        echo "Already exists, skipping: $dest"
    else
        echo "Cloning $repo -> $dest"
        git clone "$repo" "$dest"
    fi
}

# Plugins
clone_if_missing "https://github.com/zsh-users/zsh-autosuggestions"         "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_if_missing "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone_if_missing "https://github.com/marlonrichert/zsh-autocomplete.git"   "$ZSH_CUSTOM/plugins/zsh-autocomplete"
#clone_if_missing "https://github.com/zsh-users/zsh-completions.git"        "$ZSH_CUSTOM/plugins/zsh-completions"

# Theme
clone_if_missing "https://github.com/romkatv/powerlevel10k.git"            "$ZSH_CUSTOM/themes/powerlevel10k"

echo -e "\n\e[32m| Zsh Plugins DONE |\e[0m\n"

echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                                   Editing .zshrc                                \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5

# Ensure .zshrc exists
if [ ! -f "$ZSHRC_FILE" ]; then
    echo "Creating $ZSHRC_FILE (was missing)"
    touch "$ZSHRC_FILE"
fi

# Replace default plugins=(git) if present
if grep -q '^plugins=(git)' "$ZSHRC_FILE" 2>/dev/null; then
    sed -i 's/^plugins=(git)/plugins=(git sudo history encode64 copypath zsh-autosuggestions zsh-autocomplete command-not-found extract docker colored-man-pages alias-finder zsh-syntax-highlighting)/' "$ZSHRC_FILE"
else
    echo "Default plugins=(git) not found, leaving plugins as-is."
fi

# Replace default theme robbyrussell -> bira if present
if grep -q '^ZSH_THEME="robbyrussell"' "$ZSHRC_FILE" 2>/dev/null; then
    sed -i 's/^ZSH_THEME="robbyrussell"/ZSH_THEME="bira"/' "$ZSHRC_FILE"
else
    echo 'Default ZSH_THEME="robbyrussell" not found, leaving theme as-is.'
fi

echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                                Setting Up Aliases                               \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5

ALIAS_URL="https://raw.githubusercontent.com/dhimanparas20/Instant-Server-Setup/refs/heads/main/dockerAlias.sh"

echo "Fetching docker aliases from: $ALIAS_URL"
if curl -fsSL "$ALIAS_URL" >> "$ZSHRC_FILE"; then
    echo "Appended remote dockerAlias.sh contents to $ZSHRC_FILE"
else
    echo "Failed to fetch dockerAlias.sh from GitHub, skipping alias setup."
fi

echo -e "\n\e[32m| DONE |\e[0m\n"

echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                                     DONE                                        \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo "Open a new terminal or run:  source ~/.zshrc"
fastfetch
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
