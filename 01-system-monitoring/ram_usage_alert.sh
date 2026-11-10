#!/usr/bin/env bash
# ==============================================================================
# Script Name : ram_usage_alert.sh
# Description : Calculates real memory usage and swap pressure from /proc/meminfo.
#               Emits alerts and isolates top memory-consuming processes.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, procps, awk
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

THRESHOLD=85
CHECK_SWAP=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Monitors physical RAM and swap memory consumption.

Options:
  -t, --threshold <percent>   Memory usage alert threshold (default: 85%)
  -s, --swap                  Also evaluate swap space utilization
  -h, --help                  Show this help message and exit

Example:
  $(basename "$0") -t 80 --swap
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--threshold)
            THRESHOLD="$2"; shift 2 ;;
        -s|--swap)
            CHECK_SWAP=true; shift ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

# Parse /proc/meminfo for accurate calculations (respecting buffers/cache)
MEM_TOTAL=$(grep -m1 '^MemTotal:' /proc/meminfo | awk '{print $2}')
MEM_AVAIL=$(grep -m1 '^MemAvailable:' /proc/meminfo | awk '{print $2}')
SWAP_TOTAL=$(grep -m1 '^SwapTotal:' /proc/meminfo | awk '{print $2}')
SWAP_FREE=$(grep -m1 '^SwapFree:' /proc/meminfo | awk '{print $2}')

# Calculate percentages
MEM_USED=$((MEM_TOTAL - MEM_AVAIL))
MEM_USED_PCT=$(awk -v u="$MEM_USED" -v t="$MEM_TOTAL" 'BEGIN { printf "%.1f", (u / t) * 100 }')
MEM_USED_INT=$(awk -v p="$MEM_USED_PCT" 'BEGIN { printf "%.0f", p }')

# Formatting megabytes
MEM_TOTAL_MB=$((MEM_TOTAL / 1024))
MEM_USED_MB=$((MEM_USED / 1024))
MEM_AVAIL_MB=$((MEM_AVAIL / 1024))

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} RAM & Memory Pressure Monitor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"
echo -e "Total Physical RAM : ${MEM_TOTAL_MB} MB"
echo -e "Used RAM (Active)  : ${MEM_USED_MB} MB (${MEM_USED_PCT}%)"
echo -e "Available RAM      : ${MEM_AVAIL_MB} MB"

if [[ "$MEM_USED_INT" -ge "$THRESHOLD" ]]; then
    echo -e "${RED}[CRITICAL ALERT] RAM usage is at ${MEM_USED_PCT}% (Threshold: ${THRESHOLD}%)${NC}"
    echo -e "\n${YELLOW}[WARN] Top 5 Memory-Consuming Processes:${NC}"
    ps -eo pid,user,%mem,rss,comm --sort=-rss | head -n 6
else
    echo -e "${GREEN}[OK] RAM utilization is within safe operational limits.${NC}"
fi

# Optional swap audit
if [[ "$CHECK_SWAP" == true && "$SWAP_TOTAL" -gt 0 ]]; then
    SWAP_USED=$((SWAP_TOTAL - SWAP_FREE))
    SWAP_PCT=$(awk -v u="$SWAP_USED" -v t="$SWAP_TOTAL" 'BEGIN { printf "%.1f", (u / t) * 100 }')
    echo -e "\nSwap Total : $((SWAP_TOTAL / 1024)) MB | Used: $((SWAP_USED / 1024)) MB (${SWAP_PCT}%)"
fi

exit 0
