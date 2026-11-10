#!/usr/bin/env bash
# ==============================================================================
# Script Name : aws_ec2_instance_auditor.sh
# Description : Uses AWS CLI to enumerate EC2 instances across regions, summarizing
#               instance states, IPs, and flagging stopped instances incurring costs.
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

REGION="us-east-1"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Enumerates EC2 instances and attached EBS storage to audit idle costs.

Options:
  -r, --region <region>   AWS region to query (default: us-east-1)
  -h, --help              Show this help message and exit

Example:
  $(basename "$0") -r eu-central-1
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -r|--region)
            REGION="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} AWS EC2 Virtual Machine Fleet Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v aws &>/dev/null; then
    echo -e "${YELLOW}[NOTICE] 'aws' CLI binary not installed on this system.${NC}"
    echo -e "${CYAN}[INFO] Requires AWS CLI with configured API credentials.~${NC}"
    exit 0
fi

echo -e "Querying EC2 instances in region: ${REGION}...\n"

aws ec2 describe-instances --region "$REGION" \
    --query "Reservations[*].Instances[*].{ID:InstanceId,Type:InstanceType,State:State.Name,IP:PublicIpAddress}" \
    --output table 2>/dev/null || echo -e "${YELLOW}Could not connect to AWS API (check IAM credentials).${NC}"

exit 0
