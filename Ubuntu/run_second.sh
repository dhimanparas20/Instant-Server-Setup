#!/bin/zsh
# The script also sets up some configurations wherever needed

# Start
clear
echo "---------------------------------------------------------------------------------"
echo "                                    Step 2                                       "
echo "---------------------------------------------------------------------------------"
sleep 0.5
set -e


echo "---------------------------------------------------------------------------------"
echo "                                Docker Root less                                 "
echo "---------------------------------------------------------------------------------"
sleep 0.5
dockerd-rootless-setuptool.sh install 

# Install Zsh plugins
echo "---------------------------------------------------------------------------------"
echo "                         Cloning ohmyzsh extentions                              "
echo "---------------------------------------------------------------------------------"
sleep 0.5
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autocomplete
git clone https://github.com/zsh-users/zsh-completions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions
sudo git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

# Define the file path for .zshrc
ZSHRC_FILE="$HOME/.zshrc"

echo "---------------------------------------------------------------------------------"
echo "                                   Editing .zshrc                                "
echo "---------------------------------------------------------------------------------"
sleep 0.5

# Replace the line that starts with 'plugins=' to add new plugins
sed -i 's/^plugins=(git)/plugins=(git sudo history encode64 copypath zsh-autosuggestions zsh-completions zsh-autocompletecommand-not-found extract docker colored-man-pages alias-finder zsh-syntax-highlighting)/' "$ZSHRC_FILE"

# Replace the line that starts with 'ZSH_THEME="roborussel"' with 'ZSH_THEME="bira"'
sed -i 's/^ZSH_THEME="robbyrussell"/ZSH_THEME="bira"/' "$ZSHRC_FILE"

# Adding Docker Alias
if [[ -f dockerAlias.sh ]]; then
    cat dockerAlias.sh >> "$HOME/.zshrc"
    rm -f dockerAlias.sh
fi

# Reload the .zshrc file to apply the changes immediately
source "$ZSHRC_FILE"

echo "---------------------------------------------------------------------------------"
echo "Docker-related commands, aliases, and plugins added successfully to .zshrc."
echo "Please manually reboot the system once, using 'sudo reboot' "
echo "You can delete This file After Reboot."
echo "---------------------------------------------------------------------------------"
sleep 5
reboot
