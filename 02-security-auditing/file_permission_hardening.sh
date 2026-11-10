#!/usr/bin/env bash
# ==============================================================================
# Script Name : file_permission_hardening.sh
# Description : Audits and enforces CIS benchmark permissions on critical
#               system configuration files (/etc/passwd, /etc/shadow, etc.).
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, stat, chmod
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

FIX_MODE=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Audits and optionally hardens filesystem permissions on critical OS configuration files.

Options:
  --fix        Automatically apply recommended security permissions
  -h, --help   Show this help message and exit

Example:
  sudo $(basename "$0") --fix
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --fix)
            FIX_MODE=true; shift ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} System File Permission Hardening Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

# Target files and expected maximum octal permissions
declare -A TARGETS=(
    ["/etc/passwd"]="644"
    ["/etc/group"]="644"
    ["/etc/shadow"]="640"
    ["/etc/gshadow"]="640"
    ["/etc/crontab"]="600"
    ["/etc/ssh/sshd_config"]="600"
)

for file in "${!TARGETS[@]}"; do
    expected="${TARGETS[$file]}"

    if [[ ! -e "$file" ]]; then
        continue
    fi

    # Read current octal permissions
    current=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%Op" "$file" 2>/dev/null || echo "unknown")

    if [[ "$current" == "$expected" || "$current" == "0$expected" || "$current" == "000" ]]; then
        echo -e "${GREEN}[COMPLIANT]${NC} ${file} (Current: ${current}, Expected: ${expected})"
    else
        echo -e "${RED}[NON-COMPLIANT]${NC} ${file} (Current: ${current}, Expected: ${expected})"

        if [[ "$FIX_MODE" == true && "$EUID" -eq 0 ]]; then
            chmod "$expected" "$file"
            echo -e "  -> ${CYAN}[REMEDIATED] Applied chmod ${expected} to ${file}.${NC}"
        fi
    fi
done

exit 0
