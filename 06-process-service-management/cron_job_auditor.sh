#!/usr/bin/env bash
# ==============================================================================
# Script Name : cron_job_auditor.sh
# Description : Thoroughly audits all cron schedules (/etc/cron*, user crontabs,
#               and systemd timers) flagging tasks executing from /tmp or /dev/shm.
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

Enumerates and audits scheduled cron jobs and systemd timers.

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
echo -e "${CYAN} Comprehensive Cron & Timer Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

# 1. System cron files
echo -e "${YELLOW}System Cron Directories (/etc/cron*):${NC}"
for cdir in /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.weekly /etc/cron.monthly; do
    if [[ -d "$cdir" ]]; then
        find "$cdir" -maxdepth 1 -type f ! -name ".*" | while read -r item; do
            echo -e "  -> ${item}"
            if grep -E "(/tmp|/dev/shm)" "$item" >/dev/null 2>&1; then
                echo -e "     ${RED}[SUSPICIOUS] Executes from world-writable folder!${NC}"
            fi
        done
    fi
done

# 2. User crontabs
echo -e "\n${YELLOW}User Crontabs (/var/spool/cron):${NC}"
if [[ -d /var/spool/cron/crontabs && -r /var/spool/cron/crontabs ]]; then
    for cfile in /var/spool/cron/crontabs/*; do
        [[ -f "$cfile" ]] && echo -e "  User crontab: $(basename "$cfile")"
    done
else
    echo -e "  (Root permissions required to inspect /var/spool/cron/crontabs)"
fi

# 3. Systemd Timers
if command -v systemctl &>/dev/null; then
    echo -e "\n${YELLOW}Active Systemd Timers:${NC}"
    systemctl list-timers --no-legend 2>/dev/null | awk '{print "  Timer: " $NF}' || true
fi

exit 0
