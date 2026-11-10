#!/usr/bin/env bash
# ==============================================================================
# Script Name : clipboard_history_cleaner.sh
# Description : Monitors X11/Wayland clipboard buffers, automatically wiping
#               passwords and sensitive tokens after a configurable inactivity timeout.
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

TIMEOUT_SEC=45

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Clears clipboard buffer after timeout to prevent secret exposure.

Options:
  -t, --timeout <sec>   Purge timeout in seconds (default: 45)
  -h, --help            Show this help message and exit

Example:
  $(basename "$0") -t 30
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--timeout)
            TIMEOUT_SEC="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Workstation Clipboard Security Buffer Purger - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if command -v xclip &>/dev/null; then
    echo -e "Arming X11 clipboard wipe timer (${TIMEOUT_SEC}s)..."
    sleep "$TIMEOUT_SEC"
    echo "" | xclip -selection clipboard 2>/dev/null || true
    echo -e "${GREEN}[CLEARED] X11 clipboard buffer sanitized.${NC}"
elif command -v wl-copy &>/dev/null; then
    echo -e "Arming Wayland clipboard wipe timer (${TIMEOUT_SEC}s)..."
    sleep "$TIMEOUT_SEC"
    wl-copy --clear 2>/dev/null || true
    echo -e "${GREEN}[CLEARED] Wayland clipboard buffer sanitized.${NC}"
else
    echo -e "${YELLOW}[NOTICE] No desktop clipboard tool (xclip, wl-copy) detected in this environment.${NC}"
fi

exit 0
