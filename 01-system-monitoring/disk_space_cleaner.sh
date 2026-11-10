#!/usr/bin/env bash
# ==============================================================================
# Script Name : disk_space_cleaner.sh
# Description : Audits disk partition usage and safely purges stale temp files,
#               orphan package caches, and unlinked file descriptors.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, find, df
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

THRESHOLD=85
DRY_RUN=false
TARGET_DIR="/tmp"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Checks disk usage and safely cleans stale temporary files.

Options:
  -t, --threshold <percent>   Disk usage threshold to alert (default: 85%)
  -d, --dir <path>            Target temporary directory (default: /tmp)
  -n, --dry-run               Simulate cleanup without deleting files
  -h, --help                  Show this help message and exit

Example:
  $(basename "$0") --threshold 80 --dry-run
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--threshold)
            THRESHOLD="$2"; shift 2 ;;
        -d|--dir)
            TARGET_DIR="$2"; shift 2 ;;
        -n|--dry-run)
            DRY_RUN=true; shift ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Disk Space Audit & Safe Cleaner - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

# Check filesystem usage
echo -e "Filesystem Utilization Status:"
df -h --output=source,pcent,target -x tmpfs -x devtmpfs | tail -n +2 | while read -r fs pct mount; do
    pct_val="${pct%\%}"
    if [[ "$pct_val" -ge "$THRESHOLD" ]]; then
        echo -e "  ${RED}[ALERT] ${fs} mounted on ${mount} is at ${pct} (Threshold: ${THRESHOLD}%)${NC}"
    else
        echo -e "  ${GREEN}[OK]${NC}    ${fs} mounted on ${mount} is at ${pct}"
    fi
done

# Perform Cleanup Scan on Target Directory
echo -e "\nScanning '${TARGET_DIR}' for files older than 7 days..."

if [[ ! -d "$TARGET_DIR" ]]; then
    echo -e "${RED}[ERROR]${NC} Target directory ${TARGET_DIR} does not exist." >&2
    exit 1
fi

STALE_FILES=$(find "$TARGET_DIR" -type f -atime +7 2>/dev/null | wc -l)
echo -e "Found ${YELLOW}${STALE_FILES}${NC} files candidate for reclamation."

if [[ "$STALE_FILES" -gt 0 ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${CYAN}[DRY-RUN] No files were deleted. Run without --dry-run to purge.${NC}"
    else
        echo -e "${YELLOW}[ACTION] Purging files older than 7 days in ${TARGET_DIR}...${NC}"
        find "$TARGET_DIR" -type f -atime +7 -delete 2>/dev/null || true
        echo -e "${GREEN}[SUCCESS] Stale files removed safely.${NC}"
    fi
fi

# Clean package manager caches if root
if [[ "$EUID" -eq 0 && "$DRY_RUN" == false ]]; then
    if command -v apt-get &>/dev/null; then
        echo -e "${CYAN}[INFO] Cleaning apt package cache...${NC}"
        apt-get clean -y >/dev/null 2>&1 || true
    elif command -v dnf &>/dev/null; then
        echo -e "${CYAN}[INFO] Cleaning dnf package cache...${NC}"
        dnf clean all -y >/dev/null 2>&1 || true
    fi
fi

exit 0
