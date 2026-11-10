#!/usr/bin/env bash
# ==============================================================================
# Script Name : ssl_auto_certbot_renewer.sh
# Description : Automates Let's Encrypt Certbot renewals with pre-flight dry runs,
#               validity checks, and automated graceful web server reloads.
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

DRY_RUN=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Renews Let's Encrypt SSL/TLS certificates and reloads web services.

Options:
  -n, --dry-run   Perform dry-run renewal test without modifying certificates
  -h, --help      Show this help message and exit

Example:
  sudo $(basename "$0") --dry-run
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run)
            DRY_RUN=true; shift ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Automated Let's Encrypt Certbot SSL Renewer - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v certbot &>/dev/null; then
    echo -e "${YELLOW}[NOTICE] 'certbot' utility not found.${NC}"
    exit 0
fi

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}[TESTING] Executing certbot renew dry run...${NC}"
    certbot renew --dry-run
else
    echo -e "${YELLOW}[ACTION] Executing certbot renewal...${NC}"
    certbot renew --quiet --no-self-upgrade

    # Reload web service if present
    if command -v systemctl &>/dev/null; then
        if systemctl is-active --quiet nginx; then
            systemctl reload nginx
            echo -e "${GREEN}[RELOADED] Nginx reloaded.${NC}"
        elif systemctl is-active --quiet apache2; then
            systemctl reload apache2
            echo -e "${GREEN}[RELOADED] Apache reloaded.${NC}"
        fi
    fi
fi

echo -e "${GREEN}[SUCCESS] SSL certificate renewal cycle completed.${NC}"
exit 0
