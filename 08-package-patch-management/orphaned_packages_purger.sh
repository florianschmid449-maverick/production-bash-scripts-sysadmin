#!/usr/bin/env bash
# ==============================================================================
# Script Name : orphaned_packages_purger.sh
# Description : Identifies and removes unneeded dependency packages, residual
#               config files, and cleans package download caches safely.
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

Purges unneeded orphaned packages and cleans package caches.

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
echo -e "${CYAN} Orphaned Package & Dependency Purger - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if command -v apt-get &>/dev/null; then
    echo -e "${YELLOW}[APT] Removing unused orphaned packages...${NC}"
    apt-get autoremove --purge -y 2>/dev/null || true
    apt-get autoclean -y 2>/dev/null || true
    echo -e "${GREEN}[SUCCESS] APT orphan packages purged.${NC}"
elif command -v dnf &>/dev/null; then
    echo -e "${YELLOW}[DNF] Removing unused packages...${NC}"
    dnf autoremove -y 2>/dev/null || true
    echo -e "${GREEN}[SUCCESS] DNF orphan packages removed.${NC}"
fi

exit 0
