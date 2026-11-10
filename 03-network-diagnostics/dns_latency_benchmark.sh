#!/usr/bin/env bash
# ==============================================================================
# Script Name : dns_latency_benchmark.sh
# Description : Benchmarks DNS query resolution latency across major upstream
#               resolvers (Cloudflare, Google, Quad9, OpenDNS) to select fastest.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, dig or drill
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DOMAIN="google.com"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Benchmarks DNS query response times across popular public DNS resolvers.

Options:
  -d, --domain <name>   Target domain to resolve (default: google.com)
  -h, --help            Show this help message and exit

Example:
  $(basename "$0") -d github.com
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--domain)
            DOMAIN="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} DNS Resolver Latency Benchmark - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"
echo -e "Target Resolution Domain: ${DOMAIN}\n"

if ! command -v dig &>/dev/null; then
    echo -e "${RED}[ERROR] 'dig' command not found. Please install dnsutils/bind-utils.${NC}" >&2
    exit 1
fi

declare -A RESOLVERS=(
    ["Cloudflare (1.1.1.1)"]="1.1.1.1"
    ["Google (8.8.8.8)"]="8.8.8.8"
    ["Quad9 (9.9.9.9)"]="9.9.9.9"
    ["OpenDNS (208.67.222.222)"]="208.67.222.222"
)

printf "%-28s %-18s %-15s\n" "RESOLVER" "SERVER IP" "QUERY TIME"
printf "%-28s %-18s %-15s\n" "--------" "---------" "----------"

for name in "${!RESOLVERS[@]}"; do
    ip="${RESOLVERS[$name]}"
    # Query with dig
    query_time=$(dig @"$ip" "$DOMAIN" +noall +stats 2>/dev/null | grep "Query time:" | awk '{print $4, $5}' || echo "Timeout")
    if [[ "$query_time" != "Timeout" ]]; then
        printf "%-28s %-18s " "$name" "$ip"
        echo -e "${GREEN}${query_time}${NC}"
    else
        printf "%-28s %-18s " "$name" "$ip"
        echo -e "${RED}TIMEOUT${NC}"
    fi
done

exit 0
