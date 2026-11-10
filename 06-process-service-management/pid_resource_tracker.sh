#!/usr/bin/env bash
# ==============================================================================
# Script Name : pid_resource_tracker.sh
# Description : Tracks CPU%, RSS memory, thread count, and open file descriptors
#               for a designated PID over time, outputting formatted live metrics.
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
COUNT=5
INTERVAL=1

usage() {
    cat <<EOF
Usage: $(basename "$0") -p <pid> [OPTIONS]

Tracks live CPU, RAM, threads, and open file descriptors for a specific PID.

Options:
  -p, --pid <pid>        Process ID to monitor
  -c, --count <num>      Number of observations to record (default: 5)
  -i, --interval <sec>   Interval between checks in seconds (default: 1)
  -h, --help             Show this help message and exit

Example:
  $(basename "$0") -p 1234 -c 10 -i 2
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--pid)
            TARGET_PID="$2"; shift 2 ;;
        -c|--count)
            COUNT="$2"; shift 2 ;;
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
    echo -e "${RED}[ERROR] Valid running Process ID (-p) required.${NC}" >&2
    exit 2
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Process Resource & Descriptor Tracker - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

CMD=$(ps -p "$TARGET_PID" -o comm= 2>/dev/null || echo "unknown")
echo -e "Monitoring Target: PID ${TARGET_PID} (${CMD})\n"

printf "%-8s %-10s %-12s %-10s %-12s\n" "SAMPLE" "CPU %" "RSS RAM" "THREADS" "OPEN FDS"
printf "%-8s %-10s %-12s %-10s %-12s\n" "------" "-----" "-------" "-------" "--------"

for ((i = 1; i <= COUNT; i++)); do
    if [[ ! -d "/proc/$TARGET_PID" ]]; then
        echo -e "${RED}[TERMINATED] Process exited.${NC}"
        break
    fi

    cpu=$(ps -p "$TARGET_PID" -o %cpu= 2>/dev/null | xargs || echo 0)
    rss_kb=$(ps -p "$TARGET_PID" -o rss= 2>/dev/null | xargs || echo 0)
    threads=$(ps -p "$TARGET_PID" -o nlwp= 2>/dev/null | xargs || echo 1)
    fds=$(ls "/proc/$TARGET_PID/fd" 2>/dev/null | wc -l || echo 0)

    rss_mb=$(awk -v k="$rss_kb" 'BEGIN { printf "%.1f MB", k / 1024 }')
    printf "%-8s %-10s %-12s %-10s %-12s\n" "$i" "${cpu}%" "$rss_mb" "$threads" "$fds"

    if [[ "$i" -lt "$COUNT" ]]; then
        sleep "$INTERVAL"
    fi
done

exit 0
