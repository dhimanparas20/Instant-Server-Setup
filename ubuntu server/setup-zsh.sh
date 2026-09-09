#!/usr/bin/env zsh
#
# OPTIONAL — use server_setup.sh on fresh Ubuntu servers instead.
# This script re-applies zsh plugins + aliases only.
# Requires: Oh My Zsh already installed (will NOT install OMZ or Docker from scratch).
#
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

# Pinned refs tested on WSL (zsh 5.9 + oh-my-zsh). Avoids autocomplete/autosuggest breakage
# from newer plugin commits on fresh EC2/Ubuntu installs.
readonly OMZ_REF="6adfef3"
readonly ZSH_AUTOSUGGESTIONS_REF="85919cd"
readonly ZSH_AUTOCOMPLETE_REF="c10880e"
readonly ZSH_SYNTAX_HIGHLIGHTING_REF="1d85c69"
readonly ZSH_COMPLETIONS_REF="684021f"

readonly PLUGINS_LINE='plugins=(git sudo history encode64 copypath zsh-autosuggestions zsh-completions zsh-autocomplete command-not-found extract docker colored-man-pages alias-finder zsh-syntax-highlighting)'

# Path to this script (for dockerAlias.sh)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# User's zshrc
ZSHRC_FILE="$HOME/.zshrc"

echo -e "\n\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                            Installing Dependencies                              \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5

export DEBIAN_FRONTEND=noninteractive

sudo apt update -q
sudo apt install -yq software-properties-common
sudo add-apt-repository -y universe
sudo apt upgrade -yq
sudo apt install -yq curl uidmap tmate ufw dnsutils net-tools htop network-manager unzip xdg-utils "linux-headers-$(uname -r)"
sudo apt autoremove -y
git config --global credential.helper libsecret

echo -e "\n\e[32m| Installing Dependencies DONE |\e[0m\n"

echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                            Installing Other Stuff                               \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5

curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
echo -e "\n\e[32m| Installing LAZYDOCKER Done |\e[0m\n"

curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
echo -e "\n\e[32m| Installing ZOXIDE Done |\e[0m\n"

echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                                 Installing Docker                               \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5

curl -fsSL https://get.docker.com | bash
dockerd-rootless-setuptool.sh install
sudo usermod -aG docker "$USER"
echo -e "\n\e[32m| DONE |\e[0m\n"

echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                                 Installing Docker Rollout                        \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"

sudo mkdir -p /usr/local/lib/docker/cli-plugins/
sudo curl https://raw.githubusercontent.com/wowu/docker-rollout/main/docker-rollout -o /usr/local/lib/docker/cli-plugins/docker-rollout
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-rollout

echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                         Cloning oh-my-zsh Extensions                            \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
mkdir -p "$ZSH_CUSTOM"/{plugins,themes}

# Full clone (no --depth 1) so pinned commits are always reachable.
clone_and_pin() {
    local repo="$1"
    local dest="$2"
    local ref="$3"

    if [ -d "$dest/.git" ]; then
        echo "Updating $dest -> $ref"
        git -C "$dest" fetch origin
    else
        echo "Cloning $repo -> $dest"
        git clone "$repo" "$dest"
        git -C "$dest" fetch origin
    fi

    git -C "$dest" checkout "$ref"
    echo "Pinned $(basename "$dest") at $(git -C "$dest" rev-parse --short HEAD)"
}

pin_oh_my_zsh() {
    local omz_dir="$HOME/.oh-my-zsh"

    if [ ! -d "$omz_dir/.git" ]; then
        echo "Oh My Zsh not found at $omz_dir — install it first, then re-run this section."
        return 1
    fi

    echo "Pinning Oh My Zsh -> $OMZ_REF"
    git -C "$omz_dir" fetch --unshallow 2>/dev/null || git -C "$omz_dir" fetch origin
    git -C "$omz_dir" checkout "$OMZ_REF"
    echo "Pinned oh-my-zsh at $(git -C "$omz_dir" rev-parse --short HEAD)"
}

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

clone_and_pin "https://github.com/zsh-users/zsh-autosuggestions"         "$ZSH_CUSTOM/plugins/zsh-autosuggestions"         "$ZSH_AUTOSUGGESTIONS_REF"
clone_and_pin "https://github.com/zsh-users/zsh-syntax-highlighting.git"  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"   "$ZSH_SYNTAX_HIGHLIGHTING_REF"
clone_and_pin "https://github.com/marlonrichert/zsh-autocomplete.git"    "$ZSH_CUSTOM/plugins/zsh-autocomplete"          "$ZSH_AUTOCOMPLETE_REF"
clone_and_pin "https://github.com/zsh-users/zsh-completions.git"         "$ZSH_CUSTOM/plugins/zsh-completions"           "$ZSH_COMPLETIONS_REF"

clone_if_missing "https://github.com/romkatv/powerlevel10k.git"           "$ZSH_CUSTOM/themes/powerlevel10k"

pin_oh_my_zsh || true

echo -e "\n\e[32m| DONE |\e[0m\n"

echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                                   Editing .zshrc                                \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
sleep 0.5

if [ ! -f "$ZSHRC_FILE" ]; then
    echo "Creating $ZSHRC_FILE (was missing)"
    touch "$ZSHRC_FILE"
fi

# Remove broken manual plugin loading / compinit hacks from previous runs.
sed -i \
    -e '/^source.*zsh-autocomplete/d' \
    -e '/^source.*zsh-autosuggestions/d' \
    -e '/^source.*zsh-syntax-highlighting/d' \
    -e '/^autoload -Uz compinit && compinit/d' \
    -e '/^# zsh-autocomplete/d' \
    "$ZSHRC_FILE"

rm -f "$HOME/.zshenv"

if grep -q '^plugins=(git)' "$ZSHRC_FILE" 2>/dev/null; then
    sed -i "s/^plugins=(git)/${PLUGINS_LINE}/" "$ZSHRC_FILE"
elif grep -q '^plugins=(' "$ZSHRC_FILE" 2>/dev/null; then
    sed -i "/^plugins=(/c\\${PLUGINS_LINE}" "$ZSHRC_FILE"
else
    echo "No plugins=(...) line found; appending default plugins line."
    printf '\n%s\n' "$PLUGINS_LINE" >> "$ZSHRC_FILE"
fi

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

echo -e "\e[34mSetting up Git configs for $GIT_USER \e[0m"
git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_EMAIL"
git config --global credential.helper cache
git config --global credential.helper store

echo -e "\n\e[32m| DONE |\e[0m\n"

echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo -e "\e[34m                                     END                                         \e[0m"
echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
echo "Open a new terminal or run:  exec zsh"
echo "If you changed low-level stuff (kernel, headers, etc.), you can reboot later: sudo reboot"
echo -ne "\nDo you want to reboot now? (y/yes to reboot): "
read -r answer

case "$answer" in
    y|Y|yes|YES)
        echo "Rebooting..."
        sudo reboot
        ;;
    *)
        echo "Skipping reboot. You can reboot later with: sudo reboot"
        ;;
esac
