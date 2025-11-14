# Instant Server Setup

## Overview

**Instant Server Setup** is a universal, automated solution for quickly configuring a fresh Linux server (Ubuntu, Debian, Fedora, or Arch) with all essential developer tools, Docker, Oh My Zsh, productivity aliases, and optional GUI utilities.  
It is designed for developers, sysadmins, and power users who want a ready-to-use environment in minutes, not hours.

---

## What Does This Script Do?

- **Automates the installation** of all core packages, developer tools, and system utilities.
- **Configures Docker** and Docker Compose for containerized development.
- **Sets up Oh My Zsh** with powerful plugins and themes for a modern shell experience.
- **Adds a suite of useful aliases** (including advanced Docker and Git shortcuts).
- **Optionally installs GUI tools** (editors, Postman, Zoom, etc.) for desktop environments.
- **Works on Ubuntu, Debian, Fedora, and Arch Linux**—just specify your distro and setup stage.

---

## Why Use This Script?

- **Saves hours** of manual setup and configuration.
- **Ensures consistency** across multiple machines or team members.
- **Reduces errors** by automating repetitive tasks.
- **Easy to extend** or customize for your own workflow.

---

## What Gets Installed?

Depending on your distro and the setup stage, the script installs:

- **Core developer tools:** `git`, `curl`, `python3`, `pipx`, `tmate`, `ufw`, `htop`, `btop`, `network tools`, `unzip`, `wget`, etc.
- **Docker & Docker Compose:** For containerized development.
- **Oh My Zsh:** With plugins like autosuggestions, syntax highlighting, completions, and the Powerlevel10k theme.
- **Aliases:** For Docker, Git, SSH, and more (see [`dockerAlias.sh`](./Ubuntu/dockerAlias.sh) for details).
- **Optional GUI tools:** Postman, Zoom, Snap Store, PyCharm Community, Notepad++, MPV, RPi Imager, GParted, Grub Customizer, and more.
- **System enhancements:** TLP for power management, fastfetch, zoxide, uv, and more.

---

## Folder Structure

```
Instant-Server-Setup/
├── Arch/
│   ├── run_first.sh
│   ├── run_optional.sh
│   └── run_second.sh
├── Debian/
│   ├── run_first.sh
│   ├── run_optional.sh
│   └── run_second.sh
├── Fedora/
│   ├── run_first.sh
│   ├── run_optional.sh
│   └── run_second.sh
├── Ubuntu/
│   ├── run_first.sh
│   ├── run_optional.sh
│   └── run_second.sh
├── dockerAlias.sh
├── run_super.sh
└── README.md
```

---

## How To Use

### **Step 1: Clone the Repository**

```sh
git clone https://github.com/dhimanparas20/Instant-Server-Setup.git
cd Instant-Server-Setup
```

### **Step 2: Make the Master Script Executable**

```sh
chmod +x run_super.sh
```

### **Step 3: Run the Setup Script**

You must specify **both** your distro and the setup stage:

- `-d` for distro: `Ubuntu`, `Debian`, `Fedora`, or `Arch`
- `-v` for variant: `first`, `second`, or `opt`

### **Step After First Script Gets Executed**
Once the server reboots, reconnect the server:
Then, install Oh My Zsh using the following command:

```sh
sudo apt install zsh -y && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

#### **Examples:**

**Initial setup for Ubuntu:**
```sh
sudo ./run_super.sh -d Ubuntu -v first
```

**Install Oh My Zsh plugins and aliases for Fedora:**
```sh
sudo ./run_super.sh -d Fedora -v second
```

**Install optional GUI tools for Arch:**
```sh
sudo ./run_super.sh -d Arch -v opt
```

**You must run each stage in order for a complete setup.**

---

## **What Each Stage Does**

### **Stage 1: `first`**
- Updates your system and installs all core developer tools and dependencies.
- Installs Docker and configures your user for Docker access.
- Sets up basic system utilities and security tools.
- Prepares your system for further configuration.
- **Reboots the system at the end.**

### **Stage 2: `second`**
- Installs Oh My Zsh (if not already installed).
- Adds powerful Zsh plugins and the Powerlevel10k theme.
- Appends a comprehensive set of Docker, Git, and productivity aliases to your `.zshrc`.
- Finalizes your shell environment for productivity.

### **Stage 3: `opt`**
- Installs optional GUI and desktop tools (Postman, Snap Store, PyCharm, Zoom, GParted, etc.).
- Installs additional developer utilities and power management tools.
- Sets up Android platform tools and Arduino IDE.
- Applies extra system tweaks and enhancements.

---

## **Requirements & Notes**

- **Run as root or with sudo** for all stages to ensure all packages and configurations are applied.
- **Internet connection** is required for downloading packages and scripts.
- **Reboot** after each stage if prompted.
- **Oh My Zsh** will prompt you for configuration on first launch—follow the on-screen instructions.
- **Aliases** are appended to your `.zshrc` and will be available in new terminal sessions.

---

## **Customization**

- You can edit the scripts in each distro folder to add or remove packages as needed.
- The `dockerAlias.sh` file contains all the custom aliases and can be extended for your workflow.

---

## **Troubleshooting**

- If you encounter errors, check the output for missing dependencies or permission issues.
- Ensure you are running the script with the correct parameters and as root/sudo.
- For issues with Docker permissions, log out and log back in after installation.

---

## **License**

This project is open-source.  
yFeel free to modify and distribute it as per your requirements.