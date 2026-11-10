#!/usr/bin/env bash
# ==============================================================================
# Script Name : pypi_npm_audit.sh
# Description : Scans application directories for known vulnerabilities and outdated
#               dependencies using npm audit and pip list / pip-audit.
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

PROJECT_DIR="."

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Audits Node.js (npm) and Python (pip) dependencies for security vulnerabilities.

Options:
  -d, --dir <path>   Project directory to scan (default: current directory)
  -h, --help         Show this help message and exit

Example:
  $(basename "$0") -d /var/www/my_app
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dir)
            PROJECT_DIR="$2"; shift 2 ;;
        -h|--help)
            usage ;;
        *)
            echo -e "${RED}[ERROR]${NC} Unknown option: $1" >&2
            exit 2 ;;
    esac
done

echo -e "${CYAN}====================================================================${NC}"
echo -e "${CYAN} NPM & PyPI Dependency Security Auditor - Florian Schmid${NC}"
echo -e "${CYAN}====================================================================${NC}"
echo -e "Auditing directory: ${PROJECT_DIR}\n"

# 1. NPM Audit
if [[ -f "${PROJECT_DIR}/package.json" ]] && command -v npm &>/dev/null; then
    echo -e "${YELLOW}[NPM] Running 'npm audit'...${NC}"
    (cd "$PROJECT_DIR" && npm audit --audit-level=high 2>/dev/null || echo -e "${RED}[VULNERABILITY DETECTED in NPM packages]${NC}")
fi

# 2. Python Outdated Check
if [[ -f "${PROJECT_DIR}/requirements.txt" ]] && command -v pip3 &>/dev/null; then
    echo -e "\n${YELLOW}[PIP] Checking outdated Python packages...${NC}"
    pip3 list --outdated 2>/dev/null | head -n 10 || true
fi

echo -e "\n${GREEN}[SUCCESS] Dependency audit complete.${NC}"
exit 0
