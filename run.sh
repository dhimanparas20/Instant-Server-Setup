#!/usr/bin/env bash
set -e

REPO="Instant-Server-Setup"
GIT_URL="https://github.com/dhimanparas20/Instant-Server-Setup.git"

# Get current directory name
CUR_DIR="$(basename "$PWD")"

# If not in repo dir, clone or cd into it
if [ "$CUR_DIR" != "$REPO" ]; then
    if [ ! -d "$REPO" ]; then
        echo "Cloning $REPO repository..."
        git clone "$GIT_URL"
    fi
    cd "$REPO"
fi

# Make all scripts executable
echo "Setting executable permissions..."
chmod +x run_super.sh
find Arch Debian Fedora Ubuntu -type f -name "*.sh" -exec chmod +x {} \;

# Prompt for distro
echo "Select your Linux distribution:"
select DISTRO in Arch Debian Fedora Ubuntu; do
    if [[ "$DISTRO" =~ ^(Arch|Debian|Fedora|Ubuntu)$ ]]; then
        break
    else
        echo "Invalid selection. Please choose a number from the list."
    fi
done

# Prompt for setup stage
echo "Select setup stage:"
select VARIANT in first second opt; do
    if [[ "$VARIANT" =~ ^(first|second|opt)$ ]]; then
        break
    else
        echo "Invalid selection. Please choose a number from the list."
    fi
done

# Run the super script
echo "Running: sudo ./run_super.sh -d $DISTRO -v $VARIANT"
sudo ./run_super.sh -d "$DISTRO" -v "$VARIANT"
