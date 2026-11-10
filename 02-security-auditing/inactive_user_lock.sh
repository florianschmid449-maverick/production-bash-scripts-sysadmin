#!/usr/bin/env bash
# ==============================================================================
# Script Name : inactive_user_lock.sh
# Description : Audits user accounts using lastlog to find accounts inactive
#               for over 90 days, with options to safely lock passwords.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, lastlog, usermod
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

INACTIVE_DAYS=90
LOCK_ACCOUNTS=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Identifies dormant accounts with no recorded logins for over N days.

Options:
  -d, --days <count>   Inactivity duration in days (default: 90)
  -l, --lock           Lock passwords of detected inactive accounts
  -h, --help           Show this help message and exit

Example:
  sudo $(basename "$0") -d 60 --lock
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--days)
            INACTIVE_DAYS="$2"; shift 2 ;;
        -l|--lock)
            LOCK_ACCOUNTS=true; shift ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Dormant & Inactive Account Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v lastlog &>/dev/null; then
    echo -e "${RED}[ERROR] 'lastlog' command not found.${NC}" >&2
    exit 1
fi

echo -e "Auditing accounts with no login activity for >= ${INACTIVE_DAYS} days:\n"

lastlog -b "$INACTIVE_DAYS" | tail -n +2 | while read -r line; do
    user=$(echo "$line" | awk '{print $1}')
    # Skip system users (UID < 1000)
    uid=$(id -u "$user" 2>/dev/null || echo 0)
    if [[ "$uid" -lt 1000 ]]; then
        continue
    fi

    echo -e "${YELLOW}[INACTIVE]${NC} User: ${user} (UID: ${uid}) | Last activity: ${line#*"$user"}"

    if [[ "$LOCK_ACCOUNTS" == true && "$EUID" -eq 0 ]]; then
        passwd -l "$user" >/dev/null 2>&1 || true
        echo -e "  -> ${RED}[LOCKED] Account password disabled.${NC}"
    fi
done

exit 0
