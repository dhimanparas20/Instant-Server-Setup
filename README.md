# Instant Server Setup

## Overview
This repository contains scripts to quickly set up a newly installed Ubuntu server with all required dependencies, Docker, aliases, and Oh My Zsh.

## Installation Steps
Follow these steps to set up your server using this repository.

### Step 1: Initial Setup
Run the following command to download and execute the first setup script:

```sh
wget https://raw.githubusercontent.com/dhimanparas20/Instant-Server-Setup/main/run_first.sh && chmod +x run_first.sh && sudo ./run_first.sh
```

This script will:
- Install necessary dependencies
- Update and upgrade the system
- Clone the full repository
- Reboot the system

### Step 2: Oh My Zsh Installation
Once the server reboots, reconnect and navigate to the cloned directory:

```sh
cd Instant-Server-Setup
```

Then, install Oh My Zsh using the following command:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### Step 3: Final Setup
Run the second setup script to configure Oh My Zsh extensions, set up aliases, and finalize the system:

```sh
sudo ./run_second.sh
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
- The scripts should be executed with `sudo` to ensure all packages and configurations are correctly applied.

## License
This project is open-source. Feel free to modify and distribute it as per your requirements.

