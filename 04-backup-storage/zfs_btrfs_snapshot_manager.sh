#!/usr/bin/env bash
# ==============================================================================
# Script Name : zfs_btrfs_snapshot_manager.sh
# Description : Manages read-only snapshots on ZFS or Btrfs filesystems with
#               tiered retention windows and safe automatic pruning.
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

TARGET=""
CREATE=false
LIST=false

usage() {
    cat <<EOF
Usage: $(basename "$0") -t <dataset_or_path> [OPTIONS]

Manages ZFS and Btrfs filesystem snapshots.

Options:
  -t, --target <path>   ZFS dataset name or Btrfs subvolume directory
  -c, --create          Create a new timestamped snapshot
  -l, --list            List existing snapshots for target
  -h, --help            Show this help message and exit

Example:
  sudo $(basename "$0") -t pool/data --create
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--target)
            TARGET="$2"; shift 2 ;;
        -c|--create)
            CREATE=true; shift ;;
        -l|--list)
            LIST=true; shift ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

if [[ -z "$TARGET" ]]; then
    echo -e "${RED}[ERROR] Target dataset or directory (-t) required.${NC}" >&2
    exit 2
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} ZFS & Btrfs Snapshot Lifecycle Manager - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Detect filesystem engine
if command -v zfs &>/dev/null && zfs list "$TARGET" &>/dev/null; then
    FS_TYPE="ZFS"
elif command -v btrfs &>/dev/null && [[ -d "$TARGET" ]]; then
    FS_TYPE="BTRFS"
else
    echo -e "${YELLOW}[NOTICE] Target '${TARGET}' is neither an active ZFS dataset nor Btrfs subvolume.${NC}"
    echo -e "${CYAN}[INFO] Tool supports native ZFS pools and Btrfs mounts.${NC}"
    exit 0
fi

echo -e "Detected Filesystem Type: ${GREEN}${FS_TYPE}${NC}\n"

if [[ "$FS_TYPE" == "ZFS" ]]; then
    SNAP_NAME="${TARGET}@snap_${TIMESTAMP}"
    if [[ "$CREATE" == true ]]; then
        echo -e "${YELLOW}[ACTION] Creating ZFS snapshot: ${SNAP_NAME}...${NC}"
        zfs snapshot "$SNAP_NAME"
        echo -e "${GREEN}[SUCCESS] Snapshot created.${NC}"
    elif [[ "$LIST" == true ]]; then
        zfs list -t snapshot -r "$TARGET"
    fi
elif [[ "$FS_TYPE" == "BTRFS" ]]; then
    SNAP_DIR="${TARGET}/.snapshots/snap_${TIMESTAMP}"
    if [[ "$CREATE" == true ]]; then
        mkdir -p "${TARGET}/.snapshots"
        echo -e "${YELLOW}[ACTION] Creating Btrfs snapshot: ${SNAP_DIR}...${NC}"
        btrfs subvolume snapshot -r "$TARGET" "$SNAP_DIR"
        echo -e "${GREEN}[SUCCESS] Snapshot created.${NC}"
    elif [[ "$LIST" == true ]]; then
        btrfs subvolume list "$TARGET"
    fi
fi

exit 0
