#!/usr/bin/env bash
# ==============================================================================
# Script Name : inode_usage_checker.sh
# Description : Detects filesystem inode exhaustion and pinpoints directories
#               accumulating excessive micro-files or session caches.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, df, find
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

THRESHOLD=80
CHECK_PATH=""

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Checks inode allocation across mounted filesystems and scans directory hotspots.

Options:
  -t, --threshold <percent>   Inode usage alert threshold (default: 80%)
  -p, --path <dir>            Specific path to scan for top inode-consuming folders
  -h, --help                  Show this help message and exit

Example:
  $(basename "$0") -t 75 -p /var/spool
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--threshold)
            THRESHOLD="$2"; shift 2 ;;
        -p|--path)
            CHECK_PATH="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Filesystem Inode Usage Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

ALERT_TRIGGERED=false

# Inspect Inodes across all active filesystems
while read -r fs inodes iused ifree ipct mount; do
    pct_val="${ipct%\%}"
    # Filter header line or invalid rows
    if [[ ! "$pct_val" =~ ^[0-9]+$ ]]; then
        continue
    fi

    if [[ "$pct_val" -ge "$THRESHOLD" ]]; then
        ALERT_TRIGGERED=true
        echo -e "${RED}[CRITICAL INODE EXHAUSTION]${NC} ${mount} (${fs}): ${ipct} used (${iused}/${inodes})"
        if [[ -z "$CHECK_PATH" ]]; then
            CHECK_PATH="$mount"
        fi
    else
        echo -e "${GREEN}[OK]${NC} ${mount} (${fs}): ${ipct} used (${iused}/${inodes})"
    fi
done < <(df -i -x tmpfs -x devtmpfs 2>/dev/null | tail -n +2)

# If a hotspot path is identified or specified, display top 5 directories with most files
if [[ -n "$CHECK_PATH" && -d "$CHECK_PATH" ]]; then
    echo -e "\n${YELLOW}[INFO] Pinpointing top file-count directories under '${CHECK_PATH}'...${NC}"
    find "$CHECK_PATH" -maxdepth 2 -type d 2>/dev/null | while read -r dir; do
        count=$(find "$dir" -maxdepth 1 -type f 2>/dev/null | wc -l)
        echo "$count $dir"
    done | sort -rn | head -n 5 | awk '{printf "  %8d files -> %s\n", $1, $2}'
fi

if [[ "$ALERT_TRIGGERED" == true ]]; then
    exit 1
fi

exit 0
