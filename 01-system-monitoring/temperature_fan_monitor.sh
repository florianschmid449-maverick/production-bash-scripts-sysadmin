#!/usr/bin/env bash
# ==============================================================================
# Script Name : temperature_fan_monitor.sh
# Description : Reads CPU hardware thermal zones and fan sensors.
#               Provides immediate temperature reporting and throttling alerts.
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

ALERT_TEMP=80 # Celsius

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Monitors hardware temperature zones via sysfs and sensors.

Options:
  -t, --threshold <deg_c>   Alert temperature in Celsius (default: 80C)
  -h, --help                Show this help message and exit

Example:
  $(basename "$0") -t 75
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--threshold)
            ALERT_TEMP="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Hardware Thermal & Fan Sensor Monitor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

FOUND_SENSORS=false

# Method 1: Check /sys/class/thermal
if compgen -G "/sys/class/thermal/thermal_zone*" > /dev/null; then
    for zone in /sys/class/thermal/thermal_zone*; do
        if [[ -f "$zone/temp" && -f "$zone/type" ]]; then
            FOUND_SENSORS=true
            raw_temp=$(cat "$zone/temp")
            type=$(cat "$zone/type")
            temp_c=$((raw_temp / 1000))

            if [[ "$temp_c" -ge "$ALERT_TEMP" ]]; then
                echo -e "  ${RED}[CRITICAL OVERHEAT]${NC} ${type} (${zone##*/}): ${temp_c}°C (Threshold: ${ALERT_TEMP}°C)"
            elif [[ "$temp_c" -ge "$((ALERT_TEMP - 10))" ]]; then
                echo -e "  ${YELLOW}[WARNING HIGH]${NC}      ${type} (${zone##*/}): ${temp_c}°C"
            else
                echo -e "  ${GREEN}[NORMAL]${NC}            ${type} (${zone##*/}): ${temp_c}°C"
            fi
        fi
    done
fi

# Method 2: Fallback to lm-sensors if installed
if [[ "$FOUND_SENSORS" == false ]] && command -v sensors &>/dev/null; then
    echo -e "${CYAN}[INFO] Reading via lm-sensors:${NC}"
    sensors
    FOUND_SENSORS=true
fi

if [[ "$FOUND_SENSORS" == false ]]; then
    echo -e "${YELLOW}[NOTICE] No hardware thermal sensors accessible (common in virtualized containers/VMs).${NC}"
fi

exit 0
