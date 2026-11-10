#!/usr/bin/env bash
# ==============================================================================
# Script Name : public_ip_tracker.sh
# Description : Detects public WAN IP using fallback reflection APIs and tracks
#               historical IP changes with timestamped log alerts.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, curl
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CACHE_FILE="/tmp/last_known_public_ip.txt"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Resolves external public IP and flags WAN IP address changes.

Options:
  -c, --cache <path>   Cache file path to remember last IP (default: /tmp/last_known_public_ip.txt)
  -h, --help           Show this help message and exit

Example:
  $(basename "$0") -c ~/.public_ip.cache
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--cache)
            CACHE_FILE="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Public WAN IP Tracker & Change Detector - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v curl &>/dev/null; then
    echo -e "${RED}[ERROR] 'curl' command not found.${NC}" >&2
    exit 1
fi

# Fallback API candidates
APIS=(
    "https://icanhazip.com"
    "https://ifconfig.me/ip"
    "https://api.ipify.org"
)

CURRENT_IP=""
for url in "${APIS[@]}"; do
    ip=$(curl -s --max-time 3 "$url" 2>/dev/null | tr -d '[:space:]' || true)
    if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        CURRENT_IP="$ip"
        break
    fi
done

if [[ -z "$CURRENT_IP" ]]; then
    echo -e "${RED}[ERROR] Could not resolve public IP via external APIs.${NC}" >&2
    exit 1
fi

echo -e "Current Public IP : ${GREEN}${CURRENT_IP}${NC}"

if [[ -f "$CACHE_FILE" ]]; then
    LAST_IP=$(cat "$CACHE_FILE" | tr -d '[:space:]')
    if [[ "$CURRENT_IP" != "$LAST_IP" ]]; then
        echo -e "${RED}[ALERT] Public IP changed!${NC} Old: ${LAST_IP} -> New: ${CURRENT_IP}"
        echo "$CURRENT_IP" > "$CACHE_FILE"
    else
        echo -e "${GREEN}[OK] Public IP unchanged since last check (${LAST_IP}).${NC}"
    fi
else
    echo -e "${CYAN}[INIT] Storing current IP to cache (${CACHE_FILE}).${NC}"
    echo "$CURRENT_IP" > "$CACHE_FILE"
fi

exit 0
