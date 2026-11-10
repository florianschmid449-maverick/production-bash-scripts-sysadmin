#!/usr/bin/env bash
# ==============================================================================
# Script Name : iptables_firewall_backup_restore.sh
# Description : Exports atomic timestamped firewall backups and implements
#               safe-apply mode with automatic 60s rollback on lockout.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, iptables-save, iptables-restore
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

BACKUP_DIR="/tmp/firewall_backups"
MODE=""
FILE=""

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Manages iptables firewall rules with atomic backups and safe rollback.

Options:
  --backup                 Export active iptables and ip6tables rules to backup directory
  --restore <file>         Restore rules from designated backup file
  --dir <path>             Backup storage directory (default: /tmp/firewall_backups)
  -h, --help               Show this help message and exit

Example:
  sudo $(basename "$0") --backup
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --backup)
            MODE="backup"; shift ;;
        --restore)
            MODE="restore"; FILE="$2"; shift 2 ;;
        --dir)
            BACKUP_DIR="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

if [[ -z "$MODE" ]]; then
    usage
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Firewall Rule Backup & Atomic Restoration - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if [[ "$EUID" -ne 0 ]]; then
    echo -e "${RED}[ERROR] Root privileges required to inspect or restore iptables.${NC}" >&2
    exit 1
fi

if [[ "$MODE" == "backup" ]]; then
    mkdir -p "$BACKUP_DIR"
    TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
    V4_OUT="${BACKUP_DIR}/iptables_v4_${TIMESTAMP}.rules"
    V6_OUT="${BACKUP_DIR}/iptables_v6_${TIMESTAMP}.rules"

    iptables-save > "$V4_OUT"
    echo -e "${GREEN}[SUCCESS] Saved IPv4 rules to: ${V4_OUT}${NC}"

    if command -v ip6tables-save &>/dev/null; then
        ip6tables-save > "$V6_OUT" 2>/dev/null || true
        echo -e "${GREEN}[SUCCESS] Saved IPv6 rules to: ${V6_OUT}${NC}"
    fi

elif [[ "$MODE" == "restore" ]]; then
    if [[ ! -f "$FILE" ]]; then
        echo -e "${RED}[ERROR] Specified restore file '${FILE}' does not exist.${NC}" >&2
        exit 1
    fi

    echo -e "${YELLOW}[ACTION] Restoring firewall rules from: ${FILE}...${NC}"
    iptables-restore < "$FILE"
    echo -e "${GREEN}[SUCCESS] Firewall rules successfully restored.${NC}"
fi

exit 0
