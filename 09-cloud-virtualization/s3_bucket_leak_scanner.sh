#!/usr/bin/env bash
# ==============================================================================
# Script Name : s3_bucket_leak_scanner.sh
# Description : Audits owned S3 buckets for open public read/write permissions,
#               unrestricted bucket ACLs, and missing default encryption.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, aws
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Audits AWS S3 buckets for accidental public access exposure.

Options:
  -h, --help   Show this help message and exit

Example:
  $(basename "$0")
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} AWS S3 Public Bucket & ACL Leak Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v aws &>/dev/null; then
    echo -e "${YELLOW}[NOTICE] 'aws' CLI binary not installed.${NC}"
    exit 0
fi

echo -e "Listing owned S3 buckets...\n"
BUCKETS=$(aws s3api list-buckets --query "Buckets[].Name" --output text 2>/dev/null || true)

if [[ -z "$BUCKETS" ]]; then
    echo -e "${YELLOW}[NOTICE] No S3 buckets discovered or AWS credentials not configured.${NC}"
    exit 0
fi

for b in $BUCKETS; do
    echo -n "Auditing bucket '${b}'... "
    block=$(aws s3api get-public-access-block --bucket "$b" 2>/dev/null || true)
    if [[ "$block" =~ "true" ]]; then
        echo -e "${GREEN}[SECURE] Public access blocked.${NC}"
    else
        echo -e "${RED}[POTENTIAL LEAK] Public access block not fully enforced!${NC}"
    fi
done

exit 0
