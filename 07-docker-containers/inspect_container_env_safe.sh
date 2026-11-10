#!/usr/bin/env bash
# ==============================================================================
# Script Name : inspect_container_env_safe.sh
# Description : Dumps container environment variables while automatically redacting
#               sensitive keys (PASS, KEY, SECRET, TOKEN) to prevent secret leakage.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, docker
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CONTAINER=""

usage() {
    cat <<EOF
Usage: $(basename "$0") -c <container_name_or_id> [OPTIONS]

Safely inspects container environment variables with automated credential masking.

Options:
  -c, --container <id>   Container identifier or name
  -h, --help             Show this help message and exit

Example:
  $(basename "$0") -c web_api
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--container)
            CONTAINER="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

if [[ -z "$CONTAINER" ]]; then
    echo -e "${RED}[ERROR] Container (-c) required.${NC}" >&2
    exit 2
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Sanitized Container Environment Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v docker &>/dev/null; then
    echo -e "${RED}[ERROR] 'docker' binary not found.${NC}" >&2
    exit 1
fi

echo -e "Inspecting environment for container: ${CONTAINER}...\n"

docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$CONTAINER" 2>/dev/null | while read -r line; do
    key="${line%%=*}"
    val="${line#*=}"

    if [[ "$key" =~ (PASS|PASSWORD|SECRET|KEY|TOKEN|AUTH|CREDENTIAL) ]]; then
        echo -e "  ${YELLOW}${key}${NC}=${RED}******** [REDACTED]${NC}"
    else
        echo -e "  ${GREEN}${key}${NC}=${val}"
    fi
done

exit 0
