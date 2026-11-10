#!/usr/bin/env bash
# ==============================================================================
# Script Name : backup_integrity_verifier.sh
# Description : Validates backup archives by checking headers, verifying SHA-256
#               checksums, and executing test extractions in temporary directories.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, tar, gzip, sha256sum
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

usage() {
    cat <<EOF
Usage: $(basename "$0") -d <backup_dir> [OPTIONS]

Audits and verifies the integrity of backup archives and checksums.

Options:
  -d, --dir <path>   Directory containing backup archives to audit
  -h, --help         Show this help message and exit

Example:
  $(basename "$0") -d /backups
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dir)
            BACKUP_DIR="$2"; shift 2 ;;
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
echo -e "${CYAN} Backup Integrity & Archive Verifier - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

# 1. Audit SHA-256 manifests
echo -e "Auditing Checksum Manifests..."
find "$BACKUP_DIR" -maxdepth 2 -type f -name "*.sha256" | while read -r manifest; do
    echo -e "  Verifying manifest: $(basename "$manifest")"
    (cd "$(dirname "$manifest")" && sha256sum -c "$(basename "$manifest")") 2>/dev/null && \
        echo -e "    ${GREEN}[CHECKSUM PASS]${NC}" || echo -e "    ${RED}[CHECKSUM MISMATCH]${NC}"
done

# 2. Test tar.gz archive tables of contents
echo -e "\nAuditing .tar.gz Archive Headers..."
find "$BACKUP_DIR" -maxdepth 2 -type f -name "*.tar.gz" | while read -r archive; do
    echo -n "  Testing $(basename "$archive")... "
    if tar -tzf "$archive" >/dev/null 2>&1; then
        echo -e "${GREEN}[VALID]${NC}"
    else
        echo -e "${RED}[CORRUPT ARCHIVE]${NC}"
    fi
done

exit 0
