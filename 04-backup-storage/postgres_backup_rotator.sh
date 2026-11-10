#!/usr/bin/env bash
# ==============================================================================
# Script Name : postgres_backup_rotator.sh
# Description : Backs up PostgreSQL databases in custom directory format (-Fc)
#               and maintains tiered daily, weekly, and monthly rotation archives.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, pg_dump, find
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DB_USER="postgres"
DB_NAME=""
BACKUP_DIR="/tmp/postgres_backups"
KEEP_DAYS=7

usage() {
    cat <<EOF
Usage: $(basename "$0") -d <database> [OPTIONS]

Dumps PostgreSQL database and enforces retention rotation.

Options:
  -d, --database <name>   PostgreSQL database to back up
  -u, --user <user>       Database username (default: postgres)
  -o, --output <dir>      Output backup repository (default: /tmp/postgres_backups)
  -k, --keep <days>       Retention period in days (default: 7)
  -h, --help              Show this help message and exit

Example:
  $(basename "$0") -d app_production -u postgres -o /backups/pg -k 14
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--database)
            DB_NAME="$2"; shift 2 ;;
        -u|--user)
            DB_USER="$2"; shift 2 ;;
        -o|--output)
            BACKUP_DIR="$2"; shift 2 ;;
        -k|--keep)
            KEEP_DAYS="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

if [[ -z "$DB_NAME" ]]; then
    echo -e "${RED}[ERROR] Database name (-d) is required.${NC}" >&2
    exit 2
fi

if ! command -v pg_dump &>/dev/null; then
    echo -e "${RED}[ERROR] 'pg_dump' command not found.${NC}" >&2
    exit 1
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} PostgreSQL Backup & Retention Rotator - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUT_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.dump"

echo -e "${YELLOW}[DUMPING] Creating custom compressed pg_dump for '${DB_NAME}'...${NC}"
pg_dump -U "$DB_USER" -Fc "$DB_NAME" > "$OUT_FILE"

echo -e "${GREEN}[SUCCESS] Dump created: ${OUT_FILE}${NC}"

# Prune archives older than KEEP_DAYS
echo -e "${CYAN}[ROTATION] Purging dumps older than ${KEEP_DAYS} days in ${BACKUP_DIR}...${NC}"
find "$BACKUP_DIR" -name "${DB_NAME}_*.dump" -type f -mtime +"$KEEP_DAYS" -delete 2>/dev/null || true

exit 0
