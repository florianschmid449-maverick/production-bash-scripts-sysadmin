#!/usr/bin/env bash
# ==============================================================================
# Script Name : systemd_failed_services_alert.sh
# Description : Audits systemctl --failed for crashed or degraded units, extracting
#               exit status and recent log output from journalctl for diagnosis.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, systemctl, journalctl
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

Queries systemd for failed services and dumps error reasons.

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
echo -e "${CYAN} Failed Systemd Services Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v systemctl &>/dev/null; then
    echo -e "${RED}[ERROR] 'systemctl' command not found.${NC}" >&2
    exit 1
fi

FAILED_UNITS=$(systemctl --failed --no-legend 2>/dev/null | awk '{print $2}' || true)

if [[ -z "$FAILED_UNITS" ]]; then
    echo -e "${GREEN}[OK] System is healthy. Zero systemd units in failed/degraded state.${NC}"
    exit 0
fi

echo -e "${RED}[ALERT] Detected Failed Systemd Units:${NC}\n"
for unit in $FAILED_UNITS; do
    echo -e "${RED}Unit: ${unit}${NC}"
    # Extract last 3 journal lines
    if command -v journalctl &>/dev/null; then
        echo -e "${YELLOW}Recent Journal Output:${NC}"
        journalctl -u "$unit" -n 3 --no-pager 2>/dev/null | sed 's/^/  /' || true
    fi
    echo ""
done

exit 1
