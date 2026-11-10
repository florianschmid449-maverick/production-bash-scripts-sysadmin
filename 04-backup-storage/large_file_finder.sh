#!/usr/bin/env bash
# ==============================================================================
# Script Name : large_file_finder.sh
# Description : Traverses directory trees to locate files exceeding a minimum size
#               threshold (e.g. 100MB), sorted in descending order of size.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, find, sort
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SEARCH_DIR="/"
MIN_SIZE="100M"
TOP_COUNT=10

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Finds largest files exceeding threshold in specified directory.

Options:
  -d, --dir <path>     Directory to search (default: /)
  -s, --size <size>    Minimum file size threshold (default: 100M)
  -n, --count <num>    Number of top files to display (default: 10)
  -h, --help           Show this help message and exit

Example:
  $(basename "$0") -d /var/log -s 50M -n 5
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dir)
            SEARCH_DIR="$2"; shift 2 ;;
        -s|--size)
            MIN_SIZE="$2"; shift 2 ;;
        -n|--count)
            TOP_COUNT="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Large File Resource Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"
echo -e "Searching '${SEARCH_DIR}' for files > ${MIN_SIZE}...\n"

printf "%-12s %-15s %-40s\n" "SIZE" "OWNER" "FILE PATH"
printf "%-12s %-15s %-40s\n" "----" "-----" "---------"

find "$SEARCH_DIR" \( -path /proc -o -path /sys -o -path /dev \) -prune -o \
    -type f -size +"$MIN_SIZE" -exec ls -lh {} + 2>/dev/null | \
    sort -k5 -hr | head -n "$TOP_COUNT" | while read -r line; do
    sz=$(echo "$line" | awk '{print $5}')
    owner=$(echo "$line" | awk '{print $3":"$4}')
    filepath=$(echo "$line" | awk '{print $9}')
    printf "%-12s %-15s %-40s\n" "$sz" "$owner" "$filepath"
done

exit 0
