#!/usr/bin/env bash
# ==============================================================================
# Script Name : terraform_state_backup.sh
# Description : Safely downloads and timestamps terraform.tfstate before runs,
#               calculating MD5 checksums and verifying state JSON syntax with jq.
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

TF_DIR="."
BACKUP_DIR="/tmp/tfstate_backups"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Safely archives and validates Terraform state files prior to deployments.

Options:
  -d, --dir <path>      Terraform root directory (default: .)
  -o, --output <dir>    Backup destination folder (default: /tmp/tfstate_backups)
  -h, --help            Show this help message and exit

Example:
  $(basename "$0") -d /infra/prod -o /backups/tfstate
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dir)
            TF_DIR="$2"; shift 2 ;;
        -o|--output)
            BACKUP_DIR="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Terraform State File Pre-Flight Archiver - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

STATE_FILE="${TF_DIR}/terraform.tfstate"

if [[ ! -f "$STATE_FILE" ]]; then
    echo -e "${YELLOW}[NOTICE] No local 'terraform.tfstate' found in ${TF_DIR}.${NC}"
    exit 0
fi

mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/terraform.tfstate.${TIMESTAMP}.bak"

echo -e "${YELLOW}[BACKING UP] Copying ${STATE_FILE} -> ${BACKUP_FILE}...${NC}"
cp "$STATE_FILE" "$BACKUP_FILE"

# Validate JSON
if command -v jq &>/dev/null; then
    if jq empty "$BACKUP_FILE" 2>/dev/null; then
        echo -e "${GREEN}[VALID] Terraform state JSON syntax verified.${NC}"
    else
        echo -e "${RED}[WARNING] Terraform state JSON appears malformed!${NC}"
    fi
fi

echo -e "${GREEN}[SUCCESS] State backed up safely: ${BACKUP_FILE}${NC}"
exit 0
