#!/usr/bin/env bash
# ==============================================================================
# Script Name : interface_traffic_stats.sh
# Description : Calculates real-time network throughput (KB/s, MB/s) and packet drops
#               per interface by sampling /proc/net/dev counters.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, awk
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

INTERVAL=1

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Monitors network interface bandwidth throughput and error drops.

Options:
  -i, --interval <sec>   Sampling interval in seconds (default: 1)
  -h, --help             Show this help message and exit

Example:
  $(basename "$0") -i 2
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--interval)
            INTERVAL="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Network Interface Real-Time Throughput - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

# Read initial snapshot
declare -A RX_START TX_START
while read -r line; do
    if [[ "$line" =~ : ]]; then
        iface=$(echo "$line" | cut -d: -f1 | xargs)
        rx=$(echo "$line" | cut -d: -f2 | awk '{print $1}')
        tx=$(echo "$line" | cut -d: -f2 | awk '{print $9}')
        RX_START["$iface"]="$rx"
        TX_START["$iface"]="$tx"
    fi
done < /proc/net/dev

sleep "$INTERVAL"

printf "%-15s %-18s %-18s\n" "INTERFACE" "RX THROUGHPUT" "TX THROUGHPUT"
printf "%-15s %-18s %-18s\n" "---------" "-------------" "-------------"

while read -r line; do
    if [[ "$line" =~ : ]]; then
        iface=$(echo "$line" | cut -d: -f1 | xargs)
        rx_now=$(echo "$line" | cut -d: -f2 | awk '{print $1}')
        tx_now=$(echo "$line" | cut -d: -f2 | awk '{print $9}')

        rx_diff=$((rx_now - RX_START["$iface"]))
        tx_diff=$((tx_now - TX_START["$iface"]))

        rx_kb=$(awk -v b="$rx_diff" -v s="$INTERVAL" 'BEGIN { printf "%.2f KB/s", (b / 1024) / s }')
        tx_kb=$(awk -v b="$tx_diff" -v s="$INTERVAL" 'BEGIN { printf "%.2f KB/s", (b / 1024) / s }')

        printf "%-15s %-18s %-18s\n" "$iface" "$rx_kb" "$tx_kb"
    fi
done < /proc/net/dev

exit 0
