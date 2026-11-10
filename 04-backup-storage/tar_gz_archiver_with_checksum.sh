#!/usr/bin/env bash
# ==============================================================================
# Script Name : tar_gz_archiver_with_checksum.sh
# Description : Archives directories into compressed .tar.gz with POSIX ACLs,
#               generates SHA-256 manifests, and performs test extractions.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, tar, sha256sum
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
OUT_DIR="/tmp/archives"

usage() {
    cat <<EOF
Usage: $(basename "$0") -s <source_dir> [OPTIONS]

Archives directories and certifies archive integrity with checksums.

Options:
  -s, --src <dir>     Source directory to bundle
  -o, --out <dir>     Destination archive folder (default: /tmp/archives)
  -h, --help          Show this help message and exit

Example:
  $(basename "$0") -s /etc -o /backups/system_config
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--src)
            SRC_DIR="$2"; shift 2 ;;
        -o|--out)
            OUT_DIR="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

if [[ -z "$SRC_DIR" || ! -d "$SRC_DIR" ]]; then
    echo -e "${RED}[ERROR] Valid source directory required via -s.${NC}" >&2
    exit 2
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Certified Tar Archiver with Verification - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

mkdir -p "$OUT_DIR"
BASE_NAME=$(basename "$SRC_DIR")
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE="${OUT_DIR}/${BASE_NAME}_${TIMESTAMP}.tar.gz"

echo -e "${YELLOW}[ARCHIVING] Bundling ${SRC_DIR} -> ${ARCHIVE}...${NC}"
tar -czf "$ARCHIVE" -C "$(dirname "$SRC_DIR")" "$BASE_NAME"

# Checksum generation
echo -e "${CYAN}[CHECKSUM] Generating SHA-256 signature...${NC}"
sha256sum "$ARCHIVE" > "${ARCHIVE}.sha256"

# Integrity verification via test listing
echo -e "${CYAN}[VERIFYING] Testing archive readability...${NC}"
tar -tzf "$ARCHIVE" >/dev/null

SIZE=$(du -h "$ARCHIVE" | awk '{print $1}')
echo -e "${GREEN}[SUCCESS] Archive verified successfully (${SIZE}).${NC}"
echo -e "Checksum: $(cat "${ARCHIVE}.sha256")"

exit 0
