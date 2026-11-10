#!/usr/bin/env bash
# ==============================================================================
# Script Name : failed_ssh_logins.sh
# Description : Parses authentication logs to tally failed SSH login attempts,
#               identify attacking IP addresses, and generate block rules.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, awk, grep
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

TOP_COUNT=10
GEN_RULES=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Audits failed SSH login attempts from system authentication logs.

Options:
  -n, --top <count>    Number of top attacking IPs to display (default: 10)
  -b, --block-rules    Generate sample iptables DROP commands for top offenders
  -h, --help           Show this help message and exit

Example:
  $(basename "$0") -n 15 --block-rules
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--top)
            TOP_COUNT="$2"; shift 2 ;;
        -b|--block-rules)
            GEN_RULES=true; shift ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Failed SSH Login & Brute-Force Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

# Locate system auth log
AUTH_LOG=""
for candidate in "/var/log/auth.log" "/var/log/secure"; do
    if [[ -f "$candidate" && -r "$candidate" ]]; then
        AUTH_LOG="$candidate"
        break
    fi
done

TMP_LOG=$(mktemp)
trap 'rm -f "$TMP_LOG"' EXIT INT TERM

if [[ -n "$AUTH_LOG" ]]; then
    grep -E "Failed password|authentication failure" "$AUTH_LOG" > "$TMP_LOG" || true
elif command -v journalctl &>/dev/null; then
    journalctl -u ssh -u sshd --since "7 days ago" 2>/dev/null | grep -E "Failed password|authentication failure" > "$TMP_LOG" || true
else
    echo -e "${YELLOW}[NOTICE] No readable auth log (/var/log/auth.log or /var/log/secure) found.${NC}"
    echo -e "${CYAN}[INFO] Auditing requires root or 'adm' group permissions.${NC}"
    exit 0
fi

TOTAL_FAILED=$(wc -l < "$TMP_LOG" || echo 0)
echo -e "Total Failed SSH Attempts Recorded: ${RED}${TOTAL_FAILED}${NC}\n"

if [[ "$TOTAL_FAILED" -eq 0 ]]; then
    echo -e "${GREEN}[OK] No failed login attempts detected.${NC}"
    exit 0
fi

echo -e "Top ${TOP_COUNT} Offending IP Addresses:"
printf "%-10s %-20s\n" "ATTEMPTS" "IP ADDRESS"
printf "%-10s %-20s\n" "--------" "----------"

TOP_IPS=$(grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" "$TMP_LOG" | sort | uniq -c | sort -rn | head -n "$TOP_COUNT")
echo "$TOP_IPS" | awk '{printf "%-10s %-20s\n", $1, $2}'

if [[ "$GEN_RULES" == true ]]; then
    echo -e "\n${YELLOW}[ACTION] Recommended iptables Mitigation Rules:${NC}"
    echo "$TOP_IPS" | while read -r count ip; do
        echo "iptables -I INPUT -s ${ip} -j DROP"
    done
fi

exit 0
