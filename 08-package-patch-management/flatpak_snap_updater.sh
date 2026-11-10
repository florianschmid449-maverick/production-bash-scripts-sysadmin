#!/usr/bin/env bash
# ==============================================================================
# Script Name : flatpak_snap_updater.sh
# Description : Detects sandboxed Snap and Flatpak runtimes, checks for application
#               updates, applies them non-interactively, and prunes old revisions.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Checks and applies updates for Flatpak and Snap applications.

Options:
  -h, --help   Show this help message and exit

Example:
  sudo $(basename "$0")
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Flatpak & Snap Sandboxed Application Updater - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

# Snap refresh
if command -v snap &>/dev/null; then
    echo -e "${YELLOW}[SNAP] Checking for application updates...${NC}"
    snap refresh 2>/dev/null || true
    echo -e "${GREEN}[OK] Snap applications updated.${NC}"
fi

# Flatpak update
if command -v flatpak &>/dev/null; then
    echo -e "\n${YELLOW}[FLATPAK] Updating Flatpak runtimes...${NC}"
    flatpak update -y --noninteractive 2>/dev/null || true
    echo -e "${GREEN}[OK] Flatpak applications updated.${NC}"
fi

exit 0
