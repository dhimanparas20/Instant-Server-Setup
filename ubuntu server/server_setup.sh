#!/usr/bin/env bash
#
# server_setup.sh — Bootstrap a fresh Ubuntu EC2 (or similar) for Docker + app hosting.
# Idempotent: safe to re-run. Tested with Ubuntu 22.04/24.04, zsh 5.9.
#
# Usage:
#   chmod +x server_setup.sh
#   ./server_setup.sh
#
set -euo pipefail

# ─── Configuration (edit these) ───────────────────────────────────────────────
GIT_USER="${GIT_USER:-dhimanparas20}"
GIT_EMAIL="${GIT_EMAIL:-dhimanparas20@gmail.com}"
ZSH_THEME="${ZSH_THEME:-bira}"

# Pinned refs — match known-good WSL setup (prevents zsh autocomplete/autosuggest breakage)
readonly OMZ_REF="6adfef3"
readonly ZSH_AUTOSUGGESTIONS_REF="85919cd"
readonly ZSH_AUTOCOMPLETE_REF="c10880e"
readonly ZSH_SYNTAX_HIGHLIGHTING_REF="1d85c69"
readonly ZSH_COMPLETIONS_REF="684021f"

readonly PLUGINS_LINE='plugins=(git sudo history encode64 copypath zsh-autosuggestions zsh-completions zsh-autocomplete command-not-found extract docker colored-man-pages alias-finder zsh-syntax-highlighting)'

# Toggles
INSTALL_DOCKER="${INSTALL_DOCKER:-true}"
INSTALL_LAZYDOCKER="${INSTALL_LAZYDOCKER:-true}"
INSTALL_ZOXIDE="${INSTALL_ZOXIDE:-true}"
INSTALL_UV="${INSTALL_UV:-true}"          # Python/Django tooling (matches your aliases)
ENABLE_UFW="${ENABLE_UFW:-true}"          # Allows SSH before enabling
CHANGE_SHELL_TO_ZSH="${CHANGE_SHELL_TO_ZSH:-true}"
PROMPT_REBOOT="${PROMPT_REBOOT:-true}"

# UFW: keep SSH open (change port if you use a non-standard SSH port)
SSH_PORT="${SSH_PORT:-22}"

# Paths
ZSHRC_FILE="${HOME}/.zshrc"
ZSH_CUSTOM="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}"
SETUP_DIR="${HOME}/.config/server-setup"
LOG_FILE="${SETUP_DIR}/server_setup.log"
ALIAS_URL="${ALIAS_URL:-https://raw.githubusercontent.com/dhimanparas20/Instant-Server-Setup/refs/heads/main/dockerAlias.sh}"

# ─── Helpers ──────────────────────────────────────────────────────────────────
mkdir -p "${SETUP_DIR}" "${HOME}/apps" "${HOME}/docker" "${HOME}/bin"

exec > >(tee -a "${LOG_FILE}") 2>&1

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

section() {
  echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}  $*${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

ok()   { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${RED}!${NC} $*"; }

require_root_tools() {
  command -v sudo >/dev/null || { echo "sudo is required"; exit 1; }
  command -v curl >/dev/null || { echo "curl is required"; exit 1; }
}

clone_and_pin() {
  local repo="$1" dest="$2" ref="$3"

  if [[ -d "${dest}/.git" ]]; then
    echo "Updating $(basename "${dest}") -> ${ref}"
    git -C "${dest}" fetch origin
  else
    echo "Cloning ${repo}"
    git clone "${repo}" "${dest}"
    git -C "${dest}" fetch origin
  fi

  git -C "${dest}" checkout "${ref}"
  ok "Pinned $(basename "${dest}") at $(git -C "${dest}" rev-parse --short HEAD)"
}

clone_if_missing() {
  local repo="$1" dest="$2"
  if [[ -d "${dest}/.git" ]]; then
    echo "Already exists: ${dest}"
  else
    git clone "${repo}" "${dest}"
    ok "Cloned $(basename "${dest}")"
  fi
}

install_oh_my_zsh() {
  local omz_dir="${HOME}/.oh-my-zsh"

  if [[ -d "${omz_dir}/.git" ]]; then
    ok "Oh My Zsh already installed"
  else
    section "Installing Oh My Zsh"
    export RUNZSH=no
    export CHSH=no
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    ok "Oh My Zsh installed"
  fi

  section "Pinning Oh My Zsh"
  # OMZ installer shallow-clones; fetch full history so pinned commit exists
  git -C "${omz_dir}" fetch --unshallow 2>/dev/null || git -C "${omz_dir}" fetch origin
  git -C "${omz_dir}" checkout "${OMZ_REF}"
  ok "Oh My Zsh pinned at $(git -C "${omz_dir}" rev-parse --short HEAD)"
}

setup_aliases() {
  echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
  echo -e "\e[34m                                Setting Up Aliases                               \e[0m"
  echo -e "\e[34m---------------------------------------------------------------------------------\e[0m"
  sleep 0.5

  echo "Fetching docker aliases from: ${ALIAS_URL}"
  if curl -fsSL "${ALIAS_URL}" >> "${ZSHRC_FILE}"; then
    echo "Appended remote dockerAlias.sh contents to ${ZSHRC_FILE}"
  else
    echo "Failed to fetch dockerAlias.sh from GitHub, skipping alias setup."
  fi

  echo -e "\n\e[32m| DONE |\e[0m\n"
}

configure_zshrc() {
  section "Configuring ~/.zshrc"

  [[ -f "${ZSHRC_FILE}" ]] || touch "${ZSHRC_FILE}"

  # Remove broken patterns from older runs
  sed -i \
    -e '/^source.*zsh-autocomplete/d' \
    -e '/^source.*zsh-autosuggestions/d' \
    -e '/^source.*zsh-syntax-highlighting/d' \
    -e '/^autoload -Uz compinit && compinit/d' \
    -e '/^# zsh-autocomplete/d' \
    "${ZSHRC_FILE}" 2>/dev/null || true

  rm -f "${HOME}/.zshenv"

  if grep -q '^plugins=(git)' "${ZSHRC_FILE}" 2>/dev/null; then
    sed -i "s/^plugins=(git)/${PLUGINS_LINE}/" "${ZSHRC_FILE}"
  elif grep -q '^plugins=(' "${ZSHRC_FILE}" 2>/dev/null; then
    sed -i "/^plugins=(/c\\${PLUGINS_LINE}" "${ZSHRC_FILE}"
  else
    printf '\n%s\n' "${PLUGINS_LINE}" >> "${ZSHRC_FILE}"
  fi

  if grep -q '^ZSH_THEME="robbyrussell"' "${ZSHRC_FILE}" 2>/dev/null; then
    sed -i "s/^ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"${ZSH_THEME}\"/" "${ZSHRC_FILE}"
  fi

  ok "~/.zshrc configured"
}

configure_git() {
  section "Git configuration"
  git config --global user.name "${GIT_USER}"
  git config --global user.email "${GIT_EMAIL}"
  git config --global init.defaultBranch main
  git config --global credential.helper store
  git config --global pull.rebase false
  ok "Git user: ${GIT_USER} <${GIT_EMAIL}>"
}

setup_system_packages() {
  section "System packages"
  export DEBIAN_FRONTEND=noninteractive

  sudo apt-get update -qq
  sudo apt-get install -yq \
    software-properties-common \
    git curl wget ca-certificates gnupg \
    zsh \
    uidmap \
    tmate \
    ufw \
    dnsutils \
    net-tools \
    htop \
    unzip \
    jq \
    python3 \
    python3-pip \
    python3-venv \
    "linux-headers-$(uname -r)" 2>/dev/null || true

  sudo add-apt-repository -y universe 2>/dev/null || true
  sudo apt-get upgrade -yq
  sudo apt-get autoremove -yq

  ok "System packages installed"
}

setup_docker() {
  [[ "${INSTALL_DOCKER}" == "true" ]] || { warn "Skipping Docker (INSTALL_DOCKER=false)"; return 0; }

  section "Docker Engine + Compose plugin"

  if command -v docker >/dev/null 2>&1; then
    ok "Docker already installed: $(docker --version)"
  else
    curl -fsSL https://get.docker.com | sh
    ok "Docker installed"
  fi

  sudo usermod -aG docker "${USER}" || true
  sudo systemctl enable docker
  sudo systemctl start docker

  # Docker CLI plugin: rollout (zero-downtime compose updates)
  sudo mkdir -p /usr/local/lib/docker/cli-plugins
  sudo curl -fsSL \
    https://raw.githubusercontent.com/wowu/docker-rollout/main/docker-rollout \
    -o /usr/local/lib/docker/cli-plugins/docker-rollout
  sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-rollout

  # Shared network for app stacks (ignore if exists)
  docker network create app-net 2>/dev/null || true

  ok "Docker ready (log out/in or run: newgrp docker)"
  ok "Compose: $(docker compose version 2>/dev/null || echo 'available after re-login')"
}

setup_cli_tools() {
  if [[ "${INSTALL_LAZYDOCKER}" == "true" ]]; then
    section "Lazydocker"
    curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
    ok "Lazydocker installed"
  fi

  if [[ "${INSTALL_ZOXIDE}" == "true" ]]; then
    section "Zoxide"
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    ok "Zoxide installed"
  fi

  if [[ "${INSTALL_UV}" == "true" ]]; then
    section "uv (Python package manager)"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    ok "uv installed (~/.local/bin/uv)"
  fi
}

setup_zsh_plugins() {
  section "Zsh plugins (pinned versions)"
  mkdir -p "${ZSH_CUSTOM}/plugins" "${ZSH_CUSTOM}/themes"

  clone_and_pin "https://github.com/zsh-users/zsh-autosuggestions"        "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"        "${ZSH_AUTOSUGGESTIONS_REF}"
  clone_and_pin "https://github.com/zsh-users/zsh-syntax-highlighting.git" "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"  "${ZSH_SYNTAX_HIGHLIGHTING_REF}"
  clone_and_pin "https://github.com/marlonrichert/zsh-autocomplete.git"   "${ZSH_CUSTOM}/plugins/zsh-autocomplete"         "${ZSH_AUTOCOMPLETE_REF}"
  clone_and_pin "https://github.com/zsh-users/zsh-completions.git"        "${ZSH_CUSTOM}/plugins/zsh-completions"          "${ZSH_COMPLETIONS_REF}"
  clone_if_missing "https://github.com/romkatv/powerlevel10k.git"          "${ZSH_CUSTOM}/themes/powerlevel10k"
}

setup_ufw() {
  [[ "${ENABLE_UFW}" == "true" ]] || { warn "Skipping UFW (ENABLE_UFW=false)"; return 0; }

  section "Firewall (UFW)"
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow "${SSH_PORT}/tcp" comment 'SSH'
  # Uncomment to expose HTTP/HTTPS on the host (usually reverse-proxy in Docker instead):
  # sudo ufw allow 80/tcp comment 'HTTP'
  # sudo ufw allow 443/tcp comment 'HTTPS'
  echo "y" | sudo ufw enable
  sudo ufw status verbose
  ok "UFW enabled (SSH port ${SSH_PORT} allowed)"
}

set_default_shell_zsh() {
  [[ "${CHANGE_SHELL_TO_ZSH}" == "true" ]] || return 0

  if [[ "${SHELL:-}" != *zsh* ]]; then
    if command -v zsh >/dev/null; then
      chsh -s "$(command -v zsh)" "${USER}" || warn "Could not chsh — run: chsh -s \$(which zsh)"
      ok "Default shell set to zsh (open a new session)"
    fi
  else
    ok "Default shell already zsh"
  fi
}

print_summary() {
  section "Setup complete"
  cat << EOF
Log file:     ${LOG_FILE}
App dir:      ${HOME}/apps      ← put compose projects here
Docker dir:   ${HOME}/docker
Aliases:      ${ALIAS_URL}

Next steps:
  1. Open a new SSH session (or run: exec zsh)
  2. Verify Docker:  docker run --rm hello-world
  3. Verify zsh:     type ls → ghost suggestion should appear
  4. Deploy an app:  cd ~/apps && git clone <your-repo> && docker compose up -d

Optional env vars for next run:
  INSTALL_DOCKER=false ENABLE_UFW=false ./server_setup.sh

Pinned plugin refs: OMZ=${OMZ_REF} autosuggest=${ZSH_AUTOSUGGESTIONS_REF} autocomplete=${ZSH_AUTOCOMPLETE_REF}
EOF
}

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
  clear
  section "Server setup started — $(date -Is)"
  require_root_tools

  setup_system_packages
  install_oh_my_zsh
  setup_docker
  setup_cli_tools
  setup_zsh_plugins
  configure_zshrc
  setup_aliases
  configure_git
  setup_ufw
  set_default_shell_zsh
  print_summary

  if [[ "${PROMPT_REBOOT}" == "true" ]]; then
    echo -ne "\nReboot now? (y/N): "
    read -r answer || answer="n"
    case "${answer}" in
      y|Y|yes|YES) sudo reboot ;;
      *) ok "Skipping reboot. Run 'exec zsh' or reconnect SSH." ;;
    esac
  fi
}

main "$@"
