#!/usr/bin/env bash
# ==============================================================================
# Script Name : bandwidth_speedtest_logger.sh
# Description : Measures download transfer speeds and latency against fast mirrors
#               and appends structured metrics to a CSV file for ISP auditing.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, curl, awk
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CSV_OUT="/tmp/bandwidth_speedtest.csv"
TEST_URL="http://speedtest.tele2.net/10MB.zip"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Tests download throughput and logs metrics to CSV.

Options:
  -o, --output <file>   Destination CSV output file (default: /tmp/bandwidth_speedtest.csv)
  -u, --url <url>       Reference test payload URL
  -h, --help            Show this help message and exit

Example:
  $(basename "$0") -o ~/speedtest.csv
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output)
            CSV_OUT="$2"; shift 2 ;;
        -u|--url)
            TEST_URL="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Bandwidth Speed & Latency Benchmark Logger - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v curl &>/dev/null; then
    echo -e "${RED}[ERROR] 'curl' command not found.${NC}" >&2
    exit 1
fi

echo -e "Testing throughput against: ${TEST_URL}..."

# Measure download speed using curl timing variables
# speed_download is in bytes/sec
CURL_RESULT=$(curl -s -w "%{time_connect},%{time_total},%{speed_download}\n" -o /dev/null --max-time 15 "$TEST_URL" || true)

if [[ -z "$CURL_RESULT" || "$CURL_RESULT" =~ ^0,0,0 ]]; then
    echo -e "${RED}[ERROR] Failed to download test payload.${NC}" >&2
    exit 1
fi

IFS=',' read -r time_connect time_total speed_bytes <<< "$CURL_RESULT"

SPEED_MBPS=$(awk -v b="$speed_bytes" 'BEGIN { printf "%.2f", (b * 8) / (1000 * 1000) }')
LATENCY_MS=$(awk -v c="$time_connect" 'BEGIN { printf "%.2f", c * 1000 }')
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo -e "Connection Latency: ${CYAN}${LATENCY_MS} ms${NC}"
echo -e "Download Bandwidth: ${GREEN}${SPEED_MBPS} Mbps${NC}"

# Ensure CSV header
if [[ ! -f "$CSV_OUT" ]]; then
    echo "timestamp,latency_ms,download_mbps,total_time_sec" > "$CSV_OUT"
fi

echo "${TIMESTAMP},${LATENCY_MS},${SPEED_MBPS},${time_total}" >> "$CSV_OUT"
echo -e "${GREEN}[SUCCESS] Recorded entry to ${CSV_OUT}.${NC}"

exit 0
