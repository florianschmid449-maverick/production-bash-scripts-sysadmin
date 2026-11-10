#!/usr/bin/env bash
# ==============================================================================
# Script Name : remote_sftp_sync.sh
# Description : Synchronizes backup archives securely to an offsite SFTP / SSH
#               target with automatic transfer resumes and bandwidth rate limits.
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

LOCAL_DIR=""
REMOTE_TARGET=""
BW_LIMIT=0 # KB/s (0 = unlimited)

usage() {
    cat <<EOF
Usage: $(basename "$0") -l <local_dir> -r <remote_user@host:dir> [OPTIONS]

Synchronizes backup archives to an offsite SFTP server via rsync/ssh.

Options:
  -l, --local <dir>           Local directory to upload
  -r, --remote <target>       Remote destination (e.g. backupuser@sftp.domain.com:/storage)
  -b, --bwlimit <kbps>        Bandwidth limit in KB/s (default: unlimited)
  -h, --help                  Show this help message and exit

Example:
  $(basename "$0") -l /backups -r backupuser@offsite.com:/data/backups -b 5000
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -l|--local)
            LOCAL_DIR="$2"; shift 2 ;;
        -r|--remote)
            REMOTE_TARGET="$2"; shift 2 ;;
        -b|--bwlimit)
            BW_LIMIT="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

if [[ -z "$LOCAL_DIR" || -z "$REMOTE_TARGET" ]]; then
    echo -e "${RED}[ERROR] Local (-l) and remote (-r) destinations are required.${NC}" >&2
    exit 2
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Offsite Backup SFTP / SSH Synchronizer - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

RSYNC_FLAGS=(-avz --partial --progress)
if [[ "$BW_LIMIT" -gt 0 ]]; then
    RSYNC_FLAGS+=(--bwlimit="$BW_LIMIT")
    echo -e "Throttling transfer to: ${BW_LIMIT} KB/s"
fi

echo -e "${YELLOW}[SYNCING] ${LOCAL_DIR} -> ${REMOTE_TARGET}...${NC}"
rsync "${RSYNC_FLAGS[@]}" "$LOCAL_DIR/" "$REMOTE_TARGET"

echo -e "${GREEN}[SUCCESS] Offsite backup transfer completed.${NC}"
exit 0
