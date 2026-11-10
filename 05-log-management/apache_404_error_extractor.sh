#!/usr/bin/env bash
# ==============================================================================
# Script Name : apache_404_error_extractor.sh
# Description : Filters web access logs for HTTP 404 responses, identifying broken
#               internal links and malicious directory vulnerability probes.
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

LOG_PATH="/var/log/apache2/access.log"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Extracts and aggregates HTTP 404 (Not Found) errors from web access logs.

Options:
  -f, --file <log>   Access log path (default: /var/log/apache2/access.log)
  -h, --help         Show this help message and exit

Example:
  $(basename "$0") -f /var/log/httpd/access_log
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--file)
            LOG_PATH="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} HTTP 404 Broken Link & Web Probe Extractor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if [[ ! -f "$LOG_PATH" || ! -r "$LOG_PATH" ]]; then
    echo -e "${YELLOW}[NOTICE] Log file '${LOG_PATH}' is not readable.${NC}"
    echo -e "${CYAN}[INFO] Provide a valid web server log with -f <file>.${NC}"
    exit 0
fi

TOTAL_404=$(awk '$9 == "404"' "$LOG_PATH" | wc -l)
echo -e "Total 404 Errors Found: ${RED}${TOTAL_404}${NC}\n"

if [[ "$TOTAL_404" -eq 0 ]]; then
    echo -e "${GREEN}[OK] Zero 404 responses recorded in this log.${NC}"
    exit 0
fi

echo -e "${YELLOW}Top 10 Missing / Probed URLs:${NC}"
awk '$9 == "404" {print $7}' "$LOG_PATH" | sort | uniq -c | sort -rn | head -n 10 | awk '{printf "  %8d requests -> %s\n", $1, $2}'

echo -e "\n${YELLOW}Top 10 IP Addresses Generating 404s (Potential Scanners):${NC}"
awk '$9 == "404" {print $1}' "$LOG_PATH" | sort | uniq -c | sort -rn | head -n 10 | awk '{printf "  %8d requests -> %s\n", $1, $2}'

exit 0
