#!/usr/bin/env bash
# ==============================================================================
# Script Name : incremental_rsync_backup.sh
# Description : Executes space-saving incremental filesystem backups using rsync
#               hardlinks (--link-dest) to provide full snapshots with minimal I/O.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, rsync
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SRC_DIR=""
DEST_DIR=""
DRY_RUN=false

usage() {
    cat <<EOF
Usage: $(basename "$0") -s <source> -d <destination> [OPTIONS]

Performs incremental rsync backups leveraging filesystem hardlinks.

Options:
  -s, --src <dir>     Source directory to back up
  -d, --dest <dir>    Parent destination backup repository
  -n, --dry-run       Simulate rsync execution without copying files
  -h, --help          Show this help message and exit

Example:
  $(basename "$0") -s /var/www -d /backups/www
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--src)
            SRC_DIR="$2"; shift 2 ;;
        -d|--dest)
            DEST_DIR="$2"; shift 2 ;;
        -n|--dry-run)
            DRY_RUN=true; shift ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

if [[ -z "$SRC_DIR" || -z "$DEST_DIR" ]]; then
    echo -e "${RED}[ERROR] Source (-s) and destination (-d) required.${NC}" >&2
    exit 2
fi

if ! command -v rsync &>/dev/null; then
    echo -e "${RED}[ERROR] 'rsync' command not found.${NC}" >&2
    exit 1
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Incremental Hardlink Rsync Backup - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

DATE_STAMP=$(date +%Y%m%d_%H%M%S)
SNAPSHOT_PATH="${DEST_DIR}/snapshot_${DATE_STAMP}"
LATEST_LINK="${DEST_DIR}/latest"

mkdir -p "$DEST_DIR"

RSYNC_OPTS=(-a --delete)
if [[ "$DRY_RUN" == true ]]; then
    RSYNC_OPTS+=(--dry-run -v)
    echo -e "${CYAN}[DRY-RUN] Simulating backup transfer...${NC}"
fi

if [[ -d "$LATEST_LINK" ]]; then
    echo -e "${CYAN}[INFO] Hardlinking against previous snapshot: ${LATEST_LINK}${NC}"
    RSYNC_OPTS+=(--link-dest="$LATEST_LINK")
fi

echo -e "${YELLOW}[SYNCING] ${SRC_DIR} -> ${SNAPSHOT_PATH}${NC}"
rsync "${RSYNC_OPTS[@]}" "${SRC_DIR}/" "$SNAPSHOT_PATH"

if [[ "$DRY_RUN" == false ]]; then
    rm -f "$LATEST_LINK"
    ln -s "$SNAPSHOT_PATH" "$LATEST_LINK"
    echo -e "${GREEN}[SUCCESS] Backup snapshot created and updated 'latest' pointer.${NC}"
fi

exit 0
