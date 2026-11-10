#!/usr/bin/env bash
# ==============================================================================
# Script Name : vagrant_bulk_cleaner.sh
# Description : Queries vagrant global-status to identify abandoned development
#               environments and cleanly destroys stale virtual machines to free RAM.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, vagrant
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

Audits and cleans orphaned Vagrant virtual machines.

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
echo -e "${CYAN} Vagrant Environment Fleet Cleaner - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v vagrant &>/dev/null; then
    echo -e "${YELLOW}[NOTICE] 'vagrant' command not installed on this machine.${NC}"
    exit 0
fi

echo -e "Pruning stale state and listing active Vagrant machines...\n"
vagrant global-status --prune

exit 0
