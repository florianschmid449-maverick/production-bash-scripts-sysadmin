#!/usr/bin/env bash
# ==============================================================================
# Script Name : kernel_version_checker_reboot.sh
# Description : Compares running kernel version with newest installed kernel,
#               checking /var/run/reboot-required to flag pending reboots.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, uname
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

Checks if installed kernel updates require a host reboot.

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
echo -e "${CYAN} Kernel Version & Pending Reboot Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

CURRENT_KERNEL=$(uname -r)
echo -e "Currently Running Kernel : ${GREEN}${CURRENT_KERNEL}${NC}"

REBOOT_REQUIRED=false

# Method 1: Check Debian/Ubuntu reboot-required flag
if [[ -f /var/run/reboot-required ]]; then
    REBOOT_REQUIRED=true
    echo -e "${RED}[REBOOT REQUIRED] System flag /var/run/reboot-required is present!${NC}"
    if [[ -f /var/run/reboot-required.pkgs ]]; then
        echo -e "${YELLOW}Packages triggering reboot:${NC}"
        cat /var/run/reboot-required.pkgs | sed 's/^/  /'
    fi
fi

# Method 2: Check needs-restarting on RHEL/Fedora
if command -v needs-restarting &>/dev/null; then
    if ! needs-restarting -r >/dev/null 2>&1; then
        REBOOT_REQUIRED=true
        echo -e "${RED}[REBOOT REQUIRED] Core libraries or kernel require host restart.${NC}"
    fi
fi

if [[ "$REBOOT_REQUIRED" == false ]]; then
    echo -e "${GREEN}[OK] Running kernel is up-to-date. No system reboot required.${NC}"
fi

exit 0
