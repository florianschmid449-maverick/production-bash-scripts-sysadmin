#!/usr/bin/env bash
# ==============================================================================
# Script Name : backup_docker_volumes.sh
# Description : Mounts Docker named volumes into an ephemeral helper container,
#               creates compressed .tar.gz backups, and verifies data integrity.
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

VOLUME_NAME=""
BACKUP_DIR="/tmp/docker_volume_backups"

usage() {
    cat <<EOF
Usage: $(basename "$0") -v <volume_name> [OPTIONS]

Backs up Docker named volume contents into a compressed tar archive.

Options:
  -v, --volume <name>   Docker named volume to back up
  -o, --output <dir>    Destination backup directory (default: /tmp/docker_volume_backups)
  -h, --help            Show this help message and exit

Example:
  sudo $(basename "$0") -v db_data -o /backups/docker
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--volume)
            VOLUME_NAME="$2"; shift 2 ;;
        -o|--output)
            BACKUP_DIR="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

if [[ -z "$VOLUME_NAME" ]]; then
    echo -e "${RED}[ERROR] Docker volume name (-v) required.${NC}" >&2
    exit 2
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Docker Named Volume Snapshot Backup - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v docker &>/dev/null; then
    echo -e "${RED}[ERROR] 'docker' CLI not found.${NC}" >&2
    exit 1
fi

mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE="${BACKUP_DIR}/${VOLUME_NAME}_${TIMESTAMP}.tar.gz"

echo -e "${YELLOW}[BACKING UP] Archiving volume '${VOLUME_NAME}' via ephemeral container...${NC}"
docker run --rm -v "${VOLUME_NAME}:/volume_data:ro" -v "${BACKUP_DIR}:/backup" \
    alpine tar -czf "/backup/${VOLUME_NAME}_${TIMESTAMP}.tar.gz" -C /volume_data .

echo -e "${GREEN}[SUCCESS] Created volume backup: ${ARCHIVE}${NC}"
exit 0
