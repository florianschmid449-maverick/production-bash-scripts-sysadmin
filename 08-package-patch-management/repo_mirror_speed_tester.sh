#!/usr/bin/env bash
# ==============================================================================
# Script Name : repo_mirror_speed_tester.sh
# Description : Benchmarks connection latency and transfer speeds across distribution
#               mirrors to identify the fastest mirror for apt/dnf repositories.
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

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Benchmarks latency and throughput across official package repository mirrors.

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
echo -e "${CYAN} Package Repository Mirror Speed Benchmark - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v curl &>/dev/null; then
    echo -e "${RED}[ERROR] 'curl' command not found.${NC}" >&2
    exit 1
fi

# List of major public mirror nodes
MIRRORS=(
    "http://deb.debian.org/debian/"
    "http://archive.ubuntu.com/ubuntu/"
    "http://mirror.facebook.net/fedora/"
    "https://cloudflare.cdn.openbsd.org/"
)

printf "%-38s %-15s\n" "MIRROR URL" "LATENCY (ms)"
printf "%-38s %-15s\n" "----------" "------------"

for url in "${MIRRORS[@]}"; do
    time_total=$(curl -s -o /dev/null -w "%{time_connect}\n" --max-time 3 "$url" || echo "0")
    if [[ "$time_total" != "0" ]]; then
        latency_ms=$(awk -v t="$time_total" 'BEGIN { printf "%.1f", t * 1000 }')
        printf "%-38s " "$url"
        echo -e "${GREEN}${latency_ms} ms${NC}"
    else
        printf "%-38s " "$url"
        echo -e "${RED}TIMEOUT${NC}"
    fi
done

exit 0
