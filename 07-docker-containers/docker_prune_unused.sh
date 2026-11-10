#!/usr/bin/env bash
# ==============================================================================
# Script Name : docker_prune_unused.sh
# Description : Safely cleans dangling images, stopped containers, build caches,
#               and unused networks, reporting recovered disk storage.
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

FORCE=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Safely cleans stopped containers, dangling images, and builder caches.

Options:
  -f, --force   Execute prune without interactive confirmation
  -h, --help    Show this help message and exit

Example:
  $(basename "$0") --force
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--force)
            FORCE=true; shift ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Docker System & Storage Pruner - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v docker &>/dev/null; then
    echo -e "${YELLOW}[NOTICE] 'docker' CLI not found on this machine.${NC}"
    exit 0
fi

if [[ "$FORCE" == false ]]; then
    read -r -p "Are you sure you want to prune dangling Docker assets? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}[ABORTED] Pruning cancelled by user.${NC}"
        exit 0
    fi
fi

echo -e "${YELLOW}[ACTION] Pruning stopped containers, unused networks, and dangling images...${NC}"
docker system prune -f

echo -e "\n${GREEN}[SUCCESS] Docker cleanup finished successfully.${NC}"
exit 0
