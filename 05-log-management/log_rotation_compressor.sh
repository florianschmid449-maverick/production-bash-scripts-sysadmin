#!/usr/bin/env bash
# ==============================================================================
# Script Name : log_rotation_compressor.sh
# Description : Manually compresses uncompressed .log files older than N days into
#               .gz archives and purges archives older than a maximum retention age.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, gzip, find
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

TARGET_DIR=""
COMPRESS_DAYS=3
PURGE_DAYS=30
DRY_RUN=false

usage() {
    cat <<EOF
Usage: $(basename "$0") -d <log_dir> [OPTIONS]

Compresses old log files and prunes obsolete compressed archives.

Options:
  -d, --dir <path>       Directory containing log files to process
  -c, --compress <days>  Compress .log files older than N days (default: 3)
  -p, --purge <days>     Delete compressed .gz files older than N days (default: 30)
  -n, --dry-run          Simulate actions without compressing or deleting
  -h, --help             Show this help message and exit

Example:
  $(basename "$0") -d /var/log/custom_app -c 2 -p 14 --dry-run
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dir)
            TARGET_DIR="$2"; shift 2 ;;
        -c|--compress)
            COMPRESS_DAYS="$2"; shift 2 ;;
        -p|--purge)
            PURGE_DAYS="$2"; shift 2 ;;
        -n|--dry-run)
            DRY_RUN=true; shift ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

if [[ -z "$TARGET_DIR" || ! -d "$TARGET_DIR" ]]; then
    echo -e "${RED}[ERROR] Valid log directory (-d) required.${NC}" >&2
    exit 2
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Log File Compression & Archival Rotation - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

# Step 1: Compress uncompressed .log files older than COMPRESS_DAYS
echo -e "Checking for uncompressed .log files older than ${COMPRESS_DAYS} days..."
find "$TARGET_DIR" -maxdepth 2 -type f -name "*.log" -mtime +"$COMPRESS_DAYS" | while read -r log_file; do
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${CYAN}[DRY-RUN WOULD COMPRESS]${NC} $(basename "$log_file")"
    else
        echo -e "  ${YELLOW}[COMPRESSING]${NC} $(basename "$log_file")..."
        gzip "$log_file"
    fi
done

# Step 2: Purge .gz files older than PURGE_DAYS
echo -e "\nChecking for archived .gz logs older than ${PURGE_DAYS} days..."
find "$TARGET_DIR" -maxdepth 2 -type f -name "*.gz" -mtime +"$PURGE_DAYS" | while read -r gz_file; do
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${CYAN}[DRY-RUN WOULD DELETE]${NC} $(basename "$gz_file")"
    else
        echo -e "  ${RED}[PURGING]${NC} $(basename "$gz_file")"
        rm -f "$gz_file"
    fi
done

echo -e "\n${GREEN}[SUCCESS] Log compression and purge cycle complete.${NC}"
exit 0
