# **Instant Server Setup**

A fully automated, multi-distribution server setup toolkit designed to configure your system with essential tools, developer utilities, Docker rootless mode, Zsh, Oh-My-Zsh, plugins, themes, aliases, and optional desktop utilities — all in minutes.

This project supports:

* **Ubuntu**
* **Debian**
* **Fedora**

Each distro has **two scripts**, and Ubuntu/Debian have a dedicated third server setup script:

| Script               | Purpose                                                  |
| -------------------- | -------------------------------------------------------- |
| `setup_<distro>.sh`  | Main installation & system configuration                 |
| `run_optional.sh`    | Optional heavy tools, GUI apps, utilities, theming, etc. |
| `server_setup.sh`    | (Ubuntu/Debian) Server-focused setup bundle              |

And one universal top-level launcher:

```
run.sh
```

The launcher detects/asks your distro, installs Oh-My-Zsh for main scripts, and executes the correct script using Zsh.

---

## **📁 Repository Structure**

```
Instant-Server-Setup/
│
├── Ubuntu/
│   ├── setup_ubuntu.sh
│   ├── run_optional.sh
│   └── server_setup.sh
│
├── Debian/
│   ├── setup_debian.sh
│   ├── run_optional.sh
│   └── server_setup.sh
│
├── Fedora/
│   ├── setup_fedora.sh
│   └── run_optional.sh
│
├── dockerAlias.sh              # Shared docker aliases (automatically appended)
├── run.sh                      # Main launcher script
└── README.md
```

---

## **🚀 What This Toolkit Does**

Every distro's *main script* performs:

* System update + dependencies
* Docker rootless mode setup
* Zsh + Oh-My-Zsh plugins
* Powerlevel10k theme
* Git configuration
* Py tools (pipx, uv, zoxide, lazydocker, etc.)
* Hardware tools (tlp, power mgmt, fuse, htop, etc.)
* Snap / DNF / Pacman equivalents
* Sets up aliases from `dockerAlias.sh`
* One-command post-install ready-to-use system

The *optional script* installs:

* NVM + Node
* Snap apps (Postman, PyCharm, MPV, Zoom, Notepad++ …)
* GRUB theming
* Android platform tools
* Arduino IDE + udev rules
* Black formatter
* MongoDB Compass
* And more high-level optional tools

---

# **⚡ Quick Start: Easiest Method**

## Prerequirement
- zsh and Oh my Zsh must be there
- NOTE: All the scripts must be run after you are using Oh My ZSH

```bash
sudo apt update
sudo apt install git zsh -y && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

## **Method 1 — Run using curl/wget (recommended)**

```bash
wget -q https://raw.githubusercontent.com/dhimanparas20/Instant-Server-Setup/refs/heads/main/run.sh
chmod +x run.sh && ./run.sh
```

---

## **Method 2 — Manual Clone**

```bash
git clone https://github.com/dhimanparas20/Instant-Server-Setup.git
cd Instant-Server-Setup
chmod +x run.sh && ./run.sh
```

Same workflow: distro selection → script selection → execution.

---

# **💡 How The Launcher Works (run.sh)**

The launcher will:

1. Detect if you're already inside the repository
2. Otherwise clone the repo
3. Ask which distro you're on
4. Ask whether you want:

   * **1 – Main Script**
   * **2 – Optional Script**
   * **3 – Server Setup (Ubuntu/Debian only)**
5. If “Main” is chosen:

   * Runs

     ```bash
     sudo apt install zsh -y && \
     sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
     ```

     (Auto-adjusted for Debian/Ubuntu only)
6. Runs the chosen script using **Zsh**

This yields a clean, consistent experience across all distros.

---

# **🛡 Requirements**

* A supported Linux distribution:

  * Ubuntu ≥ 20.04
  * Debian ≥ 11
  * Fedora ≥ 38
* Internet connection
* Ability to use `sudo`
* Fresh system recommended but not required

---

# **⚠ Important Notes**

### ✔ Scripts are safe & idempotent

They skip already-installed packages and skip git clones if directories exist.

### ✔ Rootless Docker setup

Main scripts configure rootless Docker automatically.

### ✔ Zsh is enforced

All scripts are executed **using Zsh**, not Bash.

### ✔ Snap support

Fedora scripts add snap support where needed.

---

# **📦 Included Tools / Highlights**

* **Docker Rootless**
* **Oh-My-Zsh** + plugins
* **Powerlevel10k theme**
* **Pipx, uv, zoxide, lazydocker**
* **HTOP, Btop, Neofetch, TLP, FUSE**
* **Git global config**
* **Node + NVM (optional script)**
* **Platform Tools, Arduino IDE**
* **MongoDB Compass**
* **Snap-based apps (optional)**

---

# **🤝 Contributing**

PRs are welcome!
If you want to add another distro or improve script modularity, feel free to open a pull request.

---

# **📜 License**

MIT License — use freely for personal or production systems.
