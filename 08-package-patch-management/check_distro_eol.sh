#!/usr/bin/env bash
# ==============================================================================
# Script Name : check_distro_eol.sh
# Description : Reads /etc/os-release to detect active Linux distribution and
#               evaluates official End-Of-Life (EOL) schedule lifecycles.
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

Identifies host Linux distribution and audits End-Of-Life (EOL) support.

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
echo -e "${CYAN} Linux Distribution Lifecycle & EOL Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if [[ ! -f /etc/os-release ]]; then
    echo -e "${RED}[ERROR] /etc/os-release file not found.${NC}" >&2
    exit 1
fi

NAME=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
VERSION_ID=$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"' || echo "rolling")

echo -e "Detected OS Release : ${GREEN}${NAME}${NC}"
echo -e "Version Identifier  : ${CYAN}${VERSION_ID}${NC}\n"

# Check common deprecated distributions
if echo "$NAME" | grep -E -i "CentOS Linux 7|Ubuntu 14\.|Ubuntu 16\.|Ubuntu 18\.|Debian 8|Debian 9" >/dev/null; then
    echo -e "${RED}[CRITICAL EOL] This operating system release has reached End-Of-Life!${NC}"
    echo -e "${RED}Security updates are no longer published for this platform.${NC}"
    exit 1
else
    echo -e "${GREEN}[SUPPORTED] Operating system is within active vendor support lifecycle.${NC}"
fi

exit 0
