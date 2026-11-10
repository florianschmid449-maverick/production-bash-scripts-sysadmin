#!/usr/bin/env bash
# ==============================================================================
# Script Name : duplicate_file_finder.sh
# Description : Efficiently identifies duplicate files using two-stage filtering
#               (byte size match followed by SHA-256 hash comparison).
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, find, sha256sum, awk
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

TARGET_DIR="."

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Locates duplicate files based on size and SHA-256 cryptographic hashes.

Options:
  -d, --dir <path>   Directory to search (default: current directory)
  -h, --help         Show this help message and exit

Example:
  $(basename "$0") -d /srv/shared
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dir)
            TARGET_DIR="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

if [[ ! -d "$TARGET_DIR" ]]; then
    echo -e "${RED}[ERROR] Directory '${TARGET_DIR}' not found.${NC}" >&2
    exit 1
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} High-Efficiency Duplicate File Finder - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"
echo -e "Stage 1: Scanning file sizes in '${TARGET_DIR}'..."

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

# Stage 1: Group files by byte size
find "$TARGET_DIR" -type f -size +0c -exec ls -l {} + 2>/dev/null | awk '{print $5, $9}' | sort -n > "${TMP_DIR}/sizes.txt"

# Find duplicate sizes
awk '{print $1}' "${TMP_DIR}/sizes.txt" | uniq -d > "${TMP_DIR}/duplicate_sizes.txt"

if [[ ! -s "${TMP_DIR}/duplicate_sizes.txt" ]]; then
    echo -e "${GREEN}[OK] No candidate duplicate files found.${NC}"
    exit 0
fi

echo -e "Stage 2: Computing SHA-256 hashes for size-matched candidates..."

while read -r sz; do
    grep "^${sz} " "${TMP_DIR}/sizes.txt" | awk '{$1=""; print substr($0,2)}' | while read -r filepath; do
        if [[ -f "$filepath" ]]; then
            sha256sum "$filepath" >> "${TMP_DIR}/hashes.txt" 2>/dev/null || true
        fi
    done
done < "${TMP_DIR}/duplicate_sizes.txt"

if [[ -f "${TMP_DIR}/hashes.txt" ]]; then
    DUPS=$(awk '{print $1}' "${TMP_DIR}/hashes.txt" | sort | uniq -d || true)
    if [[ -n "$DUPS" ]]; then
        echo -e "\n${RED}[DUPLICATES FOUND]${NC}\n"
        for hash in $DUPS; do
            echo -e "${YELLOW}Hash: ${hash}${NC}"
            grep "^${hash}" "${TMP_DIR}/hashes.txt" | awk '{print "  -> " $2}'
        done
        exit 0
    fi
fi

echo -e "${GREEN}[OK] No cryptographic duplicates detected.${NC}"
exit 0
