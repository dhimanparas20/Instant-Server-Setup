#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/dhimanparas20/Instant-Server-Setup.git"
REPO_DIR="Instant-Server-Setup"

# ----------------------------- helpers ---------------------------------

error() {
  echo -e "\e[31m[ERROR]\e[0m $*" >&2
  exit 1
}

info() {
  echo -e "\e[34m[INFO]\e[0m $*"
}

success() {
  echo -e "\e[32m[SUCCESS]\e[0m $*"
}

ensure_in_repo() {
  local cwd_basename
  cwd_basename="$(basename "$PWD")"

  if [[ "$cwd_basename" == "$REPO_DIR" ]]; then
    success "Already inside $REPO_DIR, skipping clone/cd."
    return
  fi

  if [[ -d "$REPO_DIR" ]]; then
    info "Directory $REPO_DIR already exists. Entering it."
    cd "$REPO_DIR" || error "Failed to cd into $REPO_DIR"
  else
    command -v git >/dev/null 2>&1 || error "git is required but not installed."
    info "Cloning repository: $REPO_URL"
    git clone "$REPO_URL" "$REPO_DIR" || error "git clone failed."
    cd "$REPO_DIR" || error "Failed to cd into $REPO_DIR after clone."
  fi
}

select_distro() {
  echo
  echo "Select your distro:"
  echo "  1) Arch"
  echo "  2) Debian"
  echo "  3) Fedora"
  echo "  4) Ubuntu"
  echo

  read -r -p "Enter choice [1-4]: " choice

  case "${choice,,}" in
    1|arch)
      DISTRO_DIR="Arch"
      DISTRO_ID="arch"
      ;;
    2|debian)
      DISTRO_DIR="Debian"
      DISTRO_ID="debian"
      ;;
    3|fedora)
      DISTRO_DIR="Fedora"
      DISTRO_ID="fedora"
      ;;
    4|ubuntu)
      DISTRO_DIR="Ubuntu"
      DISTRO_ID="ubuntu"
      ;;
    *)
      error "Invalid distro choice."
      ;;
  esac

  success "Selected distro: $DISTRO_DIR"
}

select_script_type() {
  echo
  echo "Select script to run:"
  echo "  1) Main (setup_<distro>.sh)  [default]"
  echo "  2) Optional (run_optional.sh)"
  echo

  read -r -p "Enter choice [1-2, default 1]: " script_choice
  script_choice="${script_choice:-1}"

  case "${script_choice,,}" in
    1|main|"")
      SCRIPT_KIND="main"
      ;;
    2|optional)
      SCRIPT_KIND="optional"
      ;;
    *)
      error "Invalid script choice."
      ;;
  esac

  success "Selected script type: $SCRIPT_KIND"
}

detect_pkg_manager() {
  case "$DISTRO_ID" in
    arch)
      PKG_MGR="pacman"
      ;;
    debian|ubuntu)
      PKG_MGR="apt"
      ;;
    fedora)
      PKG_MGR="dnf"
      ;;
    *)
      error "Unsupported distro id '$DISTRO_ID' for package installation."
      ;;
  esac
}

install_pkg() {
  local pkg="$1"

  case "$PKG_MGR" in
    apt)
      sudo apt update -y >/dev/null 2>&1 || true
      sudo apt install -y "$pkg"
      ;;
    dnf)
      sudo dnf install -y "$pkg"
      ;;
    pacman)
      sudo pacman -Syu --noconfirm >/dev/null 2>&1 || true
      sudo pacman -S --noconfirm "$pkg"
      ;;
    *)
      error "Internal error: unknown PKG_MGR '$PKG_MGR'."
      ;;
  esac
}

ensure_curl() {
  if ! command -v curl >/dev/null 2>&1; then
    info "curl not found, installing..."
    install_pkg "curl"
  fi
}

# Just check requirements, do NOT install them
check_zsh_requirements() {
  local missing=0

  if ! command -v zsh >/dev/null 2>&1; then
    echo -e "\e[31m[ERROR]\e[0m zsh is not installed."
    missing=1
  fi

  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo -e "\e[31m[ERROR]\e[0m Oh My Zsh is not installed (expected at \$HOME/.oh-my-zsh)."
    missing=1
  fi

  if (( missing )); then
    echo
    echo "Please install zsh and Oh My Zsh first."
    echo "For Debian/Ubuntu you can run:"
    echo '  sudo apt install zsh -y && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
    echo
    exit 1
  fi
}

build_script_path() {
  local lower_id="$DISTRO_ID"
  case "$SCRIPT_KIND" in
    main)
      SCRIPT_PATH="$DISTRO_DIR/setup_${lower_id}.sh"
      ;;
    optional)
      SCRIPT_PATH="$DISTRO_DIR/run_optional.sh"
      ;;
    *)
      error "Internal error: unknown SCRIPT_KIND '$SCRIPT_KIND'."
      ;;
  esac

  if [[ ! -f "$SCRIPT_PATH" ]]; then
    error "Target script '$SCRIPT_PATH' not found."
  fi
}

# --------------------------- main flow ---------------------------------

ensure_in_repo
select_distro
select_script_type
detect_pkg_manager
ensure_curl
check_zsh_requirements
build_script_path

echo
info "Running '$SCRIPT_PATH' with zsh..."
echo

# Use zsh explicitly
zsh "$SCRIPT_PATH"
