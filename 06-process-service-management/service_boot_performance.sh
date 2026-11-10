#!/usr/bin/env bash
# ==============================================================================
# Script Name : service_boot_performance.sh
# Description : Evaluates systemd boot duration and analyzes 'systemd-analyze blame'
#               to rank the slowest-starting services during host initialization.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, systemd-analyze
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

TOP_COUNT=10

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Profiles boot initialization duration and highlights slowest starting services.

Options:
  -n, --top <count>   Number of slowest units to list (default: 10)
  -h, --help          Show this help message and exit

Example:
  $(basename "$0") -n 15
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--top)
            TOP_COUNT="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Boot Performance & Startup Latency Profiler - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v systemd-analyze &>/dev/null; then
    echo -e "${RED}[ERROR] 'systemd-analyze' command not found.${NC}" >&2
    exit 1
fi

echo -e "${YELLOW}Boot Time Summary:${NC}"
systemd-analyze time 2>/dev/null || echo "Unable to analyze boot time in container environment."

echo -e "\n${YELLOW}Top ${TOP_COUNT} Slowest Starting Units (systemd-analyze blame):${NC}"
systemd-analyze blame 2>/dev/null | head -n "$TOP_COUNT" | while read -r line; do
    echo -e "  -> ${CYAN}${line}${NC}"
done

exit 0
