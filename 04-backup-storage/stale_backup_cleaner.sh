#!/usr/bin/env bash
# ==============================================================================
# Script Name : stale_backup_cleaner.sh
# Description : Purges expired backups older than N days while enforcing the
#               safety floor rule (never purges the single newest remaining backup).
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

BACKUP_DIR=""
DAYS=30
DRY_RUN=false

usage() {
    cat <<EOF
Usage: $(basename "$0") -d <backup_dir> [OPTIONS]

Safely cleans expired backups while preserving the newest backup.

Options:
  -d, --dir <path>     Directory containing backup archives
  -k, --keep <days>    Retention window in days (default: 30)
  -n, --dry-run        Preview files to be deleted without removing
  -h, --help           Show this help message and exit

Example:
  $(basename "$0") -d /backups -k 14 --dry-run
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dir)
            BACKUP_DIR="$2"; shift 2 ;;
        -k|--keep)
            DAYS="$2"; shift 2 ;;
        -n|--dry-run)
            DRY_RUN=true; shift ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

if [[ -z "$BACKUP_DIR" || ! -d "$BACKUP_DIR" ]]; then
    echo -e "${RED}[ERROR] Valid backup directory (-d) required.${NC}" >&2
    exit 2
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Stale Backup Cleaner with Safety Floor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

# Find all backup files sorted by modification time (newest first)
FILES=()
while IFS= read -r f; do
    FILES+=("$f")
done < <(find "$BACKUP_DIR" -maxdepth 1 -type f \( -name "*.tar.gz" -o -name "*.dump" -o -name "*.sql.gz" \) -printf '%T@ %p\n' 2>/dev/null | sort -nr | awk '{print $2}')

TOTAL_FILES=${#FILES[@]}
if [[ "$TOTAL_FILES" -le 1 ]]; then
    echo -e "${GREEN}[SAFETY GUARD] Only ${TOTAL_FILES} backup exists. Retaining to prevent data loss.${NC}"
    exit 0
fi

NEWEST_FILE="${FILES[0]}"
echo -e "${CYAN}[PROTECTED] Newest backup preserved: $(basename "$NEWEST_FILE")${NC}\n"

# Scan files older than DAYS (excluding newest)
for ((i = 1; i < TOTAL_FILES; i++)); do
    f="${FILES[i]}"
    # Check age in days
    mtime=$(stat -c %Y "$f" 2>/dev/null || echo 0)
    now=$(date +%s)
    age_days=$(( (now - mtime) / 86400 ))

    if [[ "$age_days" -ge "$DAYS" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            echo -e "  ${YELLOW}[DRY-RUN WOULD DELETE]${NC} $(basename "$f") (Age: ${age_days} days)"
        else
            echo -e "  ${RED}[DELETED]${NC} $(basename "$f") (Age: ${age_days} days)"
            rm -f "$f" "${f}.sha256"
        fi
    fi
done

exit 0
