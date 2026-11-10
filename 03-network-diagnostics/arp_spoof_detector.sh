#!/usr/bin/env bash
# ==============================================================================
# Script Name : arp_spoof_detector.sh
# Description : Audits kernel ARP tables for duplicate MAC address mappings
#               to detect potential ARP cache poisoning and MITM attacks.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, ip or arp, awk
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

Audits local ARP neighbor tables for duplicate hardware MAC addresses.

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
echo -e "${CYAN} ARP Cache Poisoning & Duplicate MAC Detector - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

TMP_ARP=$(mktemp)
trap 'rm -f "$TMP_ARP"' EXIT INT TERM

# Read ARP entries via ip neigh or /proc/net/arp
if command -v ip &>/dev/null; then
    ip neigh show 2>/dev/null | awk '$5 ~ /^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$/ {print $1, $5}' > "$TMP_ARP"
elif [[ -f /proc/net/arp ]]; then
    tail -n +2 /proc/net/arp | awk '$4 ~ /^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$/ {print $1, $4}' > "$TMP_ARP"
fi

if [[ ! -s "$TMP_ARP" ]]; then
    echo -e "${YELLOW}[NOTICE] No active ARP neighbor entries found in local cache.${NC}"
    exit 0
fi

# Look for duplicate MAC addresses claiming multiple distinct IPs
DUPLICATE_MACS=$(awk '{print $2}' "$TMP_ARP" | sort | uniq -d || true)

if [[ -n "$DUPLICATE_MACS" ]]; then
    echo -e "${RED}[CRITICAL ALERT] Potential ARP Poisoning Detected!${NC}"
    echo -e "The following MAC addresses claim multiple IP addresses:\n"
    for mac in $DUPLICATE_MACS; do
        echo -e "${RED}MAC Address: ${mac}${NC}"
        grep "$mac" "$TMP_ARP" | awk '{print "  -> IP: " $1}'
    done
    exit 1
else
    echo -e "${GREEN}[OK] ARP table is consistent. No duplicate MAC addresses detected.${NC}"
    echo -e "Active Neighbor Count: $(wc -l < "$TMP_ARP")"
fi

exit 0
