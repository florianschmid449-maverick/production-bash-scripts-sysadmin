#!/usr/bin/env bash
# ==============================================================================
# Script Name : port_connectivity_checker.sh
# Description : Tests TCP connectivity against specified host:port targets with
#               millisecond timeout controls using pure Bash socket streams.
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

TARGETS=()
TIMEOUT=2

usage() {
    cat <<EOF
Usage: $(basename "$0") -t <host:port> [OPTIONS]

Tests TCP socket connection reachability.

Options:
  -t, --target <host:port>   Remote target to test (can be specified multiple times)
  -w, --timeout <sec>        Connection timeout in seconds (default: 2)
  -h, --help                 Show this help message and exit

Example:
  $(basename "$0") -t google.com:443 -t 1.1.1.1:53 -w 1
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--target)
            TARGETS+=("$2"); shift 2 ;;
        -w|--timeout)
            TIMEOUT="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

if [[ ${#TARGETS[@]} -eq 0 ]]; then
    echo -e "${RED}[ERROR] At least one -t host:port target is required.${NC}" >&2
    exit 2
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} TCP Port Connectivity Diagnostic - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

for target in "${TARGETS[@]}"; do
    host="${target%:*}"
    port="${target#*:}"

    if timeout "$TIMEOUT" bash -c "</dev/tcp/${host}/${port}" 2>/dev/null; then
        echo -e "  ${GREEN}[OPEN]${NC}     ${host}:${port} responded within ${TIMEOUT}s"
    else
        echo -e "  ${RED}[CLOSED]${NC}   ${host}:${port} timed out or connection refused"
    fi
done

exit 0
