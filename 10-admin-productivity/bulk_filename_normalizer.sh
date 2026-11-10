#!/usr/bin/env bash
# ==============================================================================
# Script Name : bulk_filename_normalizer.sh
# Description : Traverses directory trees to sanitize filenames: converts to lowercase,
#               replaces spaces with underscores, and strips illegal special chars.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, find, tr
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
DRY_RUN=false

usage() {
    cat <<EOF
Usage: $(basename "$0") -d <dir> [OPTIONS]

Normalizes filenames by lowercasing and replacing whitespace with underscores.

Options:
  -d, --dir <path>   Directory containing files to normalize
  -n, --dry-run      Simulate rename operations without applying
  -h, --help         Show this help message and exit

Example:
  $(basename "$0") -d ~/Downloads --dry-run
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
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

if [[ -z "$TARGET_DIR" || ! -d "$TARGET_DIR" ]]; then
    echo -e "${RED}[ERROR] Valid directory (-d) required.${NC}" >&2
    exit 2
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Bulk Filename Sanitizer & Normalizer - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

find "$TARGET_DIR" -maxdepth 1 -type f | while read -r filepath; do
    dir=$(dirname "$filepath")
    base=$(basename "$filepath")

    # Lowercase and replace spaces/hyphens with underscore
    clean=$(echo "$base" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_.-')

    if [[ "$base" != "$clean" ]]; then
        new_path="${dir}/${clean}"
        if [[ "$DRY_RUN" == true ]]; then
            echo -e "  ${YELLOW}[DRY-RUN]${NC} '${base}' -> '${clean}'"
        else
            mv "$filepath" "$new_path"
            echo -e "  ${GREEN}[RENAMED]${NC} '${base}' -> '${clean}'"
        fi
    fi
done

echo -e "${GREEN}[SUCCESS] Normalization pass complete.${NC}"
exit 0
