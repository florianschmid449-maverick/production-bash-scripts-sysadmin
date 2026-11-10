#!/usr/bin/env bash
# ==============================================================================
# Script Name : auth_log_geo_tagger.sh
# Description : Extracts external IP addresses from authentication logs and
#               resolves country/ISP to map geographical threat distribution.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, curl or geoiplookup
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

MAX_IPS=5

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Resolves geographical origins of remote IP addresses found in system auth logs.

Options:
  -n, --count <num>   Number of top attacking IPs to geolocate (default: 5)
  -h, --help          Show this help message and exit

Example:
  $(basename "$0") -n 10
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--count)
            MAX_IPS="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Authentication Log Geographic Threat Resolver - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

# Find auth log or use sample
AUTH_LOG=""
for candidate in "/var/log/auth.log" "/var/log/secure"; do
    if [[ -f "$candidate" && -r "$candidate" ]]; then
        AUTH_LOG="$candidate"
        break
    fi
done

TMP_IPS=$(mktemp)
trap 'rm -f "$TMP_IPS"' EXIT INT TERM

if [[ -n "$AUTH_LOG" ]]; then
    grep -oE "([0-9]{1,3}\.){3}[0-9]{1,3}" "$AUTH_LOG" | grep -vE "^(127\.|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)" | sort | uniq -c | sort -rn | head -n "$MAX_IPS" > "$TMP_IPS" || true
fi

if [[ ! -s "$TMP_IPS" ]]; then
    echo -e "${YELLOW}[NOTICE] No external unauthorized login attempts recorded in accessible logs.${NC}"
    exit 0
fi

printf "%-10s %-18s %-30s\n" "ATTEMPTS" "IP ADDRESS" "GEOGRAPHIC LOCATION"
printf "%-10s %-18s %-30s\n" "--------" "----------" "-------------------"

while read -r count ip; do
    geo="Unknown / Offline"
    if command -v geoiplookup &>/dev/null; then
        geo=$(geoiplookup "$ip" 2>/dev/null | head -n 1 | cut -d: -f2 | xargs || echo "Unknown")
    elif command -v curl &>/dev/null; then
        geo=$(curl -s --max-time 2 "http://ip-api.com/line/${ip}?fields=country,city" 2>/dev/null | tr '\n' ' ' || echo "Lookup Failed")
    fi

    printf "%-10s %-18s %-30s\n" "$count" "$ip" "$geo"
done < "$TMP_IPS"

exit 0
