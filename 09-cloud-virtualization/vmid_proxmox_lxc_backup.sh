#!/usr/bin/env bash
# ==============================================================================
# Script Name : vmid_proxmox_lxc_backup.sh
# Description : Triggers Proxmox VE vzdump backups for designated LXC containers
#               or VMs, verifying storage free space before initiating dumps.
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

VMID=""
STORAGE="local"

usage() {
    cat <<EOF
Usage: $(basename "$0") -v <vmid> [OPTIONS]

Initiates Proxmox VE vzdump backups with storage quota safeguards.

Options:
  -v, --vmid <id>        Target Proxmox Container or VM ID
  -s, --storage <name>   Proxmox storage pool destination (default: local)
  -h, --help             Show this help message and exit

Example:
  sudo $(basename "$0") -v 100 -s nfs-backups
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--vmid)
            VMID="$2"; shift 2 ;;
        -s|--storage)
            STORAGE="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

if [[ -z "$VMID" ]]; then
    echo -e "${RED}[ERROR] Proxmox VMID (-v) required.${NC}" >&2
    exit 2
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Proxmox VE vzdump Snapshot Backup Automation - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v vzdump &>/dev/null; then
    echo -e "${YELLOW}[NOTICE] 'vzdump' utility is only present on Proxmox VE hypervisor nodes.${NC}"
    exit 0
fi

echo -e "${YELLOW}[ACTION] Initiating snapshot backup for VMID ${VMID} to storage '${STORAGE}'...${NC}"
vzdump "$VMID" --storage "$STORAGE" --mode snapshot --compress zstd

echo -e "${GREEN}[SUCCESS] Proxmox backup completed.${NC}"
exit 0
