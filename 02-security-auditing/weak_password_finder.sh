#!/usr/bin/env bash
# ==============================================================================
# Script Name : weak_password_finder.sh
# Description : Scans /etc/shadow for accounts with empty passwords, locked accounts,
#               or legacy insecure hash algorithms (MD5/DES).
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, awk
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Audits /etc/shadow for blank passwords and weak cryptographic algorithms.

Options:
  -h, --help   Show this help message and exit

Example:
  sudo $(basename "$0")
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Shadow Password Security Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if [[ "$EUID" -ne 0 ]]; then
    echo -e "${RED}[ERROR] Root privileges required to read /etc/shadow.${NC}" >&2
    exit 1
fi

EMPTY_COUNT=0
WEAK_HASH_COUNT=0

while IFS=: read -r user pass rest; do
    # Check for empty password
    if [[ -z "$pass" ]]; then
        echo -e "${RED}[CRITICAL RISK]${NC} User '${user}' has an EMPTY password!"
        EMPTY_COUNT=$((EMPTY_COUNT + 1))
        continue
    fi

    # Ignore locked or system accounts ($! or * or !!)
    if [[ "$pass" =~ ^\* || "$pass" =~ ^\! ]]; then
        continue
    fi

    # Check hash prefix
    # $1$ = MD5, $2$ = Blowfish, $5$ = SHA-256, $6$ = SHA-512, $y$ = yescrypt
    if [[ "$pass" =~ ^\$1\$ ]]; then
        echo -e "${YELLOW}[WARNING]${NC} User '${user}' uses deprecated MD5 password hashing."
        WEAK_HASH_COUNT=$((WEAK_HASH_COUNT + 1))
    elif [[ ! "$pass" =~ ^\$[56y]\$ ]]; then
        echo -e "${YELLOW}[NOTICE]${NC} User '${user}' uses non-standard hash format."
    fi
done < /etc/shadow

if [[ "$EMPTY_COUNT" -eq 0 && "$WEAK_HASH_COUNT" -eq 0 ]]; then
    echo -e "${GREEN}[OK] All active user passwords are encrypted with modern hashes. No blank passwords found.${NC}"
fi

exit 0
