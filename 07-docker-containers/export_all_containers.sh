#!/usr/bin/env bash
# ==============================================================================
# Script Name : export_all_containers.sh
# Description : Backs up running container configurations, mounts, port bindings,
#               and network metadata to structured JSON for disaster recovery.
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

OUTPUT_DIR="/tmp/docker_container_metadata"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Exports JSON metadata for all active Docker containers for disaster recovery.

Options:
  -o, --output <dir>   Output directory for JSON dumps (default: /tmp/docker_container_metadata)
  -h, --help           Show this help message and exit

Example:
  $(basename "$0") -o /backups/docker_metadata
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output)
            OUTPUT_DIR="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Docker Container Metadata Disaster Recovery Exporter - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v docker &>/dev/null; then
    echo -e "${YELLOW}[NOTICE] 'docker' binary not found.${NC}"
    exit 0
fi

mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

CONTAINERS=$(docker ps -q 2>/dev/null || true)
if [[ -z "$CONTAINERS" ]]; then
    echo -e "${GREEN}[OK] No active containers running.${NC}"
    exit 0
fi

for cid in $CONTAINERS; do
    cname=$(docker inspect --format '{{.Name}}' "$cid" | tr -d '/')
    out_file="${OUTPUT_DIR}/${cname}_${TIMESTAMP}.json"
    docker inspect "$cid" > "$out_file"
    echo -e "  ${GREEN}[EXPORTED]${NC} ${cname} -> ${out_file}"
done

echo -e "\n${GREEN}[SUCCESS] All container configurations saved.${NC}"
exit 0
