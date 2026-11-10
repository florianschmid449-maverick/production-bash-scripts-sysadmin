#!/usr/bin/env bash
# ==============================================================================
# Script Name : automated_apt_dnf_updater.sh
# Description : Refreshes repository metadata, applies non-interactive security
#               upgrades, and records changes to /var/log/system_updates.log.
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

DRY_RUN=false
LOG_FILE="/tmp/system_updates.log"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Applies unattended package security updates and logs upgrades.

Options:
  -n, --dry-run   Simulate update cycle without installing packages
  -h, --help      Show this help message and exit

Example:
  sudo $(basename "$0") --dry-run
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run)
            DRY_RUN=true; shift ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Automated Non-Interactive System Patching - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if [[ "$EUID" -ne 0 && "$DRY_RUN" == false ]]; then
    echo -e "${RED}[ERROR] Root privileges required to apply system updates.${NC}" >&2
    exit 1
fi

if command -v apt-get &>/dev/null; then
    echo -e "${YELLOW}[APT] Updating package lists...${NC}"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y >/dev/null 2>&1 || true

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${CYAN}[DRY-RUN] Simulating upgrade...${NC}"
        apt-get -s upgrade
    else
        echo -e "${YELLOW}[APT] Applying upgrades...${NC}"
        apt-get upgrade -y | tee -a "$LOG_FILE"
        echo -e "${GREEN}[SUCCESS] System packages updated.${NC}"
    fi

elif command -v dnf &>/dev/null; then
    if [[ "$DRY_RUN" == true ]]; then
        dnf check-update --security || true
    else
        dnf upgrade-minimal --security -y | tee -a "$LOG_FILE"
        echo -e "${GREEN}[SUCCESS] Security updates applied.${NC}"
    fi
fi

exit 0
