#!/usr/bin/env bash
# ==============================================================================
# Script Name : docker_log_truncator.sh
# Description : Traverses /var/lib/docker/containers/*/*-json.log and truncates
#               oversized logs in-place without restarting active containers.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, truncate, find
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

MAX_SIZE_MB=500
DRY_RUN=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Safely truncates runaway Docker container JSON log files.

Options:
  -s, --size-mb <int>   Maximum allowed log size in MB (default: 500)
  -n, --dry-run         Preview oversized logs without truncating
  -h, --help            Show this help message and exit

Example:
  sudo $(basename "$0") -s 200 --dry-run
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--size-mb)
            MAX_SIZE_MB="$2"; shift 2 ;;
        -n|--dry-run)
            DRY_RUN=true; shift ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Docker Container In-Place Log Truncator - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

DOCKER_LOG_PATH="/var/lib/docker/containers"

if [[ ! -d "$DOCKER_LOG_PATH" ]]; then
    echo -e "${YELLOW}[NOTICE] Docker container log path '${DOCKER_LOG_PATH}' not found.${NC}"
    exit 0
fi

if [[ "$EUID" -ne 0 ]]; then
    echo -e "${RED}[ERROR] Root privileges required to read and truncate Docker logs.${NC}" >&2
    exit 1
fi

echo -e "Auditing container logs > ${MAX_SIZE_MB} MB..."

find "$DOCKER_LOG_PATH" -type f -name "*-json.log" -size +"${MAX_SIZE_MB}M" 2>/dev/null | while read -r log_file; do
    sz=$(ls -lh "$log_file" | awk '{print $5}')
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "  ${YELLOW}[DRY-RUN WOULD TRUNCATE]${NC} ${log_file} (${sz})"
    else
        echo -e "  ${RED}[TRUNCATING]${NC} ${log_file} (${sz})..."
        truncate -s 0 "$log_file"
    fi
done

echo -e "${GREEN}[SUCCESS] Log truncation check complete.${NC}"
exit 0
