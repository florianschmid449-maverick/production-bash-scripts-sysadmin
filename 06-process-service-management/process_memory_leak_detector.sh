#!/usr/bin/env bash
# ==============================================================================
# Script Name : process_memory_leak_detector.sh
# Description : Samples Resident Set Size (RSS) memory consumption of a daemon
#               over time, detecting creeping upward memory leaks.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, ps, awk
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

TARGET_PID=""
SAMPLES=3
INTERVAL=2

usage() {
    cat <<EOF
Usage: $(basename "$0") -p <pid> [OPTIONS]

Samples RSS memory over time to detect progressive memory expansion.

Options:
  -p, --pid <pid>        Target Process ID to inspect
  -s, --samples <num>    Number of samples to take (default: 3)
  -i, --interval <sec>   Delay interval between samples (default: 2)
  -h, --help             Show this help message and exit

Example:
  $(basename "$0") -p 1234 -s 5 -i 3
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--pid)
            TARGET_PID="$2"; shift 2 ;;
        -s|--samples)
            SAMPLES="$2"; shift 2 ;;
        -i|--interval)
            INTERVAL="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

if [[ -z "$TARGET_PID" || ! -d "/proc/$TARGET_PID" ]]; then
    echo -e "${RED}[ERROR] Valid active Process ID (-p) required.${NC}" >&2
    exit 2
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Progressive Process Memory Leak Detector - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

CMD=$(ps -p "$TARGET_PID" -o comm= 2>/dev/null || echo "unknown")
echo -e "Tracking PID ${TARGET_PID} (${CMD}) across ${SAMPLES} samples (${INTERVAL}s delay)...\n"

declare -a RSS_VALUES=()

for ((i = 1; i <= SAMPLES; i++)); do
    rss_kb=$(ps -p "$TARGET_PID" -o rss= 2>/dev/null | xargs || echo 0)
    RSS_VALUES+=("$rss_kb")
    mb=$(awk -v k="$rss_kb" 'BEGIN { printf "%.2f MB", k / 1024 }')
    echo -e "  Sample ${i}/${SAMPLES}: RSS = ${mb}"

    if [[ "$i" -lt "$SAMPLES" ]]; then
        sleep "$INTERVAL"
    fi
done

FIRST="${RSS_VALUES[0]}"
LAST="${RSS_VALUES[-1]}"
GROWTH=$((LAST - FIRST))

echo -e "\nMemory Leak Analysis:"
if [[ "$GROWTH" -gt 5120 ]]; then # grew more than 5MB
    GROWTH_MB=$(awk -v g="$GROWTH" 'BEGIN { printf "%.2f MB", g / 1024 }')
    echo -e "  ${RED}[LEAK DETECTED] Process expanded by +${GROWTH_MB} across sample window!${NC}"
else
    echo -e "  ${GREEN}[STABLE] Memory footprint is stable or within baseline variance.${NC}"
fi

exit 0
