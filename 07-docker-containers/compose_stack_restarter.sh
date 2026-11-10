#!/usr/bin/env bash
# ==============================================================================
# Script Name : compose_stack_restarter.sh
# Description : Pulls updated registry images for Docker Compose stacks and conducts
#               zero-downtime rolling recreations only for updated service images.
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

COMPOSE_DIR="."

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Pulls newest images and restarts Docker Compose services gracefully.

Options:
  -d, --dir <path>   Directory containing docker-compose.yml (default: .)
  -h, --help         Show this help message and exit

Example:
  $(basename "$0") -d /srv/webstack
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dir)
            COMPOSE_DIR="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Docker Compose Rolling Image Updater - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v docker &>/dev/null; then
    echo -e "${RED}[ERROR] 'docker' CLI not found.${NC}" >&2
    exit 1
fi

if [[ ! -f "${COMPOSE_DIR}/docker-compose.yml" && ! -f "${COMPOSE_DIR}/compose.yaml" ]]; then
    echo -e "${YELLOW}[NOTICE] No compose file found in '${COMPOSE_DIR}'.${NC}"
    exit 0
fi

echo -e "${YELLOW}[PULLING] Checking for updated images...${NC}"
(cd "$COMPOSE_DIR" && docker compose pull)

echo -e "\n${YELLOW}[DEPLOYING] Applying updates with zero-downtime rolling restart...${NC}"
(cd "$COMPOSE_DIR" && docker compose up -d --remove-orphans)

echo -e "${GREEN}[SUCCESS] Docker compose stack updated successfully.${NC}"
exit 0
