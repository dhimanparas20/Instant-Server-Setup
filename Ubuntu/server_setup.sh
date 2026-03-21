#!/usr/bin/env zsh

# Strict mode for zsh
set -eu
set -o pipefail

# Error handler for zsh
trap 'echo -e "\e[31mError occurred at line $LINENO. Exiting.\e[0m"' ZERR

clear
echo -e "\n\e[32m-------------------------------------------------------------------------------------------\e[0m\n"
echo -e "\e[32m                                 | WELCOME TO THE SCRIPT |                                  \e[0m"
echo -e "\n\e[32m-------------------------------------------------------------------------------------------\e[0m\n\n"
sleep 1.5

GIT_USER="dhimanparas20"
GIT_EMAIL="dhimanparas20@gmail.com"


# Path to this script (for dockerAlias.sh)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# User's zshrc
ZSHRC_FILE="$HOME/.zshrc"


echo -e "\n\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                            Installing Dependencies                              \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5

export DEBIAN_FRONTEND=noninteractive

# System-wide operations need sudo
sudo apt update -q

# Ensure add-apt-repository exists
sudo apt install -yq software-properties-common

sudo add-apt-repository -y universe
sudo apt upgrade -yq
sudo apt install -yq curl uidmap tmate ufw dnsutils neofetch net-tools htop network-manager "linux-headers-$(uname -r)"
sudo apt autoremove -y
#git config --global credential.helper libsecret

echo -e "\n\e[32m| Installing Dependencies DONE |\e[0m\n"


echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                            Installing Other Stuff                               \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5

# These remote installers expect bash / POSIX, and may sudo internally
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
echo -e "\n\e[32m| Installing LAZYDOCKER Done |\e[0m\n"

curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
echo -e "\n\e[32m| Installing ZOXIDE Done |\e[0m\n"


echo -e "\n\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                                 Installing Docker                               \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5
curl -fsSL https://get.docker.com | bash
dockerd-rootless-setuptool.sh install
sudo usermod -aG docker $USER
#newgrp docker
echo -e "\n\e[32m| DONE |\e[0m\n"

echo -e "\n\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                                 Installing Docker Rollout                        \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
# Create directory for Docker cli plugins
sudo mkdir -p /usr/local/lib/docker/cli-plugins/
# Download docker-rollout script to Docker cli plugins directory
sudo curl https://raw.githubusercontent.com/wowu/docker-rollout/main/docker-rollout -o /usr/local/lib/docker/cli-plugins/docker-rollout
# Make the script executable
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-rollout


echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
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
echo -e "\e[34m                                 Adding Git Configs                              \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5

# Per-user git config (no sudo)
echo -e "\e[34mSetting up Git COnfigs for $GIT_USER \e[0m"
git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_EMAIL"
git config --global credential.helper cache
git config --global credential.helper store
echo -e "\n\e[32m| DONE |\e[0m\n"


echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                                     END                                         \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo "Open a new terminal or run:  source ~/.zshrc"
echo "If you changed low-level stuff (kernel, headers, etc.), you can reboot later: sudo reboot"
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
