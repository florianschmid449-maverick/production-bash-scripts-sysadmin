#!/usr/bin/env bash
# ==============================================================================
# Script Name : uptime_sla_reporter.sh
# Description : Computes continuous uptime, reboot history, and estimated
#               monthly availability percentage for SLA compliance tracking.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, procps, awk
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DAYS=30

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Generates system uptime statistics and estimated SLA availability metrics.

Options:
  -d, --days <count>   Audit timeframe in days (default: 30)
  -h, --help           Show this help message and exit

Example:
  $(basename "$0") --days 90
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--days)
            DAYS="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Uptime & SLA Availability Reporter - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

# Read current uptime from /proc/uptime (first field: total seconds)
read -r UPTIME_SECONDS _ < /proc/uptime
UPTIME_DAYS=$(awk -v s="$UPTIME_SECONDS" 'BEGIN { printf "%.1f", s / 86400 }')
UPTIME_HUMAN=$(uptime -p 2>/dev/null || echo "${UPTIME_DAYS} days")

echo -e "Current System State:"
echo -e "  System Uptime      : ${GREEN}${UPTIME_HUMAN}${NC} (${UPTIME_DAYS} days)"
echo -e "  Analysis Period    : Past ${DAYS} days"

# Audit reboot count via 'last reboot' if available
REBOOT_COUNT=0
if command -v last &>/dev/null; then
    REBOOT_COUNT=$(last reboot 2>/dev/null | grep -c 'system boot' || true)
fi

echo -e "  Recorded Reboots   : ${YELLOW}${REBOOT_COUNT}${NC}"

# Calculate approximate SLA uptime percentage
# Assuming 3 minutes (180s) of downtime per recorded reboot
TOTAL_PERIOD_SECONDS=$((DAYS * 86400))
ESTIMATED_DOWNTIME_SECONDS=$((REBOOT_COUNT * 180))

if [[ "$ESTIMATED_DOWNTIME_SECONDS" -gt "$TOTAL_PERIOD_SECONDS" ]]; then
    ESTIMATED_DOWNTIME_SECONDS="$TOTAL_PERIOD_SECONDS"
fi

UPTIME_RATIO=$(awk -v total="$TOTAL_PERIOD_SECONDS" -v down="$ESTIMATED_DOWNTIME_SECONDS" \
    'BEGIN { printf "%.4f", ((total - down) / total) * 100 }')

echo -e "\nSLA Compliance Estimate:"
if (( $(awk -v r="$UPTIME_RATIO" 'BEGIN { print (r >= 99.9) }') )); then
    echo -e "  Availability Metric: ${GREEN}${UPTIME_RATIO}% (Exceeds Three Nines SLA)${NC}"
else
    echo -e "  Availability Metric: ${YELLOW}${UPTIME_RATIO}%${NC}"
fi

exit 0
