#!/usr/bin/env bash
#
# setup_debian.sh — Debian development-system bootstrap (Bash, not Zsh).
#
# Targets: Debian 12 "bookworm" and Debian 13 "trixie" with systemd.
# Run as the intended login user, NOT as root.
#
# Usage:
#   chmod +x setup_debian.sh
#   ./setup_debian.sh
#
# Examples:
#   INSTALL_POSTGRES=false INSTALL_SNAPS=false ./setup_debian.sh
#   DOCKER_MODE=rootless ./setup_debian.sh
#
set -Eeuo pipefail
umask 022

# ─── Configuration ───────────────────────────────────────────────────────────

GIT_USER="${GIT_USER:-dhimanparas20}"
GIT_EMAIL="${GIT_EMAIL:-dhimanparas20@gmail.com}"
ZSH_THEME="${ZSH_THEME:-bira}"

INSTALL_DOCKER="${INSTALL_DOCKER:-true}"
DOCKER_MODE="${DOCKER_MODE:-rootful}"
INSTALL_ROLLOUT="${INSTALL_ROLLOUT:-true}"
INSTALL_LAZYDOCKER="${INSTALL_LAZYDOCKER:-true}"
INSTALL_ZOXIDE="${INSTALL_ZOXIDE:-true}"
INSTALL_UV="${INSTALL_UV:-true}"
INSTALL_POSTGRES="${INSTALL_POSTGRES:-true}"
INSTALL_SNAPS="${INSTALL_SNAPS:-true}"
INSTALL_FASTFETCH="${INSTALL_FASTFETCH:-true}"

# Laptop-specific: leave disabled on cloud servers.
INSTALL_NETWORK_MANAGER="${INSTALL_NETWORK_MANAGER:-false}"
INSTALL_TLP="${INSTALL_TLP:-false}"

UPGRADE_SYSTEM="${UPGRADE_SYSTEM:-false}"
ENABLE_UFW="${ENABLE_UFW:-false}"
ALLOW_WEB_PORTS="${ALLOW_WEB_PORTS:-false}"
SSH_PORT="${SSH_PORT:-22}"
CHANGE_SHELL_TO_ZSH="${CHANGE_SHELL_TO_ZSH:-false}"
PROMPT_REBOOT="${PROMPT_REBOOT:-false}"

# Pin Zsh plugins to refs inherited from your earlier scripts.
# For stronger reproducibility, replace these with full commit SHAs.
readonly OMZ_REF="6adfef3"
readonly AUTOSUGGESTIONS_REF="85919cd"
readonly AUTOCOMPLETE_REF="c10880e"
readonly SYNTAX_HIGHLIGHTING_REF="1d85c69"
readonly COMPLETIONS_REF="684021f"

ALIAS_URL="${ALIAS_URL:-https://raw.githubusercontent.com/dhimanparas20/Instant-Server-Setup/refs/heads/main/dockerAlias.sh}"
ROLLOUT_URL="${ROLLOUT_URL:-https://raw.githubusercontent.com/wowu/docker-rollout/main/docker-rollout}"

readonly SETUP_DIR="${HOME}/.config/debian-setup"
readonly LOG_FILE="${SETUP_DIR}/setup.log"
readonly ZSHRC_FILE="${HOME}/.zshrc"
readonly ZSH_DIR="${HOME}/.oh-my-zsh"
readonly ZSH_CUSTOM="${ZSH_DIR}/custom"
readonly ZSH_CONFIG="${SETUP_DIR}/shell.zsh"
readonly ALIAS_FILE="${SETUP_DIR}/aliases.zsh"
readonly CURRENT_USER="$(id -un)"

WORK_DIR=""
DISTRO_ID=""
DISTRO_VERSION=""
DISTRO_CODENAME=""
DOCKER_ARCH=""

# ─── Helpers ─────────────────────────────────────────────────────────────────

section() {
  printf '\n━━ %s ━━\n\n' "$*"
}

ok() {
  printf '✓ %s\n' "$*"
}

warn() {
  printf '! %s\n' "$*" >&2
}

die() {
  warn "$*"
  exit 1
}

cleanup() {
  if [[ -n "${WORK_DIR}" && -d "${WORK_DIR}" ]]; then
    rm -rf -- "${WORK_DIR}"
  fi
}

on_error() {
  local status="$1"
  local line="$2"

  warn "Setup failed at line ${line}, exit status ${status}."
  warn "Review ${LOG_FILE}; fix the issue, then rerun."
  exit "${status}"
}

trap cleanup EXIT
trap 'on_error "$?" "$LINENO"' ERR

download() {
  local url="$1"
  local destination="$2"

  curl \
    --fail \
    --show-error \
    --silent \
    --location \
    --retry 3 \
    --connect-timeout 15 \
    --max-time 300 \
    --proto '=https' \
    --proto-redir '=https' \
    "${url}" \
    --output "${destination}"
}

apt_install() {
  sudo env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends "$@"
}

backup_file() {
  local file="$1"

  if [[ -e "${file}" ]]; then
    cp -p -- "${file}" \
      "${file}.backup.$(date +%Y%m%dT%H%M%S).$$"
  fi
}

run_installer() {
  local name="$1"
  local url="$2"
  local interpreter="$3"
  local installer="${WORK_DIR}/${name}-installer"

  download "${url}" "${installer}"
  "${interpreter}" "${installer}"
}

# ─── Preflight ───────────────────────────────────────────────────────────────

preflight() {
  [[ "${EUID}" -ne 0 ]] ||
    die "Run as your normal login user with sudo access, not root."

  [[ -r /etc/os-release ]] || die "Cannot identify the OS."

  # shellcheck disable=SC1091
  source /etc/os-release

  DISTRO_ID="${ID:-}"
  DISTRO_VERSION="${VERSION_ID:-}"
  DISTRO_CODENAME="${VERSION_CODENAME:-}"

  case "${DISTRO_ID}:${DISTRO_VERSION}" in
    debian:12)
      [[ "${DISTRO_CODENAME}" == "bookworm" ]] ||
        die "Unexpected codename for Debian 12."
      ;;
    debian:13)
      [[ "${DISTRO_CODENAME}" == "trixie" ]] ||
        die "Unexpected codename for Debian 13."
      ;;
    *)
      die "This script targets Debian 12 (bookworm) or Debian 13 (trixie)."
      ;;
  esac

  [[ -d /run/systemd/system ]] ||
    die "A running systemd instance is required."

  command -v sudo >/dev/null || die "sudo is required."
  command -v flock >/dev/null || die "flock is required."

  local name
  for name in \
    INSTALL_DOCKER INSTALL_ROLLOUT INSTALL_LAZYDOCKER \
    INSTALL_ZOXIDE INSTALL_UV INSTALL_POSTGRES INSTALL_SNAPS \
    INSTALL_FASTFETCH INSTALL_NETWORK_MANAGER INSTALL_TLP \
    UPGRADE_SYSTEM ENABLE_UFW ALLOW_WEB_PORTS \
    CHANGE_SHELL_TO_ZSH PROMPT_REBOOT
  do
    case "${!name}" in
      true|false) ;;
      *) die "${name} must be true or false." ;;
    esac
  done

  case "${DOCKER_MODE}" in
    rootful|rootless) ;;
    *) die "DOCKER_MODE must be rootful or rootless." ;;
  esac

  [[ "${SSH_PORT}" =~ ^[0-9]{1,5}$ ]] ||
    die "SSH_PORT must be a numeric TCP port."

  (( 10#${SSH_PORT} >= 1 && 10#${SSH_PORT} <= 65535 )) ||
    die "SSH_PORT must be between 1 and 65535."

  [[ "${ZSH_THEME}" =~ ^[a-zA-Z0-9_/-]+$ ]] ||
    die "Invalid ZSH_THEME."

  [[ "${ZSH_THEME}" != "powerlevel10k/powerlevel10k" ]] ||
    die "Install and configure Powerlevel10k separately first."

  DOCKER_ARCH="$(dpkg --print-architecture)"

  if [[ "${INSTALL_DOCKER}" == "true" ]]; then
    case "${DOCKER_ARCH}" in
      amd64|arm64) ;;
      *)
        die "This script validates Docker setup only for amd64 / arm64."
        ;;
    esac
  fi

  sudo -v

  mkdir -p "${SETUP_DIR}"
  chmod 700 "${SETUP_DIR}"

  exec 9>"${SETUP_DIR}/setup.lock"
  flock -n 9 || die "Another setup process is already running."

  touch "${LOG_FILE}"
  chmod 600 "${LOG_FILE}"
  exec > >(tee -a "${LOG_FILE}") 2>&1

  WORK_DIR="$(mktemp -d)"
  export PATH="${HOME}/.local/bin:${HOME}/bin:${PATH}"

  section "Debian setup started — $(date -Is)"
  printf 'Distribution: %s %s (%s)\n' \
    "${DISTRO_ID}" "${DISTRO_VERSION}" "${DISTRO_CODENAME}"
  printf 'Architecture: %s\n' "${DOCKER_ARCH}"
}

# ─── System packages ─────────────────────────────────────────────────────────

check_package_candidates() {
  local package
  local candidate
  local missing=()

  for package in "$@"; do
    candidate="$(
      apt-cache policy "${package}" |
        awk '/Candidate:/ { print $2; exit }'
    )"

    if [[ -z "${candidate}" || "${candidate}" == "(none)" ]]; then
      missing+=("${package}")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    printf 'No APT candidate for: %s\n' "${missing[*]}" >&2
    die "Review your distribution repositories before rerunning."
  fi
}

setup_system_packages() {
  section "System packages"

  sudo apt-get update

  # Base prerequisites. ca-certificates is required for HTTPS APT access.
  check_package_candidates ca-certificates gnupg curl lsb-release
  apt_install ca-certificates gnupg curl lsb-release

  if [[ "${UPGRADE_SYSTEM}" == "true" ]]; then
    sudo env DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
  fi

  local packages=(
    git
    zsh
    uidmap
    dbus-user-session
    slirp4netns
    fuse-overlayfs
    xdg-utils
    python3
    python3-pip
    python3-pipx
    python3-venv
    tmate
    ufw
    dnsutils
    net-tools
    htop
    btop
    unzip
    jq
  )

  if [[ "${INSTALL_POSTGRES}" == "true" ]]; then
    packages+=(postgresql postgresql-contrib)
  fi

  if [[ "${INSTALL_SNAPS}" == "true" ]]; then
    packages+=(snapd)
  fi

  if [[ "${INSTALL_FASTFETCH}" == "true" ]]; then
    packages+=(fastfetch)
  fi

  if [[ "${INSTALL_NETWORK_MANAGER}" == "true" ]]; then
    warn "Installing NetworkManager; existing networking is not migrated."
    packages+=(network-manager)
  fi

  if [[ "${INSTALL_TLP}" == "true" ]]; then
    warn "TLP is intended for laptops and may conflict with power managers."
    packages+=(tlp tlp-rdw)
  fi

  check_package_candidates "${packages[@]}"
  apt_install "${packages[@]}"

  if [[ "${INSTALL_POSTGRES}" == "true" ]]; then
    sudo systemctl enable --now postgresql
    warn "PostgreSQL installed; configure roles, backups, and access separately."
  fi

  ok "System packages ready"
}

# ─── Docker ──────────────────────────────────────────────────────────────────

install_docker_packages() {
  local repository_url
  repository_url="https://download.docker.com/linux/${DISTRO_ID}"

  local source_file
  local docker_sources=()
  local source_files=(/etc/apt/sources.list)

  shopt -s nullglob
  source_files+=(
    /etc/apt/sources.list.d/*.list
    /etc/apt/sources.list.d/*.sources
  )
  shopt -u nullglob

  for source_file in "${source_files[@]}"; do
    [[ -f "${source_file}" ]] || continue

    if grep -Eq \
      '^[[:space:]]*[^#].*download[.]docker[.]com' \
      "${source_file}"; then
      if [[ "${source_file}" !=
        "/etc/apt/sources.list.d/docker.sources" ]]; then
        docker_sources+=("${source_file}")
      elif ! grep -Fxq \
        "URIs: ${repository_url}" "${source_file}"; then
        docker_sources+=("${source_file}")
      fi
    fi
  done

  if (( ${#docker_sources[@]} > 0 )); then
    printf 'Review existing Docker APT sources:\n' >&2
    printf '  %s\n' "${docker_sources[@]}" >&2
    die "Consolidate Docker sources before rerunning; do not mix distros."
  fi

  local package
  for package in docker.io docker-compose docker-compose-v2 \
    podman-docker containerd runc
  do
    if dpkg-query -W -f='${Status}' "${package}" 2>/dev/null |
      grep -qx 'install ok installed'; then
      die "Conflicting package: ${package}. Review migration before rerunning."
    fi
  done

  sudo install -d -m 0755 /etc/apt/keyrings
  download "${repository_url}/gpg" "${WORK_DIR}/docker.asc"
  sudo install -m 0644 "${WORK_DIR}/docker.asc" \
    /etc/apt/keyrings/docker.asc

  cat > "${WORK_DIR}/docker.sources" <<EOF
Types: deb
URIs: ${repository_url}
Suites: ${DISTRO_CODENAME}
Components: stable
Architectures: ${DOCKER_ARCH}
Signed-By: /etc/apt/keyrings/docker.asc
EOF

  sudo install -m 0644 "${WORK_DIR}/docker.sources" \
    /etc/apt/sources.list.d/docker.sources

  sudo apt-get update
  check_package_candidates \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin \
    docker-ce-rootless-extras

  apt_install \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin \
    docker-ce-rootless-extras
}

docker_target() {
  if [[ "${DOCKER_MODE}" == "rootless" ]]; then
    docker --context rootless "$@"
  else
    sudo docker --host unix:///var/run/docker.sock "$@"
  fi
}

setup_docker() {
  [[ "${INSTALL_DOCKER}" == "true" ]] || return 0

  section "Docker — ${DOCKER_MODE}"

  [[ -z "${DOCKER_HOST:-}" && -z "${DOCKER_CONTEXT:-}" ]] ||
    die "Unset DOCKER_HOST and DOCKER_CONTEXT before local Docker setup."

  if ! command -v docker >/dev/null 2>&1; then
    install_docker_packages
  else
    ok "Preserving existing installation: $(docker --version)"
    docker compose version >/dev/null ||
      die "Existing Docker lacks Compose v2; repair it before rerunning."
  fi

  if [[ "${DOCKER_MODE}" == "rootless" ]]; then
    command -v dockerd-rootless-setuptool.sh >/dev/null ||
      die "Install rootless extras matching your Docker distribution."

    if sudo systemctl is-active --quiet docker.service ||
      sudo systemctl is-active --quiet docker.socket; then
      die "Rootful Docker is active. Review workloads, stop it, then rerun."
    fi

    [[ -n "${XDG_RUNTIME_DIR:-}" ]] ||
      die "Rootless Docker requires a normal systemd login session."

    systemctl --user show-environment >/dev/null

    awk -F: -v user="${CURRENT_USER}" -v uid="$(id -u)" \
      '($1 == user || $1 == uid) && $3 >= 65536 { found = 1 }
       END { exit !found }' /etc/subuid ||
      die "Allocate at least 65536 subordinate UIDs for ${CURRENT_USER}."

    awk -F: -v user="${CURRENT_USER}" -v uid="$(id -u)" \
      '($1 == user || $1 == uid) && $3 >= 65536 { found = 1 }
       END { exit !found }' /etc/subgid ||
      die "Allocate at least 65536 subordinate GIDs for ${CURRENT_USER}."

    if ! systemctl --user cat docker.service >/dev/null 2>&1; then
      dockerd-rootless-setuptool.sh install
    fi

    sudo loginctl enable-linger "${CURRENT_USER}"
    systemctl --user enable --now docker
    docker context use rootless
  else
    sudo systemctl enable --now docker
    sudo usermod -aG docker "${CURRENT_USER}"
    docker context use default
    warn "Docker group membership grants root-equivalent host access."
    warn "Reconnect your login session before using Docker without sudo."
  fi

  docker_target info >/dev/null

  if ! docker_target network inspect app-net >/dev/null 2>&1; then
    docker_target network create app-net
  fi

  if [[ "${INSTALL_ROLLOUT}" == "true" ]]; then
    download "${ROLLOUT_URL}" "${WORK_DIR}/docker-rollout"
    bash -n "${WORK_DIR}/docker-rollout"
    sudo install -d -m 0755 /usr/local/lib/docker/cli-plugins
    sudo install -m 0755 "${WORK_DIR}/docker-rollout" \
      /usr/local/lib/docker/cli-plugins/docker-rollout
  fi

  docker compose version
  ok "Docker ready"
}

# ─── CLI tools ───────────────────────────────────────────────────────────────

setup_cli_tools() {
  section "CLI tools"

  if [[ "${INSTALL_LAZYDOCKER}" == "true" ]] &&
    ! command -v lazydocker >/dev/null 2>&1; then
    run_installer lazydocker \
      "https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh" \
      bash
  fi

  if [[ "${INSTALL_ZOXIDE}" == "true" ]] &&
    ! command -v zoxide >/dev/null 2>&1; then
    run_installer zoxide \
      "https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh" \
      bash
  fi

  if [[ "${INSTALL_UV}" == "true" ]] &&
    ! command -v uv >/dev/null 2>&1; then
    run_installer uv "https://astral.sh/uv/install.sh" sh
  fi

  if [[ "${INSTALL_LAZYDOCKER}" == "true" ]]; then
    local config="${HOME}/.config/lazydocker/config.yml"

    if [[ ! -e "${config}" ]]; then
      mkdir -p "$(dirname "${config}")"
      printf 'gui:\n  returnImmediately: true\n' > "${config}"
    else
      ok "Preserving existing Lazydocker configuration"
    fi
  fi
}

setup_snaps() {
  [[ "${INSTALL_SNAPS}" == "true" ]] || return 0

  section "Snap packages"
  sudo systemctl enable --now snapd.socket
  sudo timeout 300 snap wait system seed.loaded

  local package
  local packages=(ngrok)

  for package in "${packages[@]}"; do
    if snap list "${package}" >/dev/null 2>&1; then
      ok "Snap already installed: ${package}"
    else
      sudo snap install "${package}"
    fi
  done
}

# ─── Oh My Zsh and plugins ────────────────────────────────────────────────────

clone_and_pin() {
  local repository="$1"
  local destination="$2"
  local reference="$3"

  if [[ -e "${destination}" && ! -d "${destination}/.git" ]]; then
    die "${destination} exists but is not a Git checkout."
  fi

  if [[ ! -d "${destination}/.git" ]]; then
    git clone "${repository}" "${destination}"
  fi

  [[ -z "$(git -C "${destination}" status --porcelain \
    --untracked-files=no)" ]] ||
    die "Tracked local changes in ${destination}; preserve them first."

  if ! git -C "${destination}" cat-file \
    -e "${reference}^{commit}" 2>/dev/null; then
    if [[ "$(git -C "${destination}" rev-parse \
      --is-shallow-repository)" == "true" ]]; then
      git -C "${destination}" fetch --unshallow origin
    else
      git -C "${destination}" fetch origin
    fi
  fi

  git -C "${destination}" checkout --detach "${reference}"
  ok "Pinned $(basename "${destination}") to ${reference}"
}

setup_zsh() {
  section "Oh My Zsh and pinned plugins"

  clone_and_pin \
    "https://github.com/ohmyzsh/ohmyzsh.git" \
    "${ZSH_DIR}" "${OMZ_REF}"

  mkdir -p "${ZSH_CUSTOM}/plugins"

  clone_and_pin \
    "https://github.com/zsh-users/zsh-autosuggestions.git" \
    "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" \
    "${AUTOSUGGESTIONS_REF}"

  clone_and_pin \
    "https://github.com/zsh-users/zsh-completions.git" \
    "${ZSH_CUSTOM}/plugins/zsh-completions" \
    "${COMPLETIONS_REF}"

  clone_and_pin \
    "https://github.com/marlonrichert/zsh-autocomplete.git" \
    "${ZSH_CUSTOM}/plugins/zsh-autocomplete" \
    "${AUTOCOMPLETE_REF}"

  clone_and_pin \
    "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
    "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" \
    "${SYNTAX_HIGHLIGHTING_REF}"
}

setup_aliases() {
  section "Aliases"

  download "${ALIAS_URL}" "${WORK_DIR}/aliases.zsh"
  zsh -n "${WORK_DIR}/aliases.zsh"

  if [[ -f "${ALIAS_FILE}" ]] &&
    cmp -s "${WORK_DIR}/aliases.zsh" "${ALIAS_FILE}"; then
    ok "Aliases unchanged"
    return 0
  fi

  backup_file "${ALIAS_FILE}"
  install -m 0600 "${WORK_DIR}/aliases.zsh" "${ALIAS_FILE}.new"
  mv -f -- "${ALIAS_FILE}.new" "${ALIAS_FILE}"
  ok "Aliases installed without duplicate appends"
}

configure_zsh() {
  section "Zsh configuration"

  local marker="# Managed by setup_debian.sh"

  cat > "${WORK_DIR}/shell.zsh" <<'EOF'
# Managed by setup_debian.sh.
export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="$ZSH/custom"

# Keep the selected Oh My Zsh commit pinned.
zstyle ':omz:update' mode disabled
EOF

  printf 'ZSH_THEME="%s"\n' "${ZSH_THEME}" \
    >> "${WORK_DIR}/shell.zsh"

  cat >> "${WORK_DIR}/shell.zsh" <<'EOF'

typeset -U path PATH
path=("$HOME/.local/bin" "$HOME/bin" /snap/bin $path)

plugins=(
  git
  sudo
  history
  encode64
  copypath
  zsh-autosuggestions
  zsh-completions
  zsh-autocomplete
  command-not-found
  extract
  docker
  colored-man-pages
  alias-finder
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"
source "$HOME/.config/debian-setup/aliases.zsh"

if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi

# Put personal overrides here; this file is never overwritten.
if [[ -f "$HOME/.zshrc.local" ]]; then
  source "$HOME/.zshrc.local"
fi
EOF

  zsh -n "${WORK_DIR}/shell.zsh"
  install -m 0600 "${WORK_DIR}/shell.zsh" "${ZSH_CONFIG}.new"
  mv -f -- "${ZSH_CONFIG}.new" "${ZSH_CONFIG}"

  if [[ -e "${ZSHRC_FILE}" ]] &&
    ! grep -Fxq "${marker}" "${ZSHRC_FILE}"; then
    backup_file "${ZSHRC_FILE}"
    warn "Existing .zshrc backed up; move personal settings to .zshrc.local."
  fi

  cat > "${WORK_DIR}/zshrc" <<'EOF'
# Managed by setup_debian.sh
source "$HOME/.config/debian-setup/shell.zsh"
EOF

  install -m 0600 "${WORK_DIR}/zshrc" "${ZSHRC_FILE}.new"
  mv -f -- "${ZSHRC_FILE}.new" "${ZSHRC_FILE}"

  ok "Zsh configured; ~/.zshenv preserved"
}

# ─── Git, firewall, and shell ─────────────────────────────────────────────────

configure_git() {
  section "Git"

  git config --global user.name "${GIT_USER}"
  git config --global user.email "${GIT_EMAIL}"
  git config --global init.defaultBranch main

  if git config --global --get-all credential.helper |
    grep -Eq '^store([[:space:]]|$)'; then
    warn "Existing plaintext Git credential helper detected."
    warn "It was preserved; migrate credentials to SSH or a secure helper."
  fi

  ok "Git identity configured; credential helpers left unchanged"
}

setup_ufw() {
  if [[ "${ENABLE_UFW}" != "true" ]]; then
    ok "UFW configuration skipped; existing firewall state unchanged"
    return 0
  fi

  section "UFW"

  warn "Confirm SSH_PORT=${SSH_PORT} matches the SSH daemon."
  warn "Docker-published ports may bypass ordinary UFW filtering."

  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow "${SSH_PORT}/tcp" comment 'SSH'

  if [[ "${ALLOW_WEB_PORTS}" == "true" ]]; then
    sudo ufw allow 80/tcp comment 'HTTP'
    sudo ufw allow 443/tcp comment 'HTTPS'
  fi

  sudo ufw --force enable
  sudo ufw status verbose
}

set_default_shell() {
  [[ "${CHANGE_SHELL_TO_ZSH}" == "true" ]] || return 0

  local shell_path
  shell_path="$(command -v zsh)"

  grep -Fxq "${shell_path}" /etc/shells ||
    die "${shell_path} is not listed in /etc/shells."

  sudo usermod --shell "${shell_path}" "${CURRENT_USER}"
  ok "Default shell changed for ${CURRENT_USER}"
}

print_summary() {
  section "Setup complete"

  printf 'Log: %s\n' "${LOG_FILE}"
  printf 'Managed shell config: %s\n' "${ZSH_CONFIG}"
  printf 'Managed aliases: %s\n' "${ALIAS_FILE}"

  cat <<'EOF'

Next steps:
  1. Review any backed-up .zshrc settings.
  2. Put personal overrides in ~/.zshrc.local.
  3. Disconnect and reconnect to refresh group membership.
  4. Start Zsh with: exec zsh
  5. If Docker was enabled:
       docker info
       docker compose version

This is a bootstrap, not complete server hardening.
Review SSH access, security updates, backups, and exposed ports.
EOF

  if [[ -f /var/run/reboot-required ]]; then
    warn "Debian reports that a reboot is required."
  fi

  if [[ "${PROMPT_REBOOT}" == "true" && -t 0 ]]; then
    local answer
    read -r -p "Reboot now? (y/N): " answer || answer="n"

    case "${answer}" in
      y|Y|yes|YES) sudo reboot ;;
      *) ok "Reboot skipped" ;;
    esac
  fi
}

main() {
  preflight
  setup_system_packages
  setup_docker
  setup_cli_tools
  setup_snaps
  setup_zsh
  setup_aliases
  configure_zsh
  configure_git
  setup_ufw
  set_default_shell
  print_summary
}

main "$@"
