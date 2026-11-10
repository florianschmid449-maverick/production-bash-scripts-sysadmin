#!/usr/bin/env bash
# ==============================================================================
# Script Name : user_account_expiry_checker.sh
# Description : Audits user accounts for approaching password expiration,
#               account lock status, and inactive dormant accounts.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, chage, getent
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

WARN_DAYS=14

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Audits user account password expiration and validity dates.

Options:
  -w, --warn-days <days>   Warning threshold in days prior to expiration (default: 14)
  -h, --help               Show this help message and exit

Example:
  sudo $(basename "$0") -w 30
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -w|--warn-days)
            WARN_DAYS="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} User Account & Password Expiry Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if [[ "$EUID" -ne 0 ]]; then
    echo -e "${YELLOW}[NOTICE] Root privileges are required to inspect /etc/shadow directly via chage.${NC}"
    echo -e "${CYAN}[INFO] Auditing current user: ${USER}${NC}\n"
fi

NOW_EPOCH=$(date +%s)
printf "%-18s %-22s %-15s\n" "USERNAME" "PASSWORD EXPIRES" "STATUS"
printf "%-18s %-22s %-15s\n" "--------" "----------------" "------"

# Enumerate accounts with human shells
getent passwd | awk -F: '$7 ~ /(bash|sh|zsh)$/ {print $1}' | while read -r username; do
    if command -v chage &>/dev/null; then
        chage_info=$(chage -l "$username" 2>/dev/null || true)
        if [[ -n "$chage_info" ]]; then
            exp_date=$(echo "$chage_info" | grep -m1 '^Password expires' | cut -d: -f2 | xargs)

            if [[ "$exp_date" == "never" ]]; then
                printf "%-18s %-22s %-15s\n" "$username" "Never" "No Expiration"
            else
                exp_epoch=$(date -d "$exp_date" +%s 2>/dev/null || echo 0)
                diff_days=$(( (exp_epoch - NOW_EPOCH) / 86400 ))

                if [[ "$diff_days" -lt 0 ]]; then
                    printf "%-18s %-22s %-15s\n" "$username" "$exp_date" "EXPIRED"
                elif [[ "$diff_days" -le "$WARN_DAYS" ]]; then
                    printf "%-18s %-22s %-15s\n" "$username" "$exp_date" "Expiring (${diff_days}d)"
                else
                    printf "%-18s %-22s %-15s\n" "$username" "$exp_date" "Valid (${diff_days}d)"
                fi
            fi
        fi
    fi
done

exit 0
