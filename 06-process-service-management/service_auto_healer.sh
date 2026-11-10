#!/usr/bin/env bash
# ==============================================================================
# Script Name : service_auto_healer.sh
# Description : Monitors critical systemd services; if failed or inactive, restarts
#               the daemon, verifies health post-restart, and logs incident.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, systemctl
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SERVICES=()

usage() {
    cat <<EOF
Usage: $(basename "$0") -s <service> [OPTIONS]

Monitors and auto-heals failed systemd daemons.

Options:
  -s, --service <name>   Service name to inspect (can specify multiple times)
  -h, --help             Show this help message and exit

Example:
  sudo $(basename "$0") -s nginx -s mariadb -s docker
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--service)
            SERVICES+=("$2"); shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

if [[ ${#SERVICES[@]} -eq 0 ]]; then
    echo -e "${RED}[ERROR] At least one service (-s) must be specified.${NC}" >&2
    exit 2
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Critical Systemd Service Auto-Healer - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v systemctl &>/dev/null; then
    echo -e "${RED}[ERROR] 'systemctl' not available.${NC}" >&2
    exit 1
fi

for svc in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$svc"; then
        echo -e "  ${GREEN}[ACTIVE]${NC} Service '${svc}' is running normally."
    else
        echo -e "  ${RED}[DOWN]${NC} Service '${svc}' is inactive or failed!"
        if [[ "$EUID" -eq 0 ]]; then
            echo -e "  -> ${YELLOW}[RESTARTING]${NC} Attempting auto-recovery for '${svc}'..."
            systemctl restart "$svc" 2>/dev/null || true
            sleep 1
            if systemctl is-active --quiet "$svc"; then
                echo -e "  -> ${GREEN}[RECOVERED]${NC} Service '${svc}' successfully restored."
            else
                echo -e "  -> ${RED}[FAILED]${NC} Could not restore service '${svc}'. Check journalctl -u ${svc}."
            fi
        else
            echo -e "  -> ${YELLOW}[NOTICE] Re-run as root to enable automatic service recovery.${NC}"
        fi
    fi
done

exit 0
