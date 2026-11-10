#!/usr/bin/env bash
# ==============================================================================
# Script Name : dmesg_error_watch.sh
# Description : Scans kernel ring buffer for critical hardware errors,
#               I/O storage timeouts, OOM kills, and machine check exceptions.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, dmesg, grep
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

LINES=50

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Scans kernel buffer messages for errors, panics, and hardware degradation.

Options:
  -n, --lines <count>   Number of recent matching lines to evaluate (default: 50)
  -h, --help            Show this help message and exit

Example:
  $(basename "$0") -n 100
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--lines)
            LINES="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Kernel Ring Buffer Error Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

# Check for dmesg command
if ! command -v dmesg &>/dev/null; then
    echo -e "${RED}[ERROR]${NC} 'dmesg' utility not found." >&2
    exit 1
fi

# Define critical search patterns
PATTERNS="error|failed|oom-killer|Out of memory|I/O error|kernel BUG|segfault|Hardware Error|corrupt"

ERRORS=$(dmesg -T 2>/dev/null | grep -E -i "$PATTERNS" | tail -n "$LINES" || true)

if [[ -z "$ERRORS" ]]; then
    echo -e "${GREEN}[OK] No critical hardware or kernel error patterns found in recent buffer.${NC}"
    exit 0
fi

echo -e "${YELLOW}[ALERT] Recent kernel alerts and errors detected:${NC}\n"
echo "$ERRORS" | while read -r line; do
    if echo "$line" | grep -E -i "oom|killed|hardware error|bug" >/dev/null; then
        echo -e "${RED}${line}${NC}"
    else
        echo -e "${YELLOW}${line}${NC}"
    fi
done

exit 0
