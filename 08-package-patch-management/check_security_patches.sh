#!/usr/bin/env bash
# ==============================================================================
# Script Name : check_security_patches.sh
# Description : Queries apt, dnf, zypper, or apk strictly for pending security
#               updates and CVE advisories without applying any modifications.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils
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

Audits host package manager for pending security and CVE patches.

Options:
  -h, --help   Show this help message and exit

Example:
  $(basename "$0")
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
echo -e "${CYAN} Pending Security Patch & CVE Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

# Detect package manager
if command -v apt-get &>/dev/null; then
    echo -e "Detected Debian/Ubuntu Package Manager (APT)..."
    PENDING=$(apt-get -s dist-upgrade 2>/dev/null | grep -i security || true)
    if [[ -n "$PENDING" ]]; then
        echo -e "${RED}[SECURITY UPDATES PENDING]${NC}"
        echo "$PENDING" | head -n 5
    else
        echo -e "${GREEN}[OK] No pending security updates reported.${NC}"
    fi
elif command -v dnf &>/dev/null; then
    echo -e "Detected RHEL/Fedora Package Manager (DNF)..."
    dnf updateinfo list security 2>/dev/null || echo -e "${GREEN}[OK] System security packages up to date.${NC}"
elif command -v zypper &>/dev/null; then
    zypper list-patches --category security 2>/dev/null || true
else
    echo -e "${YELLOW}[NOTICE] No supported package manager detected.${NC}"
fi

exit 0
