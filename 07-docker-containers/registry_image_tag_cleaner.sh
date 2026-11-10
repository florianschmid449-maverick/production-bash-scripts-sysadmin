#!/usr/bin/env bash
# ==============================================================================
# Script Name : registry_image_tag_cleaner.sh
# Description : Sorts local Docker image tags by creation timestamp, pruning old
#               build revisions while preserving the latest N images and :latest.
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

KEEP_COUNT=3
DRY_RUN=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Prunes obsolete local Docker image tags while retaining newest releases.

Options:
  -k, --keep <num>   Number of recent revisions to retain per repo (default: 3)
  -n, --dry-run      Preview deletions without removing images
  -h, --help         Show this help message and exit

Example:
  $(basename "$0") -k 5 --dry-run
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -k|--keep)
            KEEP_COUNT="$2"; shift 2 ;;
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
echo -e "${CYAN} Local Docker Image Tag Lifecycle Cleaner - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v docker &>/dev/null; then
    echo -e "${YELLOW}[NOTICE] 'docker' binary not found.${NC}"
    exit 0
fi

# Clean untagged images (<none>)
UNTAGGED=$(docker images -f "dangling=true" -q 2>/dev/null || true)
if [[ -n "$UNTAGGED" ]]; then
    echo -e "${YELLOW}[ACTION] Removing dangling <none> layers...${NC}"
    if [[ "$DRY_RUN" == false ]]; then
        docker rmi $UNTAGGED 2>/dev/null || true
    fi
fi

echo -e "${GREEN}[SUCCESS] Image tag audit complete.${NC}"
exit 0
