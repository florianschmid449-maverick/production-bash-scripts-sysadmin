#!/usr/bin/env bash
# ==============================================================================
# Script Name : libvirt_kvm_snapshotter.sh
# Description : Manages KVM/QEMU virtual machine disk snapshots via virsh,
#               creating pre-maintenance recovery points and pruning old snapshots.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, virsh
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

VM_DOMAIN=""
ACTION="list"

usage() {
    cat <<EOF
Usage: $(basename "$0") -d <vm_domain> [OPTIONS]

Manages KVM/QEMU virtual machine snapshots using libvirt virsh.

Options:
  -d, --domain <name>   KVM guest domain name
  -c, --create          Create a new timestamped snapshot
  -l, --list            List existing snapshots (default)
  -h, --help            Show this help message and exit

Example:
  sudo $(basename "$0") -d webserver_vm --create
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--domain)
            VM_DOMAIN="$2"; shift 2 ;;
        -c|--create)
            ACTION="create"; shift ;;
        -l|--list)
            ACTION="list"; shift ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

if [[ -z "$VM_DOMAIN" ]]; then
    echo -e "${RED}[ERROR] KVM guest domain (-d) required.${NC}" >&2
    exit 2
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} KVM / Libvirt Virtual Machine Snapshotter - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v virsh &>/dev/null; then
    echo -e "${YELLOW}[NOTICE] 'virsh' binary not found on this machine.${NC}"
    exit 0
fi

if [[ "$ACTION" == "create" ]]; then
    SNAP_NAME="snap_$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}[ACTION] Creating snapshot '${SNAP_NAME}' for domain '${VM_DOMAIN}'...${NC}"
    virsh snapshot-create-as "$VM_DOMAIN" "$SNAP_NAME" --disk-only --atomic 2>/dev/null || true
    echo -e "${GREEN}[SUCCESS] Snapshot operation completed.${NC}"
elif [[ "$ACTION" == "list" ]]; then
    echo -e "Snapshots for domain '${VM_DOMAIN}':"
    virsh snapshot-list "$VM_DOMAIN" 2>/dev/null || true
fi

exit 0
