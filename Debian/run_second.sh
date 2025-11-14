#!/usr/bin/env zsh
set -euo pipefail

# Define ZSH_CUSTOM if not already set
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

clear
echo "---------------------------------------------------------------------------------"
echo "                                    Step 2                                       "
echo "---------------------------------------------------------------------------------"
sleep 0.5

# Install Zsh plugins if not already present
echo "---------------------------------------------------------------------------------"
echo "                         Cloning ohmyzsh extensions                              "
echo "---------------------------------------------------------------------------------"
sleep 0.5

[[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] || \
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] || \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
[[ -d "$ZSH_CUSTOM/plugins/zsh-autocomplete" ]] || \
    git clone https://github.com/marlonrichert/zsh-autocomplete.git "$ZSH_CUSTOM/plugins/zsh-autocomplete"
[[ -d "$ZSH_CUSTOM/plugins/zsh-completions" ]] || \
    git clone https://github.com/zsh-users/zsh-completions.git "$ZSH_CUSTOM/plugins/zsh-completions"
[[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]] || \
    git clone https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"

ZSHRC_FILE="$HOME/.zshrc"

echo "---------------------------------------------------------------------------------"
echo "                                   Editing .zshrc                                "
echo "---------------------------------------------------------------------------------"
sleep 0.5

sed -i 's/^plugins=(git)/plugins=(git sudo history encode64 copypath zsh-autosuggestions zsh-completions zsh-autocompletecommand-not-found extract docker colored-man-pages alias-finder zsh-syntax-highlighting)/' "$ZSHRC_FILE"
sed -i 's/^ZSH_THEME="robbyrussell"/ZSH_THEME="bira"/' "$ZSHRC_FILE"

if [[ -f dockerAlias.sh ]]; then
    cat dockerAlias.sh >> "$HOME/.zshrc"
    rm -f dockerAlias.sh
fi

source "$ZSHRC_FILE"

echo "---------------------------------------------------------------------------------"
echo "Docker-related commands, aliases, and plugins added successfully to .zshrc."
echo "Please manually reboot the system once, using 'sudo reboot'."
echo "You can delete this file after reboot."
echo "---------------------------------------------------------------------------------"
sleep 5
