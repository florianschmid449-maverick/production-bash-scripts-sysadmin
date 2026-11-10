#!/usr/bin/env bash
# ==============================================================================
# Script Name : parallel_task_runner.sh
# Description : Pure-Bash parallel task manager with worker pool concurrency
#               control (e.g. max 4 workers) without external tools like GNU parallel.
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

MAX_JOBS=4
CMD_FILE=""

usage() {
    cat <<EOF
Usage: $(basename "$0") -f <task_file> [OPTIONS]

Executes a list of shell commands in parallel with bounded worker concurrency.

Options:
  -f, --file <path>   File containing commands to run (one command per line)
  -j, --jobs <count>  Maximum concurrent worker jobs (default: 4)
  -h, --help          Show this help message and exit

Example:
  $(basename "$0") -f commands.txt -j 8
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--file)
            CMD_FILE="$2"; shift 2 ;;
        -j|--jobs)
            MAX_JOBS="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

if [[ -z "$CMD_FILE" || ! -f "$CMD_FILE" ]]; then
    echo -e "${RED}[ERROR] Valid task file (-f) required.${NC}" >&2
    exit 2
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Pure-Bash Parallel Worker Task Runner - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"
echo -e "Executing tasks from '${CMD_FILE}' (Max Workers: ${MAX_JOBS})...\n"

RUNNING=0
while IFS= read -r cmd || [[ -n "$cmd" ]]; do
    [[ "$cmd" =~ ^#.*$ || -z "$cmd" ]] && continue

    # Manage concurrency pool
    while [[ $(jobs -r -p | wc -l) -ge "$MAX_JOBS" ]]; do
        sleep 0.1
    done

    echo -e "${CYAN}[DISPATCH]${NC} $cmd"
    (
        eval "$cmd" >/dev/null 2>&1 && \
            echo -e "${GREEN}[COMPLETED]${NC} $cmd" || \
            echo -e "${RED}[FAILED]${NC}    $cmd"
    ) &

done < "$CMD_FILE"

# Wait for remaining background jobs
wait
echo -e "\n${GREEN}[SUCCESS] All parallel worker tasks finished.${NC}"
exit 0
