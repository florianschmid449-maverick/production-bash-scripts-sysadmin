#!/usr/bin/env bash
# ==============================================================================
# Script Name : top_process_logger.sh
# Description : Records periodic CSV snapshots of highest CPU and memory-consuming
#               processes for offline trend troubleshooting.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, procps
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

OUTPUT_CSV="/tmp/top_processes_snapshot.csv"
ITERATIONS=1
INTERVAL=2

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Captures periodic snapshots of top resource-consuming processes to CSV.

Options:
  -o, --output <file>     Destination CSV file path (default: /tmp/top_processes_snapshot.csv)
  -n, --iterations <num>  Number of snapshot samples to collect (default: 1)
  -i, --interval <sec>    Delay interval in seconds between samples (default: 2)
  -h, --help              Show this help message and exit

Example:
  $(basename "$0") -o /var/log/process_spikes.csv -n 5 -i 10
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output)
            OUTPUT_CSV="$2"; shift 2 ;;
        -n|--iterations)
            ITERATIONS="$2"; shift 2 ;;
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
echo -e "${CYAN} Top Process Resource Logger - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"
echo -e "Logging ${ITERATIONS} snapshot(s) to: ${OUTPUT_CSV}"

# Ensure output header exists
if [[ ! -f "$OUTPUT_CSV" ]]; then
    echo "timestamp,rank,pid,user,cpu_pct,mem_pct,command" > "$OUTPUT_CSV"
fi

for ((i = 1; i <= ITERATIONS; i++)); do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${CYAN}[INFO] Capturing snapshot ${i}/${ITERATIONS} at ${TIMESTAMP}...${NC}"

    rank=1
    ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | tail -n +2 | head -n 5 | while read -r pid user cpu mem comm; do
        echo "${TIMESTAMP},${rank},${pid},${user},${cpu},${mem},\"${comm}\"" >> "$OUTPUT_CSV"
        rank=$((rank + 1))
    done

    if [[ "$i" -lt "$ITERATIONS" ]]; then
        sleep "$INTERVAL"
    fi
done

echo -e "${GREEN}[SUCCESS] Logged snapshots to ${OUTPUT_CSV}.${NC}"
exit 0
