#!/usr/bin/env bash
# ==============================================================================
# Script Name : route_trace_diagnostics.sh
# Description : Executes diagnostic traceroutes to identify network hop latency
#               spikes and packet drops across internet gateways.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, traceroute or mtr or tracepath
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

TARGET="1.1.1.1"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Performs hop-by-hop network path diagnostics.

Options:
  -d, --dest <host/ip>   Target host or IP address (default: 1.1.1.1)
  -h, --help             Show this help message and exit

Example:
  $(basename "$0") -d 8.8.8.8
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dest)
            TARGET="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Network Route & Hop Diagnostic - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"
echo -e "Tracing route to: ${TARGET}...\n"

if command -v tracepath &>/dev/null; then
    tracepath "$TARGET"
elif command -v traceroute &>/dev/null; then
    traceroute -n "$TARGET"
elif command -v mtr &>/dev/null; then
    mtr --report --report-cycles 2 "$TARGET"
else
    echo -e "${YELLOW}[NOTICE] Neither tracepath, traceroute, nor mtr was found.${NC}"
    echo -e "${CYAN}[INFO] Performing fallback ping diagnostics (5 packets):${NC}"
    ping -c 5 "$TARGET"
fi

exit 0
