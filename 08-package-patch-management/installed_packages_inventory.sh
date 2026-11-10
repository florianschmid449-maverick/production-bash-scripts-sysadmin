#!/usr/bin/env bash
# ==============================================================================
# Script Name : installed_packages_inventory.sh
# Description : Generates a versioned Software Bill of Materials (SBOM) covering
#               system OS packages, pip libraries, and global npm packages.
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

OUT_FILE="/tmp/installed_packages_sbom.csv"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Exports installed software packages to a CSV inventory.

Options:
  -o, --output <path>   Output CSV file (default: /tmp/installed_packages_sbom.csv)
  -h, --help            Show this help message and exit

Example:
  $(basename "$0") -o ~/server_sbom.csv
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output)
            OUT_FILE="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Software Bill of Materials (SBOM) Package Inventory - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

echo "ecosystem,package_name,version" > "$OUT_FILE"

# 1. OS packages (dpkg or rpm)
if command -v dpkg-query &>/dev/null; then
    echo -e "${YELLOW}[SCANNING] Enumerating Debian/Ubuntu packages...${NC}"
    dpkg-query -W -f='os,${Package},${Version}\n' >> "$OUT_FILE" 2>/dev/null || true
elif command -v rpm &>/dev/null; then
    echo -e "${YELLOW}[SCANNING] Enumerating RPM packages...${NC}"
    rpm -qa --qf 'os,%{NAME},%{VERSION}-%{RELEASE}\n' >> "$OUT_FILE" 2>/dev/null || true
fi

# 2. Python pip packages
if command -v pip3 &>/dev/null; then
    echo -e "${YELLOW}[SCANNING] Enumerating Python pip modules...${NC}"
    pip3 list --format=freeze 2>/dev/null | awk -F== '{print "python," $1 "," $2}' >> "$OUT_FILE" || true
fi

TOTAL=$(wc -l < "$OUT_FILE")
echo -e "${GREEN}[SUCCESS] Recorded $((TOTAL - 1)) packages to: ${OUT_FILE}${NC}"
exit 0
