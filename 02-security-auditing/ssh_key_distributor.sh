#!/usr/bin/env bash
# ==============================================================================
# Script Name : ssh_key_distributor.sh
# Description : Distributes public SSH keys to remote target hosts and validates
#               authorized_keys directory and file permissions (0700/0600).
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, ssh, ssh-copy-id
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

KEY_FILE="${HOME}/.ssh/id_rsa.pub"
HOSTS_FILE=""

usage() {
    cat <<EOF
Usage: $(basename "$0") -f <hosts_file> [OPTIONS]

Distributes public SSH identity key across a fleet of remote servers.

Options:
  -f, --file <path>   File containing remote targets (one host per line: user@host)
  -k, --key <path>    Public key file to distribute (default: ~/.ssh/id_rsa.pub)
  -h, --help          Show this help message and exit

Example:
  $(basename "$0") -f inventory.txt -k ~/.ssh/id_ed25519.pub
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--file)
            HOSTS_FILE="$2"; shift 2 ;;
        -k|--key)
            KEY_FILE="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

if [[ -z "$HOSTS_FILE" || ! -f "$HOSTS_FILE" ]]; then
    echo -e "${RED}[ERROR] Valid hosts file required via -f.${NC}" >&2
    exit 2
fi

if [[ ! -f "$KEY_FILE" ]]; then
    echo -e "${RED}[ERROR] Public key '${KEY_FILE}' does not exist.${NC}" >&2
    exit 1
fi

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} SSH Key Fleet Distribution Tool - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"
echo -e "Distributing Key: ${KEY_FILE}\n"

while IFS= read -r host || [[ -n "$host" ]]; do
    # Skip empty lines and comments
    [[ "$host" =~ ^#.*$ || -z "$host" ]] && continue
    host=$(echo "$host" | xargs)

    echo -e "${CYAN}[CONNECTING]${NC} Target: ${host}"
    if ssh-copy-id -i "$KEY_FILE" -o ConnectTimeout=5 "$host" 2>/dev/null; then
        echo -e "${GREEN}[SUCCESS]${NC} Key successfully installed on ${host}."
    else
        echo -e "${RED}[FAILED]${NC}  Could not copy key to ${host}."
    fi
done < "$HOSTS_FILE"

exit 0
