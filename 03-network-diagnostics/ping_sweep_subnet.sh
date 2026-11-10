#!/usr/bin/env bash
# ==============================================================================
# Script Name : ping_sweep_subnet.sh
# Description : Fast ICMP ping sweep across an IPv4 /24 subnet using parallel
#               background subshells to locate active hosts and reverse DNS.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, ping
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SUBNET="192.168.1"
TIMEOUT=1

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Performs a high-speed parallel ping sweep across a /24 subnet.

Options:
  -s, --subnet <prefix>   Subnet base address (default: 192.168.1)
  -t, --timeout <sec>     Ping timeout per host in seconds (default: 1)
  -h, --help              Show this help message and exit

Example:
  $(basename "$0") -s 10.0.0 -t 1
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--subnet)
            SUBNET="$2"; shift 2 ;;
        -t|--timeout)
            TIMEOUT="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Fast Parallel Subnet Ping Sweep - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"
echo -e "Sweeping Subnet Range: ${SUBNET}.1 - ${SUBNET}.254 (Timeout: ${TIMEOUT}s)...\n"

TMP_RESULTS=$(mktemp)
trap 'rm -f "$TMP_RESULTS"' EXIT INT TERM

# Launch 254 pings in background
for ip in $(seq 1 254); do
    target="${SUBNET}.${ip}"
    (
        if ping -c 1 -W "$TIMEOUT" "$target" &>/dev/null; then
            host=$(getent hosts "$target" 2>/dev/null | awk '{print $2}' || echo "unresolved")
            echo "$target ($host)" >> "$TMP_RESULTS"
        fi
    ) &
done

# Wait for subshells to complete
wait

if [[ ! -s "$TMP_RESULTS" ]]; then
    echo -e "${YELLOW}[NOTICE] No active hosts responded on ${SUBNET}.0/24.${NC}"
    exit 0
fi

ACTIVE_COUNT=$(wc -l < "$TMP_RESULTS")
echo -e "${GREEN}[SUCCESS] Discovered ${ACTIVE_COUNT} active host(s):${NC}\n"
sort -V "$TMP_RESULTS" | while read -r line; do
    echo -e "  ${GREEN}[ONLINE]${NC} $line"
done

exit 0
