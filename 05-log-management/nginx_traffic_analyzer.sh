#!/usr/bin/env bash
# ==============================================================================
# Script Name : nginx_traffic_analyzer.sh
# Description : Parses Nginx access logs to report top requesting client IPs,
#               frequent request URIs, HTTP status code distributions, and bots.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, awk, sort, uniq
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
TOP_N=10

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Parses web server access logs to extract traffic profiles and client patterns.

Options:
  -f, --file <log_path>   Path to access log file (default: /var/log/nginx/access.log)
  -n, --top <count>       Number of top entries to show (default: 10)
  -h, --help              Show this help message and exit

Example:
  $(basename "$0") -f /var/log/nginx/access.log -n 5
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--file)
            LOG_FILE="$2"; shift 2 ;;
        -n|--top)
            TOP_N="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Nginx Web Traffic & Access Log Analyzer - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if [[ ! -f "$LOG_FILE" || ! -r "$LOG_FILE" ]]; then
    echo -e "${YELLOW}[NOTICE] Log file '${LOG_FILE}' not accessible.${NC}"
    echo -e "${CYAN}[INFO] Please specify a valid log with -f <file>.${NC}"
    exit 0
fi

TOTAL_REQUESTS=$(wc -l < "$LOG_FILE")
echo -e "Total Requests Parsed: ${GREEN}${TOTAL_REQUESTS}${NC}\n"

echo -e "${YELLOW}Top ${TOP_N} Client IP Addresses:${NC}"
awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -rn | head -n "$TOP_N" | awk '{printf "  %8d requests -> %s\n", $1, $2}'

echo -e "\n${YELLOW}Top ${TOP_N} Requested URIs:${NC}"
awk '{print $7}' "$LOG_FILE" | sort | uniq -c | sort -rn | head -n "$TOP_N" | awk '{printf "  %8d hits -> %s\n", $1, $2}'

echo -e "\n${YELLOW}HTTP Status Code Distribution:${NC}"
awk '{print $9}' "$LOG_FILE" | grep -E "^[0-9]{3}$" | sort | uniq -c | sort -rn | while read -r count code; do
    if [[ "$code" =~ ^2 ]]; then
        echo -e "  ${GREEN}HTTP ${code}${NC} : ${count} responses"
    elif [[ "$code" =~ ^[45] ]]; then
        echo -e "  ${RED}HTTP ${code}${NC} : ${count} responses"
    else
        echo -e "  ${CYAN}HTTP ${code}${NC} : ${count} responses"
    fi
done

exit 0
