#!/usr/bin/env bash
# ==============================================================================
# Script Name : cloudflare_dns_updater.sh
# Description : Dynamic DNS (DDNS) updater script using Cloudflare API v4 to update
#               an A record automatically whenever the host public WAN IP changes.
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

ZONE_ID=""
RECORD_NAME=""
API_TOKEN=""

usage() {
    cat <<EOF
Usage: $(basename "$0") -z <zone_id> -r <record_name> -t <api_token> [OPTIONS]

Updates Cloudflare DNS A-record with current public WAN IP.

Options:
  -z, --zone <id>        Cloudflare DNS Zone ID
  -r, --record <name>    DNS record name (e.g. home.domain.com)
  -t, --token <token>    Cloudflare API Bearer Token
  -h, --help             Show this help message and exit

Example:
  $(basename "$0") -z 12345 -r vpn.example.com -t secret_token
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -z|--zone)
            ZONE_ID="$2"; shift 2 ;;
        -r|--record)
            RECORD_NAME="$2"; shift 2 ;;
        -t|--token)
            API_TOKEN="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

if [[ -z "$ZONE_ID" || -z "$RECORD_NAME" || -z "$API_TOKEN" ]]; then
    echo -e "${RED}[ERROR] Zone ID (-z), Record (-r), and API Token (-t) are required.${NC}" >&2
    exit 2
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Cloudflare Dynamic DNS (DDNS) Auto-Updater - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

# Detect current WAN IP
WAN_IP=$(curl -s https://icanhazip.com | tr -d '[:space:]')
echo -e "Current Public IP : ${GREEN}${WAN_IP}${NC}"
echo -e "Updating Cloudflare record: ${RECORD_NAME}..."

# Query Cloudflare API for Record ID
RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=A&name=${RECORD_NAME}" \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -H "Content-Type: application/json" | grep -oE '"id":"[a-f0-9]+"' | head -n 1 | cut -d: -f2 | tr -d '"' || true)

if [[ -z "$RECORD_ID" ]]; then
    echo -e "${RED}[ERROR] Could not find DNS record for ${RECORD_NAME}.${NC}" >&2
    exit 1
fi

# Update Record
RES=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"${RECORD_NAME}\",\"content\":\"${WAN_IP}\",\"ttl\":120,\"proxied\":false}")

if echo "$RES" | grep '"success":true' >/dev/null; then
    echo -e "${GREEN}[SUCCESS] Cloudflare DNS record ${RECORD_NAME} updated to ${WAN_IP}.${NC}"
else
    echo -e "${RED}[ERROR] API update failed: ${RES}${NC}" >&2
    exit 1
fi

exit 0
