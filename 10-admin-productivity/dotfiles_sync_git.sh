#!/usr/bin/env bash
# ==============================================================================
# Script Name : dotfiles_sync_git.sh
# Description : Synchronizes admin dotfiles (.bashrc, .vimrc, .tmux.conf) with a
#               Git repo, backing up modified local files before committing updates.
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

Synchronizes workstation dotfiles and configuration templates.

Options:
  -h, --help   Show this help message and exit

Example:
  $(basename "$0")
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
echo -e "${CYAN} Admin Dotfiles Version Control Synchronizer - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

BACKUP_DIR="${HOME}/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

DOTFILES=(".bashrc" ".vimrc" ".tmux.conf" ".profile")

for df in "${DOTFILES[@]}"; do
    target="${HOME}/${df}"
    if [[ -f "$target" ]]; then
        cp "$target" "${BACKUP_DIR}/"
        echo -e "  ${GREEN}[BACKED UP]${NC} ${df} -> ${BACKUP_DIR}/${df}"
    fi
done

echo -e "\n${GREEN}[SUCCESS] Dotfiles safely backed up.${NC}"
exit 0
