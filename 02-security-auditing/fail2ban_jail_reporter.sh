#!/usr/bin/env bash
# ==============================================================================
# Script Name : fail2ban_jail_reporter.sh
# Description : Audits active Fail2ban intrusion defense jails, reports active
#               banned IP counts, and summarizes repeat offensive vectors.
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

Queries Fail2ban status across all configured intrusion defense jails.

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
echo -e "${CYAN} Fail2ban Intrusion Defense & Jail Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v fail2ban-client &>/dev/null; then
    echo -e "${YELLOW}[NOTICE] 'fail2ban-client' is not installed on this host.${NC}"
    echo -e "${CYAN}[INFO] Fail2ban provides automated host intrusion defense against brute-force attacks.${NC}"
    exit 0
fi

if [[ "$EUID" -ne 0 ]]; then
    echo -e "${YELLOW}[NOTICE] Administrative privileges are recommended to query fail2ban-client.${NC}\n"
fi

STATUS_OUT=$(fail2ban-client status 2>/dev/null || true)

if [[ -z "$STATUS_OUT" ]]; then
    echo -e "${RED}[ERROR] Fail2ban daemon is inactive or access to control socket was denied.${NC}" >&2
    exit 1
fi

JAILS=$(echo "$STATUS_OUT" | grep "Jail list:" | cut -d: -f2 | tr ',' ' ' | xargs || true)

if [[ -z "$JAILS" ]]; then
    echo -e "${YELLOW}[NOTICE] No active Fail2ban jails currently enabled.${NC}"
    exit 0
fi

echo -e "Active Jails Discovered: ${GREEN}${JAILS}${NC}\n"
printf "%-18s %-15s %-15s %-30s\n" "JAIL NAME" "CURRENT BANS" "TOTAL BANS" "CURRENTLY BANNED IPS"
printf "%-18s %-15s %-15s %-30s\n" "---------" "------------" "----------" "--------------------"

for jail in $JAILS; do
    jail_info=$(fail2ban-client status "$jail" 2>/dev/null || true)
    currently_banned=$(echo "$jail_info" | grep "Currently banned:" | awk '{print $NF}' || echo 0)
    total_banned=$(echo "$jail_info" | grep "Total banned:" | awk '{print $NF}' || echo 0)
    banned_ips=$(echo "$jail_info" | grep "Banned IP list:" | cut -d: -f2 | xargs || echo "None")

    printf "%-18s %-15s %-15s %-30s\n" "$jail" "$currently_banned" "$total_banned" "${banned_ips:-None}"
done

echo -e "\n${GREEN}[SUCCESS] Fail2ban audit completed.${NC}"
exit 0
