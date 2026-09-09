# Instant Server Setup

Tools and scripts to bootstrap Ubuntu servers with **zsh**, **Oh My Zsh**, **Docker**, and dev aliases.

**Repository:** https://github.com/dhimanparas20/Instant-Server-Setup.git

## Quick start

See **[ubuntu server/UBUNTU-SERVER-SETUP.md](ubuntu%20server/UBUNTU-SERVER-SETUP.md)** for full steps.

```bash
git clone https://github.com/dhimanparas20/Instant-Server-Setup.git
cd "Instant-Server-Setup/ubuntu server"
chmod +x server_setup.sh && ./server_setup.sh
exec zsh
```

## Layout

```text
Instant-Server-Setup/
├── dockerAlias.sh
├── README.md
└── ubuntu server/
    ├── UBUNTU-SERVER-SETUP.md    ← setup guide
    ├── server_setup.sh           ← run on new servers
    └── setup-zsh.sh              ← zsh-only (optional)
```

## Download script without cloning

```bash
curl -fsSL -o server_setup.sh \
  "https://raw.githubusercontent.com/dhimanparas20/Instant-Server-Setup/refs/heads/main/ubuntu%20server/server_setup.sh"
chmod +x server_setup.sh && ./server_setup.sh
```
