#!/usr/bin/env bash
# ==============================================================================
# Script Name : sudo_access_auditor.sh
# Description : Audits sudoers configuration and group memberships for dangerous
#               wildcards, NOPASSWD directives, and privilege escalations.
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

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Audits sudoers directives and administrative group access.

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
echo -e "${CYAN} Sudo Access & Privilege Escalation Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

# Check read access to sudoers
if [[ ! -r "/etc/sudoers" ]]; then
    echo -e "${YELLOW}[WARN] /etc/sudoers is unreadable. Re-run script as root or with sudo.${NC}"
    echo -e "${CYAN}[INFO] Checking group memberships available in /etc/group...${NC}"
fi

echo -e "Privileged Administrative Groups:"
for grp in "sudo" "wheel" "admin"; do
    if getent group "$grp" >/dev/null 2>&1; then
        members=$(getent group "$grp" | cut -d: -f4)
        echo -e "  Group '${grp}': ${GREEN}${members:-none}${NC}"
    fi
done

if [[ -r "/etc/sudoers" ]]; then
    echo -e "\nAuditing Sudoers Directives:"

    # Search for NOPASSWD directives
    NOPASSWD_ENTRIES=$(grep -rhE "^[^#].*NOPASSWD" /etc/sudoers /etc/sudoers.d/ 2>/dev/null || true)
    if [[ -n "$NOPASSWD_ENTRIES" ]]; then
        echo -e "  ${RED}[SECURITY RISK] NOPASSWD entries detected:${NC}"
        echo "$NOPASSWD_ENTRIES" | sed 's/^/    /'
    else
        echo -e "  ${GREEN}[OK] No unauthenticated NOPASSWD entries found.${NC}"
    fi

    # Search for risky commands allowing shell escapes
    RISKY_CMDS="vi|vim|nano|less|more|find|awk|bash|sh|zsh|python|perl|ruby"
    SHELL_ESCAPES=$(grep -rhE "^[^#].*($RISKY_CMDS)" /etc/sudoers /etc/sudoers.d/ 2>/dev/null || true)
    if [[ -n "$SHELL_ESCAPES" ]]; then
        echo -e "\n  ${YELLOW}[WARNING] Directives permitting potential shell-escape binaries:${NC}"
        echo "$SHELL_ESCAPES" | sed 's/^/    /'
    fi
fi

exit 0
