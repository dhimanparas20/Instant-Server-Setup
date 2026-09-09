# Instant Server Setup

One-shot bootstrap for fresh **Ubuntu EC2** (or similar) — Docker-ready, zsh + plugins, dev aliases, basic firewall.

## Quick start

On a new server:

```bash
curl -fsSL -o server_setup.sh https://raw.githubusercontent.com/dhimanparas20/Instant-Server-Setup/main/server_setup.sh
chmod +x server_setup.sh
./server_setup.sh
```

Or clone this repo and run `./server_setup.sh`.

## What it installs

| Category | Tools |
|----------|--------|
| **Shell** | zsh, Oh My Zsh (pinned), autosuggest + autocomplete + syntax-highlighting |
| **Docker** | Engine, Compose plugin, rollout CLI plugin, `app-net` network |
| **CLI** | lazydocker, zoxide, uv (Python) |
| **System** | git, jq, htop, ufw, python3 venv, build headers |
| **Layout** | `~/apps`, `~/docker`, `~/.config/server-setup/` |

## Configuration

Edit the top of `server_setup.sh` or pass env vars:

```bash
GIT_USER="you" GIT_EMAIL="you@example.com" ./server_setup.sh

# Skip parts
INSTALL_DOCKER=false ENABLE_UFW=false ./server_setup.sh
```

| Variable | Default | Description |
|----------|---------|-------------|
| `GIT_USER` / `GIT_EMAIL` | dhimanparas20 | Git identity |
| `INSTALL_DOCKER` | true | Docker Engine + compose |
| `INSTALL_UV` | true | Python uv (Django aliases) |
| `ENABLE_UFW` | true | Firewall (SSH allowed first) |
| `SSH_PORT` | 22 | UFW SSH port |
| `CHANGE_SHELL_TO_ZSH` | true | chsh to zsh |
| `PROMPT_REBOOT` | true | Ask to reboot at end |

## Pinned zsh refs (known-good)

| Component | Ref |
|-----------|-----|
| Oh My Zsh | `6adfef3` |
| zsh-autosuggestions | `85919cd` |
| zsh-autocomplete | `c10880e` |
| zsh-syntax-highlighting | `1d85c69` |
| zsh-completions | `684021f` |

Plugins load **only** via Oh My Zsh `plugins=(...)` — no manual `source`, no extra `compinit`.

## After setup

```bash
exec zsh
docker run --rm hello-world
cd ~/apps && docker compose up -d
```

Log file: `~/.config/server-setup/server_setup.log`

## Improvements over the old script

- **Single bash script** — runs on fresh servers before zsh is default
- **Installs Oh My Zsh** — no manual pre-step
- **Pinned plugin versions** — full git clones, no `--depth 1` surprises
- **Remote aliases** — appends `dockerAlias.sh` from your GitHub repo to `~/.zshrc`
- **Smarter docker** — no rootless + sudo conflict; uses docker group with sudo fallback
- **UFW safe defaults** — SSH allowed before enable
- **Idempotent** — safe to re-run
- **App directories** — `~/apps` for compose projects

## Files

| File | Purpose |
|------|---------|
| `server_setup.sh` | Full server bootstrap (use this) |
| `setup-zsh.sh` | Zsh-only subset (legacy) |
