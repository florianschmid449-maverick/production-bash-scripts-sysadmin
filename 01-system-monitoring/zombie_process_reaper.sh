#!/usr/bin/env bash
# ==============================================================================
# Script Name : zombie_process_reaper.sh
# Description : Detects defunct zombie processes, identifies their parent PIDs,
#               and attempts safe recovery via SIGCHLD signals.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, procps
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

REAP=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Scans the system process table for zombie (defunct) processes.

Options:
  -r, --reap   Send SIGCHLD to parent processes to prompt reaping
  -h, --help   Show this help message and exit

Example:
  $(basename "$0") --reap
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -r|--reap)
            REAP=true; shift ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Zombie Process Auditor & Reaper - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

# Find all processes in state 'Z'
ZOMBIES=$(ps -eo pid,ppid,stat,comm | awk '$3 ~ /^Z/ {print $1, $2, $4}')

if [[ -z "$ZOMBIES" ]]; then
    echo -e "${GREEN}[OK] No zombie processes detected on system.${NC}"
    exit 0
fi

echo -e "${YELLOW}[WARN] Defunct (Zombie) Processes Found:${NC}\n"
printf "%-10s %-10s %-30s\n" "PID" "PARENT PID" "COMMAND"
printf "%-10s %-10s %-30s\n" "---" "----------" "-------"

echo "$ZOMBIES" | while read -r pid ppid comm; do
    printf "%-10s %-10s %-30s\n" "$pid" "$ppid" "$comm"

    if [[ "$REAP" == true ]]; then
        echo -e "  -> ${CYAN}[ACTION] Sending SIGCHLD to parent PID ${ppid}...${NC}"
        kill -s SIGCHLD "$ppid" 2>/dev/null || echo -e "     ${RED}[FAIL] Could not signal parent PID ${ppid}.${NC}"
    fi
done

exit 0
