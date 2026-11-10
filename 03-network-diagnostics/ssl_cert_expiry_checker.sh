#!/usr/bin/env bash
# ==============================================================================
# Script Name : ssl_cert_expiry_checker.sh
# Description : Connects to TLS/SSL endpoints via OpenSSL, calculates remaining
#               days before expiration, and warns if renewal is due (<30 days).
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, openssl, date
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

HOST="github.com"
PORT=443
WARN_DAYS=30

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Audits SSL/TLS certificate validity and expiration dates.

Options:
  -H, --host <domain>    Remote hostname/domain (default: github.com)
  -p, --port <port>      Remote TLS port (default: 443)
  -w, --warn <days>      Warning threshold in days (default: 30)
  -h, --help             Show this help message and exit

Example:
  $(basename "$0") -H mydomain.org -p 443 -w 14
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -H|--host)
            HOST="$2"; shift 2 ;;
        -p|--port)
            PORT="$2"; shift 2 ;;
        -w|--warn)
            WARN_DAYS="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} TLS / SSL Certificate Expiration Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"
echo -e "Auditing Target: ${HOST}:${PORT}\n"

if ! command -v openssl &>/dev/null; then
    echo -e "${RED}[ERROR] 'openssl' command not found.${NC}" >&2
    exit 1
fi

CERT_DATES=$(echo | openssl s_client -servername "$HOST" -connect "${HOST}:${PORT}" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || true)

if [[ -z "$CERT_DATES" ]]; then
    echo -e "${RED}[ERROR] Could not establish TLS handshake or retrieve certificate from ${HOST}:${PORT}.${NC}" >&2
    exit 1
fi

NOT_AFTER=$(echo "$CERT_DATES" | grep '^notAfter=' | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "$NOT_AFTER" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$NOT_AFTER" +%s 2>/dev/null || echo 0)
CURRENT_EPOCH=$(date +%s)

DAYS_LEFT=$(( (EXPIRY_EPOCH - CURRENT_EPOCH) / 86400 ))

echo -e "Certificate Expiration Date : ${NOT_AFTER}"
echo -e "Days Remaining              : ${DAYS_LEFT} days"

if [[ "$DAYS_LEFT" -le 0 ]]; then
    echo -e "${RED}[CRITICAL EXPIRED] Certificate has already expired!${NC}"
    exit 1
elif [[ "$DAYS_LEFT" -le "$WARN_DAYS" ]]; then
    echo -e "${YELLOW}[WARNING EXPIRING SOON] Certificate expires in ${DAYS_LEFT} days (Threshold: ${WARN_DAYS}d).${NC}"
else
    echo -e "${GREEN}[OK] Certificate is valid for ${DAYS_LEFT} more days.${NC}"
fi

exit 0
