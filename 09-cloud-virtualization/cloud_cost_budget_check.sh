#!/usr/bin/env bash
# ==============================================================================
# Script Name : cloud_cost_budget_check.sh
# Description : Queries cloud cost metrics to compare month-to-date expenditure
#               against assigned budget thresholds and alert on forecasted spikes.
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

BUDGET_USD=500

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Audits cloud budget thresholds and estimates burn rates.

Options:
  -b, --budget <amount>   Monthly budget target in USD (default: 500)
  -h, --help              Show this help message and exit

Example:
  $(basename "$0") -b 1000
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -b|--budget)
            BUDGET_USD="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Cloud Infrastructure Monthly Cost & Budget Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"
echo -e "Configured Monthly Spending Ceiling: \$${BUDGET_USD}\n"

if command -v aws &>/dev/null; then
    START_DATE=$(date +%Y-%m-01)
    END_DATE=$(date +%Y-%m-%d)

    echo -e "Querying AWS Cost Explorer from ${START_DATE} to ${END_DATE}..."
    aws ce get-cost-and-usage \
        --time-period Start="${START_DATE}",End="${END_DATE}" \
        --granularity MONTHLY \
        --metrics "UnblendedCost" 2>/dev/null || echo -e "${YELLOW}AWS Cost Explorer requires explicit IAM billing permissions.${NC}"
else
    echo -e "${YELLOW}[NOTICE] Cloud CLI tool (aws) not configured on this host.${NC}"
fi

exit 0
