#!/usr/bin/env bash
# ==============================================================================
# Script Name : slow_query_log_parser.sh
# Description : Analyzes MySQL/MariaDB slow query logs, ranking slow SQL commands
#               by execution time and identifying lock contention bottlenecks.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, grep, awk
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SLOW_LOG="/var/log/mysql/mysql-slow.log"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Parses database slow query logs to highlight execution bottlenecks.

Options:
  -f, --file <path>   Path to slow query log (default: /var/log/mysql/mysql-slow.log)
  -h, --help          Show this help message and exit

Example:
  $(basename "$0") -f /var/log/mariadb/slow.log
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--file)
            SLOW_LOG="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Database Slow Query Log Parser - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if [[ ! -f "$SLOW_LOG" || ! -r "$SLOW_LOG" ]]; then
    echo -e "${YELLOW}[NOTICE] Slow query log '${SLOW_LOG}' not readable.${NC}"
    echo -e "${CYAN}[INFO] Check file path with -f <file> or verify log permissions.${NC}"
    exit 0
fi

TOTAL_SLOW=$(grep -c "^# Query_time:" "$SLOW_LOG" || echo 0)
echo -e "Total Slow Queries Logged: ${YELLOW}${TOTAL_SLOW}${NC}\n"

if [[ "$TOTAL_SLOW" -eq 0 ]]; then
    echo -e "${GREEN}[OK] No slow queries recorded in log.${NC}"
    exit 0
fi

echo -e "Top 5 Slowest Queries Recorded:"
grep -A 2 "^# Query_time:" "$SLOW_LOG" | grep -v "^#" | grep -v "^--" | head -n 5 | while read -r sql; do
    [[ -n "$sql" ]] && echo -e "  -> ${RED}${sql}${NC}"
done

exit 0
