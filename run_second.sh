#!/bin/zsh
# The script also sets up some configurations wherever needed

# Start
clear
echo "---------------------------------------------------------------------------------"
echo "                                    Step 2                                       "
echo "---------------------------------------------------------------------------------"
sleep 0.5
set -e
rm -rf run_first.sh && echo "run_first.sh deleted from home directory"

# Install Zsh plugins
clear
echo "---------------------------------------------------------------------------------"
echo "                         Cloning ohmyzsh extentions                              "
echo "---------------------------------------------------------------------------------"
sleep 0.5
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
sudo git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

# Define the file path for .zshrc
ZSHRC_FILE="$HOME/.zshrc"

clear
echo "---------------------------------------------------------------------------------"
echo "                                   Editing .zshrc                                "
echo "---------------------------------------------------------------------------------"
sleep 0.5

# Replace the line that starts with 'plugins=' to add new plugins
sed -i 's/^plugins=(git)/plugins=(git sudo history encode64 copypath zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC_FILE"

# Replace the line that starts with 'ZSH_THEME="roborussel"' with 'ZSH_THEME="bira"'
sed -i 's/^ZSH_THEME="robbyrussell"/ZSH_THEME="bira"/' "$ZSHRC_FILE"

# Adding Docker Alias
cat dockerAlias.sh >> ~/.zshrc
rm -rf dockerAlias.sh

# Reload the .zshrc file to apply the changes immediately
source "$ZSHRC_FILE"

clear
echo "Docker-related commands, aliases, and plugins added successfully to .zshrc."
echo "Please manually reboot the system once, using 'sudo reboot' "
echo "You can delete This file After Reboot."
