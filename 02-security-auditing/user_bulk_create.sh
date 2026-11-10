#!/usr/bin/env bash
# ==============================================================================
# Script Name : user_bulk_create.sh
# Description : Provisions Linux user accounts in bulk from a CSV definition file,
#               configuring home directories, default shells, and SSH keys safely.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, useradd
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CSV_FILE=""
DRY_RUN=false

usage() {
    cat <<EOF
Usage: $(basename "$0") -f <csv_file> [OPTIONS]

Provisions user accounts in bulk from a CSV file.
CSV format expected: username,shell,groups (comma separated)

Options:
  -f, --file <path>   Input CSV file containing user specifications
  -n, --dry-run       Simulate creation without making changes
  -h, --help          Show this help message and exit

Example:
  sudo $(basename "$0") -f users.csv --dry-run
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--file)
            CSV_FILE="$2"; shift 2 ;;
        -n|--dry-run)
            DRY_RUN=true; shift ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

if [[ -z "$CSV_FILE" || ! -f "$CSV_FILE" ]]; then
    echo -e "${RED}[ERROR]${NC} Valid CSV file required via -f." >&2
    exit 2
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Bulk User Provisioning Tool - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

while IFS=, read -r username shell groups; do
    # Skip comments or empty lines
    [[ "$username" =~ ^#.*$ || -z "$username" ]] && continue

    username=$(echo "$username" | xargs)
    shell=$(echo "${shell:-/bin/bash}" | xargs)
    groups=$(echo "${groups:-}" | xargs)

    if id "$username" &>/dev/null; then
        echo -e "${YELLOW}[SKIP]${NC} User '${username}' already exists."
        continue
    fi

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${CYAN}[DRY-RUN]${NC} Would create user '${username}' (Shell: ${shell}, Groups: ${groups:-default})"
    else
        CMD="useradd -m -s '$shell'"
        if [[ -n "$groups" ]]; then
            CMD="$CMD -G '$groups'"
        fi
        CMD="$CMD '$username'"
        eval "$CMD"
        chmod 700 "/home/$username"
        echo -e "${GREEN}[CREATED]${NC} User '${username}' successfully provisioned."
    fi
done < "$CSV_FILE"

exit 0
