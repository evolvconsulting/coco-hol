#!/bin/bash
# CoCo-Financial HOL - Prerequisite Check Script
# This script verifies all prerequisites are met before starting the lab

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "=============================================="
echo "  CoCo-Financial HOL - Prerequisite Check"
echo "=============================================="
echo ""

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# Function to check command exists
check_command() {
    local cmd=$1
    local name=$2
    local install_hint=$3
    
    if command -v "$cmd" &> /dev/null; then
        version=$($cmd --version 2>&1 | head -1)
        echo -e "${GREEN}[PASS]${NC} $name is installed"
        echo "       Version: $version"
        ((PASS_COUNT++))
        return 0
    else
        echo -e "${RED}[FAIL]${NC} $name is NOT installed"
        echo "       Install: $install_hint"
        ((FAIL_COUNT++))
        return 1
    fi
}

# Function to check with warning
check_optional() {
    local cmd=$1
    local name=$2
    local hint=$3
    
    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}[PASS]${NC} $name is available"
        ((PASS_COUNT++))
    else
        echo -e "${YELLOW}[WARN]${NC} $name is not installed (optional)"
        echo "       Hint: $hint"
        ((WARN_COUNT++))
    fi
}

echo "Checking Operating System..."
echo "----------------------------"
OS=$(uname -s)
ARCH=$(uname -m)

case "$OS" in
    Darwin)
        echo -e "${GREEN}[PASS]${NC} macOS detected ($ARCH)"
        ((PASS_COUNT++))
        ;;
    Linux)
        echo -e "${GREEN}[PASS]${NC} Linux detected ($ARCH)"
        ((PASS_COUNT++))
        ;;
    MINGW*|CYGWIN*|MSYS*)
        echo -e "${YELLOW}[WARN]${NC} Windows detected - Please use WSL"
        echo "       Cortex Code CLI is not natively supported on Windows"
        ((WARN_COUNT++))
        ;;
    *)
        echo -e "${RED}[FAIL]${NC} Unsupported OS: $OS"
        ((FAIL_COUNT++))
        ;;
esac
echo ""

echo "Checking Required Tools..."
echo "--------------------------"

# Check Snowflake CLI
check_command "snow" "Snowflake CLI" "brew install snowflake-cli (macOS) or pip install snowflake-cli"
echo ""

# Check Cortex Code CLI
check_command "cortex" "Cortex Code CLI" "curl -LsS https://ai.snowflake.com/static/cc-scripts/install.sh | sh"
echo ""

# Check OpenSSL (for key generation)
check_command "openssl" "OpenSSL" "brew install openssl (macOS) or apt install openssl (Linux)"
echo ""

echo "Checking Optional Tools..."
echo "--------------------------"

# Check Python (for advanced scripts)
check_optional "python3" "Python 3" "brew install python3 (macOS) or apt install python3 (Linux)"
echo ""

# Check UV (for Python dependency management)
check_optional "uv" "UV Package Manager" "curl -LsSf https://astral.sh/uv/install.sh | sh"
echo ""

echo "Checking Snowflake Connections..."
echo "----------------------------------"

if command -v snow &> /dev/null; then
    CONNECTIONS=$(snow connection list --format json 2>/dev/null || echo "[]")
    if [ "$CONNECTIONS" != "[]" ] && [ -n "$CONNECTIONS" ]; then
        echo -e "${GREEN}[PASS]${NC} Snowflake connections configured"
        echo "       Run 'snow connection list' to see available connections"
        ((PASS_COUNT++))
    else
        echo -e "${YELLOW}[WARN]${NC} No Snowflake connections found"
        echo "       You'll need to configure a connection in Module 2"
        ((WARN_COUNT++))
    fi
else
    echo -e "${YELLOW}[SKIP]${NC} Cannot check connections (Snowflake CLI not installed)"
fi
echo ""

echo "Checking Configuration Files..."
echo "--------------------------------"

# Check connections.toml
if [ -f "$HOME/.snowflake/connections.toml" ]; then
    echo -e "${GREEN}[PASS]${NC} connections.toml exists"
    ((PASS_COUNT++))
else
    echo -e "${YELLOW}[WARN]${NC} connections.toml not found at ~/.snowflake/connections.toml"
    echo "       This file will be created during connection setup"
    ((WARN_COUNT++))
fi

# Check for existing keys
if [ -d "$HOME/.snowflake/keys" ]; then
    echo -e "${BLUE}[INFO]${NC} Key directory exists at ~/.snowflake/keys"
    if [ -f "$HOME/.snowflake/keys/rsa_key.p8" ]; then
        echo -e "${BLUE}[INFO]${NC} RSA private key found (rsa_key.p8)"
    fi
else
    echo -e "${BLUE}[INFO]${NC} No key directory found (will be created if using key-pair auth)"
fi
echo ""

echo "=============================================="
echo "                  SUMMARY"
echo "=============================================="
echo ""
echo -e "${GREEN}Passed:${NC}  $PASS_COUNT"
echo -e "${RED}Failed:${NC}  $FAIL_COUNT"
echo -e "${YELLOW}Warnings:${NC} $WARN_COUNT"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}All required prerequisites are met!${NC}"
    echo "You're ready to start the lab."
    echo ""
    echo "Next step: Open README.md and proceed to Module 1"
    exit 0
else
    echo -e "${RED}Some prerequisites are missing.${NC}"
    echo ""
    echo "Run the accelerated setup script to install missing components:"
    echo "  bash scripts/accelerated_setup.sh"
    echo ""
    echo "Or install manually and re-run this check."
    exit 1
fi
