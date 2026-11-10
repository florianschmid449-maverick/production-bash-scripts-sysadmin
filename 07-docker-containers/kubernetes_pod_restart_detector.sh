#!/usr/bin/env bash
# ==============================================================================
# Script Name : kubernetes_pod_restart_detector.sh
# Description : Queries kubectl across all namespaces to identify pods with high
#               restart counts or CrashLoopBackOff status, reporting exit causes.
# Author      : Florian Schmid
# Contact     : FlorianSchmid449@gmail.com
# Version     : 1.0.0
# License     : MIT
# Requirements: bash (>= 4.4), coreutils, kubectl
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

# ANSI Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

MIN_RESTARTS=3

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Audits Kubernetes cluster pods for restart loops and abnormal termination phases.

Options:
  -r, --restarts <num>   Minimum restart count threshold (default: 3)
  -h, --help             Show this help message and exit

Example:
  $(basename "$0") -r 5
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -r|--restarts)
            MIN_RESTARTS="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} Kubernetes Pod Stability & CrashLoop Detector - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"

if ! command -v kubectl &>/dev/null; then
    echo -e "${YELLOW}[NOTICE] 'kubectl' binary not found on this machine.${NC}"
    exit 0
fi

echo -e "Auditing pods with restarts >= ${MIN_RESTARTS} or non-running status...\n"

printf "%-18s %-30s %-12s %-15s\n" "NAMESPACE" "POD NAME" "RESTARTS" "STATUS"
printf "%-18s %-30s %-12s %-15s\n" "---------" "--------" "--------" "------"

kubectl get pods -A --no-headers 2>/dev/null | while read -r line; do
    ns=$(echo "$line" | awk '{print $1}')
    pod=$(echo "$line" | awk '{print $2}')
    status=$(echo "$line" | awk '{print $4}')
    restarts=$(echo "$line" | awk '{print $5}')

    # Check restart count integer
    restarts_clean=$(echo "$restarts" | grep -oE "^[0-9]+" || echo 0)

    if [[ "$restarts_clean" -ge "$MIN_RESTARTS" || "$status" =~ CrashLoopBackOff|Error|OOMKilled ]]; then
        printf "%-18s %-30s %-12s " "$ns" "$pod" "$restarts"
        echo -e "${RED}${status}${NC}"
    fi
done

exit 0
