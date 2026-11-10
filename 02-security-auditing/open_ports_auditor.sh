#!/usr/bin/env bash
# ==============================================================================
# Script Name : open_ports_auditor.sh
# Description : Audits open TCP and UDP listening ports and maps them to active
#               processes, flagging services bound to 0.0.0.0 or public IPs.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, ss or netstat
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

Audits active listening TCP and UDP sockets and bound network interfaces.

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
echo -e "${CYAN} Open Listening Ports & Services Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v ss &>/dev/null; then
    echo -e "${RED}[ERROR]${NC} 'ss' command not found." >&2
    exit 1
fi

printf "%-6s %-25s %-20s %-15s\n" "PROTO" "LOCAL ADDRESS:PORT" "PROCESS" "EXPOSURE"
printf "%-6s %-25s %-20s %-15s\n" "-----" "------------------" "-------" "--------"

ss -tulnp 2>/dev/null | tail -n +2 | while read -r line; do
    proto=$(echo "$line" | awk '{print $1}')
    local_addr=$(echo "$line" | awk '{print $5}')
    proc_info=$(echo "$line" | awk '{print $7}')

    # Truncate process info if present
    proc_name="${proc_info#*users:((\"}"
    proc_name="${proc_name%%\"*}"

    exposure="${GREEN}Localhost${NC}"
    if [[ "$local_addr" =~ ^0\.0\.0\.0: || "$local_addr" =~ ^\[::\]: || "$local_addr" =~ ^\*: ]]; then
        exposure="${RED}PUBLIC (0.0.0.0)${NC}"
    fi

    printf "%-6s %-25s %-20s " "$proto" "$local_addr" "${proc_name:-unknown}"
    echo -e "$exposure"
done

exit 0
