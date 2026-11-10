#!/usr/bin/env bash
# ==============================================================================
# Script Name : docker_container_healthcheck.sh
# Description : Audits Docker containers for unhealthy states, restart loops,
#               or non-zero exits, isolating stderr outputs for quick alerts.
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

Audits Docker container health status and restart stability.

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
echo -e "${CYAN} Docker Container Health & Restart Loop Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v docker &>/dev/null; then
    echo -e "${YELLOW}[NOTICE] 'docker' binary not found.${NC}"
    exit 0
fi

# List all containers and status
CONTAINERS=$(docker ps -a --format "{{.ID}} {{.Names}} {{.Status}}" 2>/dev/null || true)

if [[ -z "$CONTAINERS" ]]; then
    echo -e "${GREEN}[OK] No Docker containers present or daemon is inactive.${NC}"
    exit 0
fi

UNHEALTHY_FOUND=false

echo "$CONTAINERS" | while read -r id name status; do
    if [[ "$status" =~ unhealthy || "$status" =~ "Restarting" || "$status" =~ "Exited (" && ! "$status" =~ "Exited (0)" ]]; then
        UNHEALTHY_FOUND=true
        echo -e "${RED}[ALERT] Container '${name}' (${id}) is in degraded state: ${status}${NC}"
        echo -e "${YELLOW}Recent Stderr Logs:${NC}"
        docker logs --tail 3 "$id" 2>&1 | sed 's/^/  /' || true
    else
        echo -e "${GREEN}[HEALTHY]${NC} Container '${name}' -> ${status}"
    fi
done

exit 0
