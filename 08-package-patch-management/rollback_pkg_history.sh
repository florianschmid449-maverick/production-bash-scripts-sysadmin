#!/usr/bin/env bash
# ==============================================================================
# Script Name : rollback_pkg_history.sh
# Description : Parses package manager transaction histories (dnf history or
#               /var/log/dpkg.log) to facilitate rapid rollbacks of faulty updates.
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

Inspects recent package upgrade history and displays rollback operations.

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
echo -e "${CYAN} Package Manager Transaction & Rollback History - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if command -v dnf &>/dev/null; then
    echo -e "${YELLOW}Recent DNF Transactions:${NC}"
    dnf history list | head -n 10
    echo -e "\n${CYAN}[INFO] To rollback a transaction, run: sudo dnf history rollback <ID>${NC}"
elif [[ -f /var/log/dpkg.log ]]; then
    echo -e "${YELLOW}Recent DPKG Upgrades / Installs (/var/log/dpkg.log):${NC}"
    grep -E "upgrade|install" /var/log/dpkg.log | tail -n 15 | while read -r line; do
        echo -e "  -> ${line}"
    done
else
    echo -e "${YELLOW}[NOTICE] No transaction history logs found.${NC}"
fi

exit 0
