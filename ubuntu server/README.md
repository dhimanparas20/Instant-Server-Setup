# Instant Server Setup

Bootstrap **raw Ubuntu EC2** → **zsh + Oh My Zsh + Docker + dev aliases**.

**Repository:** https://github.com/dhimanparas20/Instant-Server-Setup.git

**Full guide:** [ubuntu server/UBUNTU-SERVER-SETUP.md](ubuntu%20server/UBUNTU-SERVER-SETUP.md)

---

## New server — copy/paste

```bash
sudo apt update && sudo apt install -y git curl
git clone https://github.com/dhimanparas20/Instant-Server-Setup.git
cd "Instant-Server-Setup/ubuntu server"
chmod +x server_setup.sh && ./server_setup.sh
exec zsh
sudo usermod -s $(which zsh) ubuntu
```

Disconnect SSH and log back in — zsh + theme every time (no more `exec zsh`).

---

## Layout

```text
Instant-Server-Setup/
├── dockerAlias.sh
├── README.md
└── ubuntu server/
    ├── UBUNTU-SERVER-SETUP.md     ← full docs (options, hacks, troubleshooting)
    ├── server_setup.sh            ← run on every new server
    └── setup-zsh.sh               ← optional (skip if you ran server_setup.sh)
```

---

## Scripts

| Script | Use |
|------|-----|
| `server_setup.sh` | **Every new server** — full install |
| `setup-zsh.sh` | Zsh/plugins only — **skip** if you ran `server_setup.sh` |

---

## Permanent zsh (EC2)

`chsh` fails (password/PAM). Use this instead:

```bash
sudo usermod -s $(which zsh) ubuntu
```

Then reconnect SSH.

---

## AWS firewall

UFW is **off** by default. Open ports in **EC2 Security Group** (SSH 22, HTTP 80, HTTPS 443, etc.).

---

## Download without clone

```bash
curl -fsSL -o server_setup.sh \
  "https://raw.githubusercontent.com/dhimanparas20/Instant-Server-Setup/refs/heads/main/ubuntu%20server/server_setup.sh"
chmod +x server_setup.sh && ./server_setup.sh
```
