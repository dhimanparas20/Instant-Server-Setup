#!/bin/bash
# The script must be run using sudo
# The script also sets up some configurations wherever needed

# Check if the script is run with sudo
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script with sudo:"
    echo "sudo ./run_second.sh"
    exit 1
fi

# Start
clear
echo "---------------------------------------------------------------------------------"
echo "                                    Step 2                                       "
echo "---------------------------------------------------------------------------------"
sleep 1
set -e
rm -f ~/run_first.sh && echo "run_first.sh deleted from home directory"
sleep 0.5

# Install Zsh plugins
clear
echo "---------------------------------------------------------------------------------"
echo "                         Cloning ohmyzsh extentions                              "
echo "---------------------------------------------------------------------------------"
sleep 0.5
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

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

# Reload the .zshrc file to apply the changes immediately
source "$ZSHRC_FILE"

clear
echo "Docker-related commands, aliases, and plugins added successfully to .zshrc."
echo "System Will Reboot"
echo "You can delete This Folder After Reboot."
sleep 5
reboot