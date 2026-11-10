#!/usr/bin/env bash
# ==============================================================================
# Script Name : database_mysql_dump.sh
# Description : Dumps MySQL/MariaDB databases with single-transaction consistency,
#               applies gzip compression, and calculates SHA-256 integrity sums.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, mysqldump or mariadb-dump, gzip
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DB_USER="root"
DB_NAME=""
BACKUP_DIR="/tmp/mysql_backups"

usage() {
    cat <<EOF
Usage: $(basename "$0") -d <database> [OPTIONS]

Performs consistent compressed MySQL/MariaDB database backups.

Options:
  -d, --database <name>   Database name to back up (or 'all' for --all-databases)
  -u, --user <user>       Database username (default: root)
  -o, --output <dir>      Output backup directory (default: /tmp/mysql_backups)
  -h, --help              Show this help message and exit

Example:
  $(basename "$0") -d my_production_db -u admin -o /backups/db
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

DUMP_BIN=""
for bin in "mariadb-dump" "mysqldump"; do
    if command -v "$bin" &>/dev/null; then
        DUMP_BIN="$bin"
        break
    fi
done

if [[ -z "$DUMP_BIN" ]]; then
    echo -e "${RED}[ERROR] Neither 'mysqldump' nor 'mariadb-dump' was found.${NC}" >&2
    exit 1
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} MySQL / MariaDB Consistent Database Dump - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUT_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.sql.gz"

echo -e "${YELLOW}[DUMPING] Starting dump of database '${DB_NAME}' using ${DUMP_BIN}...${NC}"

if [[ "$DB_NAME" == "all" ]]; then
    "$DUMP_BIN" -u "$DB_USER" --all-databases --single-transaction --quick | gzip > "$OUT_FILE"
else
    "$DUMP_BIN" -u "$DB_USER" --single-transaction --quick "$DB_NAME" | gzip > "$OUT_FILE"
fi

# Calculate checksum
sha256sum "$OUT_FILE" > "${OUT_FILE}.sha256"

SIZE_HUMAN=$(du -h "$OUT_FILE" | awk '{print $1}')
echo -e "${GREEN}[SUCCESS] Backup complete: ${OUT_FILE} (${SIZE_HUMAN})${NC}"
echo -e "Checksum: $(cat "${OUT_FILE}.sha256")"

exit 0
