#!/usr/bin/env bash
# ==============================================================================
# Script Name : journalctl_critical_exporter.sh
# Description : Queries systemd journal for priority levels 0-3 (emerg, alert,
#               crit, err) and exports an incident post-mortem digest.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, journalctl
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SINCE="24 hours ago"
OUT_FILE="/tmp/systemd_critical_incident_report.txt"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Exports systemd journal emergency, critical, and error events to an incident report.

Options:
  -s, --since <time>    Timeframe expression (default: '24 hours ago')
  -o, --output <path>   Destination output file path (default: /tmp/systemd_critical_incident_report.txt)
  -h, --help            Show this help message and exit

Example:
  $(basename "$0") -s "2 hours ago" -o /var/log/incident.log
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--since)
            SINCE="$2"; shift 2 ;;
        -o|--output)
            OUT_FILE="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Systemd Critical Journal Incident Exporter - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v journalctl &>/dev/null; then
    echo -e "${RED}[ERROR] 'journalctl' command not found.${NC}" >&2
    exit 1
fi

echo -e "Querying system events with priority <= 3 (err) since '${SINCE}'..."

# Query journalctl -p 0..3 (emerg to err)
if journalctl -p 0..3 --since "$SINCE" --no-pager > "$OUT_FILE" 2>/dev/null; then
    EVENT_COUNT=$(wc -l < "$OUT_FILE")
    if [[ "$EVENT_COUNT" -gt 0 ]]; then
        echo -e "${RED}[ALERT] Found ${EVENT_COUNT} critical/error event(s).${NC}"
        echo -e "${GREEN}[SUCCESS] Report exported to: ${OUT_FILE}${NC}"
        echo -e "\nSample entries:"
        head -n 5 "$OUT_FILE"
    else
        echo -e "${GREEN}[OK] Zero critical system errors logged since ${SINCE}.${NC}"
    fi
else
    echo -e "${YELLOW}[NOTICE] Could not query systemd journal (insufficient permissions or inactive daemon).${NC}"
fi

exit 0
