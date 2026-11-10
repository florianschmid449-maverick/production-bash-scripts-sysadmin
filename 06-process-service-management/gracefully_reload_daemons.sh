#!/usr/bin/env bash
# ==============================================================================
# Script Name : gracefully_reload_daemons.sh
# Description : Validates daemon configuration syntax (nginx -t, apache2ctl configtest)
#               prior to issuing zero-downtime reloads to prevent service outages.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, systemctl
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DAEMON="nginx"

usage() {
    cat <<EOF
Usage: $(basename "$0") -d <daemon_name> [OPTIONS]

Performs pre-flight syntax verification and graceful service reload.

Options:
  -d, --daemon <name>   Daemon to reload: nginx, apache2, haproxy (default: nginx)
  -h, --help            Show this help message and exit

Example:
  sudo $(basename "$0") -d nginx
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--daemon)
            DAEMON="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Pre-Flight Syntax Check & Graceful Reload - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

# Check syntax based on daemon type
SYNTAX_PASS=false

case "$DAEMON" in
    nginx)
        if command -v nginx &>/dev/null; then
            echo -e "Testing Nginx configuration syntax..."
            nginx -t && SYNTAX_PASS=true
        fi
        ;;
    apache2|httpd)
        if command -v apache2ctl &>/dev/null; then
            apache2ctl configtest && SYNTAX_PASS=true
        elif command -v httpd &>/dev/null; then
            httpd -t && SYNTAX_PASS=true
        fi
        ;;
    haproxy)
        if command -v haproxy &>/dev/null && [[ -f /etc/haproxy/haproxy.cfg ]]; then
            haproxy -c -f /etc/haproxy/haproxy.cfg && SYNTAX_PASS=true
        fi
        ;;
    *)
        echo -e "${RED}[ERROR] Unsupported daemon '${DAEMON}'.${NC}" >&2
        exit 2
        ;;
esac

if [[ "$SYNTAX_PASS" == true ]]; then
    echo -e "${GREEN}[SYNTAX OK] Pre-flight tests passed.${NC}"
    if [[ "$EUID" -eq 0 ]] && command -v systemctl &>/dev/null; then
        echo -e "${YELLOW}[ACTION] Executing zero-downtime graceful reload...${NC}"
        systemctl reload "$DAEMON"
        echo -e "${GREEN}[SUCCESS] Service '${DAEMON}' reloaded without downtime.${NC}"
    else
        echo -e "${CYAN}[NOTICE] Syntax verified. Re-run as root to execute systemctl reload.${NC}"
    fi
else
    echo -e "${RED}[ABORTED] Configuration syntax errors detected. Service NOT reloaded.${NC}"
    exit 1
fi

exit 0
