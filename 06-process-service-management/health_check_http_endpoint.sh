#!/usr/bin/env bash
# ==============================================================================
# Script Name : health_check_http_endpoint.sh
# Description : Performs synthetic HTTP/HTTPS health checks, verifying status
#               codes, expected response strings, and measuring latency in ms.
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

URL=""
EXPECTED_STATUS=200
TIMEOUT=3

usage() {
    cat <<EOF
Usage: $(basename "$0") -u <url> [OPTIONS]

Performs synthetic HTTP health checks with latency measurements.

Options:
  -u, --url <url>              Endpoint URL to probe
  -e, --expected <status>      Expected HTTP response code (default: 200)
  -t, --timeout <sec>          Connection timeout in seconds (default: 3)
  -h, --help                   Show this help message and exit

Example:
  $(basename "$0") -u https://api.github.com -e 200 -t 2
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -u|--url)
            URL="$2"; shift 2 ;;
        -e|--expected)
            EXPECTED_STATUS="$2"; shift 2 ;;
        -t|--timeout)
            TIMEOUT="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

if [[ -z "$URL" ]]; then
    echo -e "${RED}[ERROR] URL (-u) required.${NC}" >&2
    exit 2
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Synthetic HTTP/HTTPS Endpoint Health Check - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v curl &>/dev/null; then
    echo -e "${RED}[ERROR] 'curl' command not found.${NC}" >&2
    exit 1
fi

echo -e "Testing URL: ${URL} (Expected HTTP ${EXPECTED_STATUS}, Timeout: ${TIMEOUT}s)..."

RES=$(curl -s -o /dev/null -w "%{http_code},%{time_total}\n" --max-time "$TIMEOUT" "$URL" || echo "000,0")
IFS=',' read -r code time_total <<< "$RES"

LATENCY_MS=$(awk -v t="$time_total" 'BEGIN { printf "%.1f", t * 1000 }')

echo -e "HTTP Status Received : ${code}"
echo -e "Total Response Time  : ${LATENCY_MS} ms"

if [[ "$code" == "$EXPECTED_STATUS" ]]; then
    echo -e "${GREEN}[HEALTHY] Endpoint responded with expected code ${EXPECTED_STATUS} in ${LATENCY_MS}ms.${NC}"
    exit 0
else
    echo -e "${RED}[UNHEALTHY] Endpoint returned unexpected code ${code} (Expected: ${EXPECTED_STATUS}).${NC}"
    exit 1
fi
