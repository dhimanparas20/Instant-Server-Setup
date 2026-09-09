# Instant Server Setup

Bootstrap Ubuntu servers with **zsh**, **Oh My Zsh**, **Docker**, and dev aliases.

**Repository:** https://github.com/dhimanparas20/Instant-Server-Setup.git

## New server (one command block)

```bash
sudo apt update && sudo apt install -y git curl
git clone https://github.com/dhimanparas20/Instant-Server-Setup.git
cd "Instant-Server-Setup/ubuntu server"
chmod +x server_setup.sh && ./server_setup.sh
exec zsh
```

Full guide: **[ubuntu server/UBUNTU-SERVER-SETUP.md](ubuntu%20server/UBUNTU-SERVER-SETUP.md)**

## Layout

```text
Instant-Server-Setup/
├── dockerAlias.sh                 ← aliases (auto-fetched by server_setup.sh)
├── README.md
└── ubuntu server/
    ├── UBUNTU-SERVER-SETUP.md     ← detailed setup guide
    ├── server_setup.sh            ← run on every new server
    └── setup-zsh.sh               ← optional (skip if you ran server_setup.sh)
```

## Scripts

| File | Use |
|------|-----|
| `server_setup.sh` | **Fresh servers** — installs everything |
| `setup-zsh.sh` | **Optional** — zsh/plugins only; do not run if you already ran `server_setup.sh` |

## Download without cloning

```bash
curl -fsSL -o server_setup.sh \
  "https://raw.githubusercontent.com/dhimanparas20/Instant-Server-Setup/refs/heads/main/ubuntu%20server/server_setup.sh"
chmod +x server_setup.sh && ./server_setup.sh && exec zsh
```
