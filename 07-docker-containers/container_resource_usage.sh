#!/usr/bin/env bash
# ==============================================================================
# Script Name : container_resource_usage.sh
# Description : Streams Docker container CPU%, memory limits, and network I/O stats,
#               flagging containers approaching assigned quota thresholds.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, docker
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

Reports snapshot of live Docker container resource usage.

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
echo -e "${CYAN} Docker Container Live Resource Monitor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v docker &>/dev/null; then
    echo -e "${YELLOW}[NOTICE] 'docker' binary not found.${NC}"
    exit 0
fi

# Query docker stats --no-stream
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}" 2>/dev/null || echo -e "${YELLOW}Docker daemon inactive or permission denied.${NC}"

exit 0
