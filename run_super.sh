#!/usr/bin/env bash
set -e

usage() {
    echo "Usage: $0 -d <Arch|Debian|Fedora|Ubuntu> -v <first|second|opt>"
    exit 1
}

# Parse arguments
while getopts ":d:v:" opt; do
  case $opt in
    d)
      DISTRO="${OPTARG,,}" # to lowercase
      ;;
    v)
      VARIANT="${OPTARG,,}"
      ;;
    *)
      usage
      ;;
  esac
done

# Check both parameters are provided
if [ -z "${DISTRO:-}" ] || [ -z "${VARIANT:-}" ]; then
    usage
fi

# Map variant to script name
case "$VARIANT" in
  first)
    SCRIPT="run_first.sh"
    ;;
  second)
    SCRIPT="run_second.sh"
    ;;
  opt)
    SCRIPT="run_optional.sh"
    ;;
  *)
    echo "Unknown variant: $VARIANT"
    usage
    ;;
esac

# Map distro to folder name (capitalize first letter)
case "$DISTRO" in
  arch|debian|fedora|ubuntu)
    FOLDER="$(tr '[:lower:]' '[:upper:]' <<< ${DISTRO:0:1})${DISTRO:1}"
    ;;
  *)
    echo "Unknown distro: $DISTRO"
    usage
    ;;
esac

# Check if the script exists
if [ ! -f "./$FOLDER/$SCRIPT" ]; then
    echo "Script not found: $FOLDER/$SCRIPT"
    exit 2
fi

# Run the script
bash "./$FOLDER/$SCRIPT"
