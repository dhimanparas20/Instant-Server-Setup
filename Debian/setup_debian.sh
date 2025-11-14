#!/usr/bin/env zsh

# Strict mode for zsh
set -eu
set -o pipefail

# Error handler for zsh
trap 'echo -e "\e[31mError occurred at line $LINENO. Exiting.\e[0m"' ZERR

GIT_USER="dhimanparas20"
GIT_EMAIL="dhimanparas20@gmail.com"

# Path to this script (for dockerAlias.sh)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# User's zshrc
ZSHRC_FILE="$HOME/.zshrc"

clear
echo -e "\n\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                         Installing Dependencies (Debian)                        \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m\n"
sleep 0.5

export DEBIAN_FRONTEND=noninteractive

# System-wide operations need sudo
sudo apt update -q

# Some useful base tools (also pulls in software-properties-common on Debian if needed)
sudo apt install -yq ca-certificates curl gnupg lsb-release

# NOTE: No "universe" on Debian, so we skip add-apt-repository here.
sudo apt upgrade -yq
sudo apt install -yq curl postgresql postgresql-contrib git uidmap snapd python3 python3-pip pipx python3-venv tmate libfuse3-dev fuse3 ufw dnsutils neofetch net-tools htop btop network-manager tlp tlp-rdw "linux-headers-$(uname -r)"

# PKGS=(
#     curl postgresql postgresql-contrib git uidmap snapd python3 python3-pip pipx python3-venv
#     fuse tmate libfuse2 ufw dnsutils fastfetch net-tools htop btop network-manager tlp tlp-rdw
#     "linux-headers-$(uname -r)"
# )

# install_pkg_if_available() {
#     local pkg="$1"

#     # Check if package name exists in the Debian repos
#     if ! apt-cache show "$pkg" &>/dev/null; then
#         echo -e "\n\e[33m------------------| Package '$pkg' not found on Debian, skipping |----------------------\e[0m"
#         return 0
#     fi

#     if dpkg -s "$pkg" &>/dev/null; then
#         echo -e "\n\e[32m------------------| $pkg already installed, skipping |----------------------\e[0m"
#     else
#         echo -e "\n\e[34m------------------| INSTALLING $pkg |----------------------\e[0m"
#         sudo apt install -yq "$pkg"
#     fi
# }

# for pkg in "${PKGS[@]}"; do
#     install_pkg_if_available "$pkg"
# done

# Per-user
pipx ensurepath
echo -e "\n\e[32m| DONE |\e[0m\n"

echo -e "\n\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                            Installing Other Stuff                               \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5

# These remote installers expect bash / POSIX, and may sudo internally
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
curl -LsSf https://astral.sh/uv/install.sh | bash
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
echo -e "\n\e[32m| DONE |\e[0m\n"


echo -e "\n\e[34m---------------------------------------------------------------------------------\e[0m"
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
echo -e "\n\e[32m| DONE |\e[0m\n"


echo -e "\n\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                                 Installing Docker                               \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5
curl -fsSL https://get.docker.com | bash
dockerd-rootless-setuptool.sh install
echo -e "\n\e[32m| DONE |\e[0m\n"


echo -e "\n\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                                 Adding Git Configs                              \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5

# Per-user git config (no sudo)
git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_EMAIL"
git config --global credential.helper cache
git config --global credential.helper store
echo -e "\n\e[32m| DONE |\e[0m\n"


echo -e "\n\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                         Cloning oh-my-zsh Extensions                            \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5

# oh-my-zsh custom dir
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
clone_if_missing "https://github.com/zsh-users/zsh-autosuggestions"        "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_if_missing "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone_if_missing "https://github.com/marlonrichert/zsh-autocomplete.git"   "$ZSH_CUSTOM/plugins/zsh-autocomplete"
clone_if_missing "https://github.com/zsh-users/zsh-completions.git"        "$ZSH_CUSTOM/plugins/zsh-completions"

# Theme
clone_if_missing "https://github.com/romkatv/powerlevel10k.git"            "$ZSH_CUSTOM/themes/powerlevel10k"
echo -e "\n\e[32m| DONE |\e[0m\n"


echo -e "\n\e[34m---------------------------------------------------------------------------------\e[0m"
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
    sed -i 's/^plugins=(git)/plugins=(git sudo history encode64 copypath zsh-autosuggestions zsh-completions zsh-autocomplete command-not-found extract docker colored-man-pages alias-finder zsh-syntax-highlighting)/' "$ZSHRC_FILE"
else
    echo "Default plugins=(git) not found, leaving plugins as-is."
fi

# Replace default theme robbyrussell -> bira if present
if grep -q '^ZSH_THEME="robbyrussell"' "$ZSHRC_FILE" 2>/dev/null; then
    sed -i 's/^ZSH_THEME="robbyrussell"/ZSH_THEME="bira"/' "$ZSHRC_FILE"
else
    echo 'Default ZSH_THEME="robbyrussell" not found, leaving theme as-is.'
fi
echo -e "\n\e[32m| DONE |\e[0m\n"

echo -e "\n\e[34m---------------------------------------------------------------------------------\e[0m"
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


echo -e "\n\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                                     DONE                                        \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo "Open a new terminal or run:  source ~/.zshrc"
neofetch

# Reboot prompt
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
