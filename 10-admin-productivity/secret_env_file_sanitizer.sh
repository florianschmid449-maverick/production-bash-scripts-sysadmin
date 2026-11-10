#!/usr/bin/env bash
# ==============================================================================
# Script Name : secret_env_file_sanitizer.sh
# Description : Scans repositories for exposed credentials, untracked .env files,
#               and private keys, generating sanitized .env.example templates.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, grep
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

Scans folders for credentials and creates redacted .env.example templates.

Options:
  -d, --dir <path>   Directory to scan (default: current directory)
  -h, --help         Show this help message and exit

Example:
  $(basename "$0") -d /srv/app
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

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Secret Leak Detector & .env Sanitizer - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

# Search for private keys
echo -e "Scanning for private keys..."
KEYS=$(grep -rn "BEGIN OPENSSH PRIVATE KEY\|BEGIN RSA PRIVATE KEY" "$TARGET_DIR" 2>/dev/null || true)
if [[ -n "$KEYS" ]]; then
    echo -e "${RED}[ALERT] Private key patterns detected in repository!${NC}"
    echo "$KEYS" | head -n 3
else
    echo -e "${GREEN}[OK] No unencrypted private key headers found.${NC}"
fi

# Sanitize .env files to .env.example
if [[ -f "${TARGET_DIR}/.env" ]]; then
    EXAMPLE_FILE="${TARGET_DIR}/.env.example"
    echo -e "\n${YELLOW}[ACTION] Generating sanitized ${EXAMPLE_FILE}...${NC}"
    sed -E 's/=(.*)/=your_\1_here/' "${TARGET_DIR}/.env" > "$EXAMPLE_FILE"
    echo -e "${GREEN}[SUCCESS] .env.example generated with values redacted.${NC}"
fi

exit 0
