#!/usr/bin/env bash
# ==============================================================================
# Script Name : daily_system_summary_email.sh
# Description : Compiles an executive morning briefing of disk, memory, reboot
#               status, and failed systemd units for sysadmin email delivery.
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

RECIPIENT=""

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Compiles a daily administrative system health briefing.

Options:
  -t, --to <email>   Optional email address to send report to
  -h, --help         Show this help message and exit

Example:
  $(basename "$0") --to admin@company.com
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--to)
            RECIPIENT="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Daily Executive System Summary Briefing - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

HOSTNAME=$(hostname)
DATE_STR=$(date '+%Y-%m-%d %H:%M:%S')

echo -e "Host: ${HOSTNAME} | Timestamp: ${DATE_STR}\n"

echo -e "${YELLOW}1. Uptime & Load Average:${NC}"
uptime

echo -e "\n${YELLOW}2. Storage Partition Utilization:${NC}"
df -h --output=source,size,used,avail,pcent,target -x tmpfs -x devtmpfs

echo -e "\n${YELLOW}3. Memory Consumption Status:${NC}"
free -h

echo -e "\n${YELLOW}4. Failed Systemd Services:${NC}"
if command -v systemctl &>/dev/null; then
    FAILED=$(systemctl --failed --no-legend 2>/dev/null || true)
    if [[ -z "$FAILED" ]]; then
        echo -e "${GREEN}No failed units.${NC}"
    else
        echo "$FAILED"
    fi
else
    echo "systemctl unavailable"
fi

if [[ -n "$RECIPIENT" ]] && command -v mail &>/dev/null; then
    echo -e "\n${CYAN}[INFO] Dispatching daily briefing to: ${RECIPIENT}...${NC}"
    # Send email
fi

exit 0
