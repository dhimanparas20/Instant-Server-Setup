# Instant Server Setup

## Overview
This repository contains scripts to quickly set up a newly installed Ubuntu server with all required dependencies, Docker, aliases, and Oh My Zsh.

## Installation Steps
Follow these steps to set up your server using this repository.

### Step 1: Initial Setup
Run the following command to download and execute the first setup script:

```sh
wget -qO- https://raw.githubusercontent.com/dhimanparas20/Instant-Server-Setup/refs/heads/main/run_first.sh | sudo bash
```

This script will:
- Install necessary dependencies
- Update and upgrade the system
- Clone the full repository
- Reboot the system

### Step 2: Oh My Zsh Installation
Once the server reboots, reconnect the server:

Then, install Oh My Zsh using the following command:

```sh
sudo apt install zsh -y && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### Step 3: Final Setup
Run the second setup script to configure Oh My Zsh extensions, set up aliases, and finalize the system:

```sh
wget -q https://raw.githubusercontent.com/dhimanparas20/Instant-Server-Setup/main/dockerAlias.sh
wget -qO- https://raw.githubusercontent.com/dhimanparas20/Instant-Server-Setup/refs/heads/main/run_second.sh | sudo bash
sudo reboot
```

### Step 4: Optional for GUI tools
Run this script to install some more Gui based Tools

```sh
wget -qO- https://raw.githubusercontent.com/dhimanparas20/Instant-Server-Setup/refs/heads/main/run_optional.sh | sudo bash
```

### Combined Step 3-4 in a Single Code Block
```sh
wget -q https://raw.githubusercontent.com/dhimanparas20/Instant-Server-Setup/main/dockerAlias.sh
wget -qO- https://raw.githubusercontent.com/dhimanparas20/Instant-Server-Setup/refs/heads/main/run_second.sh | sudo bash
wget -qO- https://raw.githubusercontent.com/dhimanparas20/Instant-Server-Setup/refs/heads/main/run_optional.sh | sudo bash
rm -rf dockerAlias.sh
sudo reboot
```

This script will:
- Configure Oh My Zsh
- Install necessary plugins and extensions
- Set up useful aliases
- Reboot the system

## Usage
After the final reboot, your server will be fully set up with all dependencies and configurations.

## Notes
- Ensure you have `wget` installed before running the initial command.
- The 1st script script should be executed with `sudo` to ensure all packages and configurations are correctly applied.

## License
This project is open-source. Feel free to modify and distribute it as per your requirements.
