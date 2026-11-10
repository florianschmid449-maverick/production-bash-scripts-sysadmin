#!/usr/bin/env bash
# ==============================================================================
# Script Name : file_integrity_monitor.sh
# Description : Lightweight File Integrity Monitoring (FIM) tool that builds a
#               SHA-256 baseline and detects modified, added, or deleted system files.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, sha256sum, find
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

TARGET_DIR="/etc"
BASELINE_FILE="/tmp/fim_baseline.sha256"
ACTION="check"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Monitors and audits filesystem integrity against a cryptographic SHA-256 baseline.

Options:
  -d, --dir <path>       Directory to monitor (default: /etc)
  -b, --baseline <path>  Baseline manifest file path (default: /tmp/fim_baseline.sha256)
  -i, --init             Initialize or update the baseline manifest
  -c, --check            Check current files against the baseline (default)
  -h, --help             Show this help message and exit

Example:
  sudo $(basename "$0") -d /etc/pam.d --init
  sudo $(basename "$0") -d /etc/pam.d --check
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dir)
            TARGET_DIR="$2"; shift 2 ;;
        -b|--baseline)
            BASELINE_FILE="$2"; shift 2 ;;
        -i|--init)
            ACTION="init"; shift ;;
        -c|--check)
            ACTION="check"; shift ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Defensive File Integrity Monitor (FIM) - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if [[ ! -d "$TARGET_DIR" ]]; then
    echo -e "${RED}[ERROR] Target directory '${TARGET_DIR}' does not exist.${NC}" >&2
    exit 1
fi

if [[ "$ACTION" == "init" ]]; then
    echo -e "${YELLOW}[INITIALIZING] Generating cryptographic SHA-256 baseline for '${TARGET_DIR}'...${NC}"
    find "$TARGET_DIR" -maxdepth 2 -type f -exec sha256sum {} + 2>/dev/null > "$BASELINE_FILE"
    COUNT=$(wc -l < "$BASELINE_FILE")
    echo -e "${GREEN}[SUCCESS] Recorded ${COUNT} file signatures to baseline: ${BASELINE_FILE}${NC}"
    exit 0
fi

if [[ "$ACTION" == "check" ]]; then
    if [[ ! -f "$BASELINE_FILE" ]]; then
        echo -e "${RED}[ERROR] Baseline file '${BASELINE_FILE}' not found. Run with --init first.${NC}" >&2
        exit 1
    fi

    echo -e "${YELLOW}[AUDITING] Comparing files against baseline: ${BASELINE_FILE}...${NC}\n"

    FAILURES=0
    TOTAL=0

    while read -r expected_hash filepath; do
        TOTAL=$((TOTAL + 1))
        if [[ ! -f "$filepath" ]]; then
            echo -e "  ${RED}[DELETED]${NC}  ${filepath}"
            FAILURES=$((FAILURES + 1))
            continue
        fi

        current_hash=$(sha256sum "$filepath" | awk '{print $1}')
        if [[ "$expected_hash" != "$current_hash" ]]; then
            echo -e "  ${RED}[MODIFIED]${NC} ${filepath} (Hash mismatch!)"
            FAILURES=$((FAILURES + 1))
        fi
    done < "$BASELINE_FILE"

    if [[ "$FAILURES" -eq 0 ]]; then
        echo -e "${GREEN}[INTEGRITY VERIFIED] All ${TOTAL} monitored files match baseline hashes perfectly.${NC}"
        exit 0
    else
        echo -e "\n${RED}[ALERT] Detected ${FAILURES} file integrity anomalies out of ${TOTAL} monitored.${NC}"
        exit 1
    fi
fi
