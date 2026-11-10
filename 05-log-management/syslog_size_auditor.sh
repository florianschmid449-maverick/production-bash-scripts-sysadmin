#!/usr/bin/env bash
# ==============================================================================
# Script Name : syslog_size_auditor.sh
# Description : Samples file sizes across /var/log to detect runaway log files
#               growing excessively and threatening partition capacity.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, find, stat
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

LOG_DIR="/var/log"
MAX_SIZE_MB=500

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Audits log directory for excessively large or runaway log files.

Options:
  -d, --dir <path>       Log directory to inspect (default: /var/log)
  -s, --size-mb <int>    Size alert threshold in Megabytes (default: 500)
  -h, --help             Show this help message and exit

Example:
  sudo $(basename "$0") -d /var/log -s 100
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dir)
            LOG_DIR="$2"; shift 2 ;;
        -s|--size-mb)
            MAX_SIZE_MB="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} System Log Partition Size Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"
echo -e "Auditing '${LOG_DIR}' for files exceeding ${MAX_SIZE_MB} MB...\n"

if [[ ! -d "$LOG_DIR" ]]; then
    echo -e "${RED}[ERROR] Directory '${LOG_DIR}' does not exist.${NC}" >&2
    exit 1
fi

LARGE_LOGS=$(find "$LOG_DIR" -type f -size +"${MAX_SIZE_MB}M" -exec ls -lh {} + 2>/dev/null || true)

if [[ -z "$LARGE_LOGS" ]]; then
    echo -e "${GREEN}[OK] No log files exceed ${MAX_SIZE_MB} MB in ${LOG_DIR}.${NC}"
else
    echo -e "${RED}[ALERT] Found oversized log files:${NC}\n"
    echo "$LARGE_LOGS" | awk '{print $5, $9}' | while read -r sz path; do
        echo -e "  ${RED}${sz}${NC} -> ${path}"
    done
fi

exit 0
