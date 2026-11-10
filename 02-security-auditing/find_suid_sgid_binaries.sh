#!/usr/bin/env bash
# ==============================================================================
# Script Name : find_suid_sgid_binaries.sh
# Description : Scans filesystems for binaries with SUID/SGID execution bits set.
#               Identifies potential privilege escalation targets.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, find
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCAN_PATH="/"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Finds all SUID and SGID executables across the filesystem.

Options:
  -p, --path <dir>   Root directory to start scan from (default: /)
  -h, --help         Show this help message and exit

Example:
  sudo $(basename "$0") -p /usr
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--path)
            SCAN_PATH="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} SUID & SGID Privilege Escalation Scanner - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"
echo -e "Scanning '${SCAN_PATH}' (skipping /proc, /sys, /dev)...\n"

# Search physical paths only
find "$SCAN_PATH" \( -path /proc -o -path /sys -o -path /dev \) -prune -o \
    -type f \( -perm -4000 -o -perm -2000 \) -exec ls -ld {} + 2>/dev/null | while read -r line; do
    perms=$(echo "$line" | awk '{print $1}')
    owner=$(echo "$line" | awk '{print $3":"$4}')
    binary=$(echo "$line" | awk '{print $9}')

    if [[ "$perms" =~ s ]]; then
        echo -e "${RED}[SUID]${NC} ${perms} ${owner} ${binary}"
    else
        echo -e "${YELLOW}[SGID]${NC} ${perms} ${owner} ${binary}"
    fi
done

echo -e "\n${GREEN}[SUCCESS] Scan completed.${NC}"
exit 0
