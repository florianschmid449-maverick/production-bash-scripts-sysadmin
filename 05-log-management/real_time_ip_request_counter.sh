#!/usr/bin/env bash
# ==============================================================================
# Script Name : real_time_ip_request_counter.sh
# Description : Tails active web server access logs in real-time, aggregating
#               request volumes per client IP to spot Layer 7 DDoS and scrapers.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, tail, awk
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

LOG_FILE="/var/log/nginx/access.log"
SAMPLE_LINES=200

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Samples recent access log stream to detect aggressive client IP request rates.

Options:
  -f, --file <path>    Log file to tail/sample (default: /var/log/nginx/access.log)
  -n, --lines <count>  Number of recent log lines to sample (default: 200)
  -h, --help           Show this help message and exit

Example:
  $(basename "$0") -f /var/log/nginx/access.log -n 500
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--file)
            LOG_FILE="$2"; shift 2 ;;
        -n|--lines)
            SAMPLE_LINES="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Real-Time Client IP Request Rate Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if [[ ! -f "$LOG_FILE" || ! -r "$LOG_FILE" ]]; then
    echo -e "${YELLOW}[NOTICE] Log file '${LOG_FILE}' not accessible.${NC}"
    echo -e "${CYAN}[INFO] Provide a readable web access log with -f <file>.${NC}"
    exit 0
fi

echo -e "Sampling last ${SAMPLE_LINES} lines from ${LOG_FILE}...\n"
printf "%-10s %-20s %-25s\n" "REQUESTS" "CLIENT IP" "RATE EVALUATION"
printf "%-10s %-20s %-25s\n" "--------" "---------" "---------------"

tail -n "$SAMPLE_LINES" "$LOG_FILE" | awk '{print $1}' | sort | uniq -c | sort -rn | head -n 10 | while read -r count ip; do
    if [[ "$count" -ge 50 ]]; then
        eval_str="${RED}HIGH FREQUENCY / SCRAPER${NC}"
    elif [[ "$count" -ge 20 ]]; then
        eval_str="${YELLOW}MODERATE ACTIVITY${NC}"
    else
        eval_str="${GREEN}NORMAL BROWSER${NC}"
    fi

    printf "%-10s %-20s " "$count" "$ip"
    echo -e "$eval_str"
done

exit 0
