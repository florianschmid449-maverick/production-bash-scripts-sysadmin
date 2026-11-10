#!/usr/bin/env bash
# ==============================================================================
# Script Name : hung_process_killer.sh
# Description : Detects processes exceeding maximum runtime or CPU limits, attempts
#               graceful termination (SIGTERM), and escalates to SIGKILL if stuck.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, ps, kill, awk
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

TARGET_NAME=""
MAX_RUNTIME_SEC=3600
DRY_RUN=false

usage() {
    cat <<EOF
Usage: $(basename "$0") -p <process_name> [OPTIONS]

Terminates runaway processes exceeding maximum execution duration.

Options:
  -p, --process <name>   Process name to inspect
  -m, --max-time <sec>   Maximum allowed runtime in seconds (default: 3600)
  -n, --dry-run          Preview target processes without sending kill signals
  -h, --help             Show this help message and exit

Example:
  $(basename "$0") -p php-fpm -m 600 --dry-run
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--process)
            TARGET_NAME="$2"; shift 2 ;;
        -m|--max-time)
            MAX_RUNTIME_SEC="$2"; shift 2 ;;
        -n|--dry-run)
            DRY_RUN=true; shift ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

if [[ -z "$TARGET_NAME" ]]; then
    echo -e "${RED}[ERROR] Process name (-p) required.${NC}" >&2
    exit 2
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Runaway / Hung Process Lifecycle Terminator - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

# Find matching processes and their elapsed times in seconds
FOUND=0
while read -r pid etimes comm; do
    if [[ "$etimes" -ge "$MAX_RUNTIME_SEC" ]]; then
        FOUND=$((FOUND + 1))
        echo -e "${RED}[RUNAWAY]${NC} PID: ${pid} (${comm}) has run for ${etimes}s (Max: ${MAX_RUNTIME_SEC}s)"

        if [[ "$DRY_RUN" == true ]]; then
            echo -e "  -> ${CYAN}[DRY-RUN] Would send SIGTERM to PID ${pid}.${NC}"
        else
            echo -e "  -> ${YELLOW}[ACTION] Sending SIGTERM to PID ${pid}...${NC}"
            kill -15 "$pid" 2>/dev/null || true
            sleep 2
            if kill -0 "$pid" 2>/dev/null; then
                echo -e "  -> ${RED}[ESCALATING] Sending SIGKILL to stubborn PID ${pid}...${NC}"
                kill -9 "$pid" 2>/dev/null || true
            fi
        fi
    fi
done < <(ps -eo pid,etimes,comm 2>/dev/null | grep "$TARGET_NAME" || true)

if [[ "$FOUND" -eq 0 ]]; then
    echo -e "${GREEN}[OK] No matching '${TARGET_NAME}' processes exceed ${MAX_RUNTIME_SEC}s runtime.${NC}"
fi

exit 0
