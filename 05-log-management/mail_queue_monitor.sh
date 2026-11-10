#!/usr/bin/env bash
# ==============================================================================
# Script Name : mail_queue_monitor.sh
# Description : Audits Postfix/Exim mail transfer agent queues to detect stalled
#               messages, delivery backlogs, and spam outbreak bursts.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

WARN_LIMIT=50

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Audits local MTA mail queue depth and delivery bottlenecks.

Options:
  -w, --warn <count>   Queue warning threshold (default: 50)
  -h, --help           Show this help message and exit

Example:
  $(basename "$0") -w 100
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -w|--warn)
            WARN_LIMIT="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Mail Transfer Agent (MTA) Queue Monitor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

QUEUE_COUNT=0
MTA_TYPE=""

if command -v postqueue &>/dev/null; then
    MTA_TYPE="Postfix"
    QUEUE_COUNT=$(postqueue -p 2>/dev/null | tail -n 1 | awk '{print $5}' || echo 0)
    [[ ! "$QUEUE_COUNT" =~ ^[0-9]+$ ]] && QUEUE_COUNT=0
elif command -v mailq &>/dev/null; then
    MTA_TYPE="Sendmail/Exim"
    QUEUE_COUNT=$(mailq 2>/dev/null | grep -c '^[0-9A-Z]' || echo 0)
fi

if [[ -z "$MTA_TYPE" ]]; then
    echo -e "${YELLOW}[NOTICE] No standard MTA binary (postfix, mailq) found on this host.${NC}"
    exit 0
fi

echo -e "Detected MTA Engine : ${GREEN}${MTA_TYPE}${NC}"
echo -e "Queued Messages     : ${QUEUE_COUNT} (Threshold: ${WARN_LIMIT})"

if [[ "$QUEUE_COUNT" -ge "$WARN_LIMIT" ]]; then
    echo -e "${RED}[CRITICAL QUEUE BACKLOG] Mail queue exceeds threshold! Possible spam or relay block.${NC}"
    exit 1
else
    echo -e "${GREEN}[OK] Mail queue depth is within normal parameters.${NC}"
fi

exit 0
