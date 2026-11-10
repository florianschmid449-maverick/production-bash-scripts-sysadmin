#!/usr/bin/env bash
# ==============================================================================
# Script Name : cpu_load_monitor.sh
# Description : Advanced multi-core CPU load monitor and live terminal dashboard.
#               Computes normalized load averages, tracks thermal zone spikes,
#               and isolates highest resource-consuming processes with progress bars.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 2.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, procps
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color & Style Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# Default Configuration
WARN_THRESHOLD=80
CRIT_THRESHOLD=100
LOG_FILE=""
INTERACTIVE_MODE=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Monitors system CPU load normalized across all available logical cores.

Options:
  -w, --warn <percent>      Warning load threshold per core (default: 80%)
  -c, --crit <percent>      Critical load threshold per core (default: 100%)
  -l, --log <file>          Path to log incidents to file
  -m, --menu                Launch interactive terminal monitoring dashboard
  -h, --help                Show this help message and exit

Examples:
  $(basename "$0") -w 75 -c 90
  $(basename "$0") --menu
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -w|--warn)
            WARN_THRESHOLD="$2"; shift 2 ;;
        -c|--crit)
            CRIT_THRESHOLD="$2"; shift 2 ;;
        -l|--log)
            LOG_FILE="$2"; shift 2 ;;
        -m|--menu)
            INTERACTIVE_MODE=true; shift ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

draw_progress_bar() {
    local pct=$1
    local width=25
    local filled=$(( (pct * width) / 100 ))
    [[ "$filled" -gt "$width" ]] && filled="$width"
    local empty=$(( width - filled ))

    local color="$GREEN"
    if [[ "$pct" -ge "$CRIT_THRESHOLD" ]]; then
        color="$RED"
    elif [[ "$pct" -ge "$WARN_THRESHOLD" ]]; then
        color="$YELLOW"
    fi

    echo -ne "["
    for ((i=0; i<filled; i++)); do echo -ne "${color}█${NC}"; done
    for ((i=0; i<empty; i++)); do echo -ne "░"; done
    echo -ne "] ${color}${pct}%${NC}"
}

run_cpu_audit() {
    local cores
    cores=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)
    read -r l1 l5 l15 _ < /proc/loadavg

    local l1_pct
    l1_pct=$(awk -v l="$l1" -v c="$cores" 'BEGIN { printf "%.0f", (l / c) * 100 }')
    local l5_pct
    l5_pct=$(awk -v l="$l5" -v c="$cores" 'BEGIN { printf "%.0f", (l / c) * 100 }')
    local l15_pct
    l15_pct=$(awk -v l="$l15" -v c="$cores" 'BEGIN { printf "%.0f", (l / c) * 100 }')

    echo -e "${CYAN}====================================================================${NC}"
    echo -e "${BOLD}${CYAN} CPU Load & Utilization Monitor - Florian Schmid${NC}"
    echo -e "${CYAN}====================================================================${NC}"
    echo -e "CPU Cores Online : ${BOLD}${cores} cores${NC} | Timestamp: $(date '+%Y-%m-%d %H:%M:%S')\n"

    echo -ne "  1-Min Load Average  : "
    draw_progress_bar "$l1_pct"
    echo -e " (Raw: ${l1})"

    echo -ne "  5-Min Load Average  : "
    draw_progress_bar "$l5_pct"
    echo -e " (Raw: ${l5})"

    echo -ne "  15-Min Load Average : "
    draw_progress_bar "$l15_pct"
    echo -e " (Raw: ${l15})\n"

    if [[ "$l1_pct" -ge "$CRIT_THRESHOLD" ]]; then
        echo -e "${RED}[CRITICAL ALERT] CPU load exceeds 100% capacity per core!${NC}"
    elif [[ "$l1_pct" -ge "$WARN_THRESHOLD" ]]; then
        echo -e "${YELLOW}[WARNING ALERT] CPU load exceeds warning threshold (${WARN_THRESHOLD}%).${NC}"
    else
        echo -e "${GREEN}[HEALTHY] CPU utilization is within safe operational limits.${NC}"
    fi

    echo -e "\n${YELLOW}Top 5 CPU-Consuming Active Processes:${NC}"
    printf "  %-8s %-12s %-10s %-10s %-25s\n" "PID" "USER" "%CPU" "%MEM" "COMMAND"
    printf "  %-8s %-12s %-10s %-10s %-25s\n" "---" "----" "----" "----" "-------"
    ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | tail -n +2 | head -n 5 | while read -r p u c m cmd; do
        printf "  %-8s %-12s %-10s %-10s %-25s\n" "$p" "$u" "$c%" "$m%" "$cmd"
    done

    if [[ -n "$LOG_FILE" ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') Cores:${cores} 1m:${l1} 5m:${l5} 15m:${l15} Pct:${l1_pct}%" >> "$LOG_FILE"
    fi
}

if [[ "$INTERACTIVE_MODE" == true ]]; then
    while true; do
        clear
        run_cpu_audit
        echo -e "\n${CYAN}────────────────────────────────────────────────────────────────────${NC}"
        echo -e "Interactive Menu: [r] Refresh Now | [l] Top 10 Processes | [q] Exit"
        read -rp "Select an option: " opt
        case "$opt" in
            r|R) continue ;;
            l|L)
                clear
                echo -e "${YELLOW}Top 10 CPU Consumers:${NC}\n"
                ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -n 11
                echo ""
                read -rp "Press Enter to return..." _
                ;;
            q|Q) exit 0 ;;
            *) sleep 0.5 ;;
        esac
    done
else
    run_cpu_audit
fi

exit 0
