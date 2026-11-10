#!/usr/bin/env bash
# ==============================================================================
# Script Name : swap_monitor.sh
# Description : Identifies which specific processes are consuming swap space
#               by parsing /proc/[pid]/smaps or status files.
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

TOP_COUNT=10

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Ranks active processes by swap space consumption in Megabytes.

Options:
  -n, --top <count>    Number of top processes to display (default: 10)
  -h, --help           Show this help message and exit

Example:
  $(basename "$0") -n 5
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--top)
            TOP_COUNT="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Process Swap Space Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

# Ensure /proc is available
if [[ ! -d /proc ]]; then
    echo -e "${RED}[ERROR]${NC} /proc filesystem is not mounted." >&2
    exit 1
fi

TMP_FILE=$(mktemp)
trap 'rm -f "$TMP_FILE"' EXIT INT TERM

# Scan all running process status files for VmSwap
for status_file in /proc/[0-9]*/status; do
    if [[ -r "$status_file" ]]; then
        pid=$(basename "$(dirname "$status_file")")
        swap_kb=$(grep -s 'VmSwap:' "$status_file" | awk '{print $2}' || true)
        if [[ -n "$swap_kb" && "$swap_kb" -gt 0 ]]; then
            cmd=$(ps -p "$pid" -o comm= 2>/dev/null || cat "/proc/$pid/cmdline" 2>/dev/null | tr '\0' ' ' || echo "unknown")
            echo "$swap_kb $pid $cmd" >> "$TMP_FILE"
        fi
    fi
done

if [[ ! -s "$TMP_FILE" ]]; then
    echo -e "${GREEN}[OK] No processes are currently consuming swap space.${NC}"
    exit 0
fi

echo -e "Top ${TOP_COUNT} processes using swap memory:\n"
printf "%-12s %-10s %-30s\n" "SWAP USED" "PID" "COMMAND"
printf "%-12s %-10s %-30s\n" "---------" "---" "-------"

sort -rn "$TMP_FILE" | head -n "$TOP_COUNT" | while read -r kb pid cmd; do
    mb=$(awk -v k="$kb" 'BEGIN { printf "%.2f MB", k / 1024 }')
    printf "%-12s %-10s %-30s\n" "$mb" "$pid" "$cmd"
done

exit 0
