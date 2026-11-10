#!/usr/bin/env bash
# ==============================================================================
# Script Name : ssh_tunnel_bastion_keeper.sh
# Description : Maintains persistent SSH port forwarding tunnels through bastion
#               jump hosts, automatically reconnecting upon network disconnects.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, ssh
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

LOCAL_PORT=8080
REMOTE_PORT=80
REMOTE_TARGET="127.0.0.1"
BASTION_HOST=""

usage() {
    cat <<EOF
Usage: $(basename "$0") -b <bastion_host> [OPTIONS]

Maintains persistent auto-reconnecting SSH port forwarding tunnels.

Options:
  -b, --bastion <host>      Bastion jump host (user@bastion.example.com)
  -l, --local <port>        Local bound port (default: 8080)
  -r, --remote <port>       Target service port (default: 80)
  -t, --target <host>       Target host accessible from bastion (default: 127.0.0.1)
  -h, --help                Show this help message and exit

Example:
  $(basename "$0") -b jump.corp.com -l 5432 -r 5432 -t db.internal
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -b|--bastion)
            BASTION_HOST="$2"; shift 2 ;;
        -l|--local)
            LOCAL_PORT="$2"; shift 2 ;;
        -r|--remote)
            REMOTE_PORT="$2"; shift 2 ;;
        -t|--target)
            REMOTE_TARGET="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

if [[ -z "$BASTION_HOST" ]]; then
    echo -e "${RED}[ERROR] Bastion host (-b) is required.${NC}" >&2
    exit 2
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Resilient SSH Bastion Port Forward Tunnel - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"
echo -e "Mapping localhost:${LOCAL_PORT} -> ${REMOTE_TARGET}:${REMOTE_PORT} via ${BASTION_HOST}"
echo -e "Press Ctrl+C to terminate tunnel.\n"

while true; do
    echo -e "${YELLOW}[CONNECTING] Establishing SSH port forward tunnel...${NC}"
    ssh -N -L "${LOCAL_PORT}:${REMOTE_TARGET}:${REMOTE_PORT}" \
        -o "ServerAliveInterval 15" \
        -o "ServerAliveCountMax 3" \
        -o "ExitOnForwardFailure yes" \
        "$BASTION_HOST" || true

    echo -e "${RED}[DISCONNECTED] Tunnel collapsed. Reconnecting in 5 seconds...${NC}"
    sleep 5
done
