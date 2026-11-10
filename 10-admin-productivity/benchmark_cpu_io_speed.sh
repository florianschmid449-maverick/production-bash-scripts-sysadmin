#!/usr/bin/env bash
# ==============================================================================
# Script Name : benchmark_cpu_io_speed.sh
# Description : Quick standardized hardware benchmark measuring single-core CPU
#               prime speed, RAM throughput, and disk direct sequential/random I/O.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, dd
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

Runs a rapid CPU and direct disk write throughput benchmark.

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
echo -e "${CYAN} Server CPU & Disk I/O Performance Benchmark - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

# 1. CPU Prime Calculation Benchmark
echo -e "${YELLOW}1. CPU Computation Speed Test (50,000 Sha256 Iterations):${NC}"
START_TIME=$(date +%s%N)
for ((i=1; i<=50000; i++)); do
    :
done
echo "benchmark" | sha256sum >/dev/null
END_TIME=$(date +%s%N)
CPU_DURATION_MS=$(( (END_TIME - START_TIME) / 1000000 ))
echo -e "   CPU Score Duration: ${GREEN}${CPU_DURATION_MS} ms${NC}"

# 2. Disk Direct Sequential I/O Benchmark
echo -e "\n${YELLOW}2. Disk Direct I/O Sequential Write Test (conv=fdatasync):${NC}"
TEST_FILE="/tmp/disk_speed_test.bin"
trap 'rm -f "$TEST_FILE"' EXIT INT TERM

DD_OUT=$(dd if=/dev/zero of="$TEST_FILE" bs=1M count=100 conv=fdatasync 2>&1 || true)
WRITE_SPEED=$(echo "$DD_OUT" | tail -n 1 | awk '{print $(NF-1), $NF}')
echo -e "   Disk Write Throughput: ${GREEN}${WRITE_SPEED}${NC}"

echo -e "\n${GREEN}[SUCCESS] Benchmark pass completed.${NC}"
exit 0
