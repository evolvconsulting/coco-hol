#!/bin/bash
# CoCo-Financial HOL - Accelerated Setup Script
# This script installs missing prerequisites for the lab

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "=============================================="
echo "  CoCo-Financial HOL - Accelerated Setup"
echo "=============================================="
echo ""

# Detect OS
OS=$(uname -s)
ARCH=$(uname -m)

echo -e "${BLUE}[INFO]${NC} Detected: $OS ($ARCH)"
echo ""

# Function to prompt user
prompt_install() {
    local name=$1
    echo -e "${YELLOW}$name is not installed.${NC}"
    read -p "Would you like to install it now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# ============================================
# Install Snowflake CLI
# ============================================
echo "Checking Snowflake CLI..."
echo "-------------------------"

if command -v snow &> /dev/null; then
    echo -e "${GREEN}[OK]${NC} Snowflake CLI is already installed"
    snow --version
else
    if prompt_install "Snowflake CLI"; then
        echo -e "${BLUE}[INFO]${NC} Installing Snowflake CLI..."
        
        case "$OS" in
            Darwin)
                # macOS - try brew first, fall back to pip
                if command -v brew &> /dev/null; then
                    echo "Installing via Homebrew..."
                    brew install snowflake-cli
                elif command -v pip3 &> /dev/null; then
                    echo "Installing via pip..."
                    pip3 install snowflake-cli-labs
                else
                    echo -e "${RED}[ERROR]${NC} Neither Homebrew nor pip found."
                    echo "Please install Homebrew (https://brew.sh) or pip, then retry."
                fi
                ;;
            Linux)
                # Linux - use pip
                if command -v pip3 &> /dev/null; then
                    pip3 install snowflake-cli-labs
                elif command -v pip &> /dev/null; then
                    pip install snowflake-cli-labs
                else
                    echo -e "${RED}[ERROR]${NC} pip not found."
                    echo "Install pip: sudo apt install python3-pip (Debian/Ubuntu)"
                fi
                ;;
            *)
                echo -e "${RED}[ERROR]${NC} Unsupported OS for automatic installation"
                ;;
        esac
        
        # Verify installation
        if command -v snow &> /dev/null; then
            echo -e "${GREEN}[SUCCESS]${NC} Snowflake CLI installed!"
            snow --version
        fi
    fi
fi
echo ""

# ============================================
# Install Cortex Code CLI
# ============================================
echo "Checking Cortex Code CLI..."
echo "---------------------------"

if command -v cortex &> /dev/null; then
    echo -e "${GREEN}[OK]${NC} Cortex Code CLI is already installed"
    cortex --version
else
    if prompt_install "Cortex Code CLI"; then
        echo -e "${BLUE}[INFO]${NC} Installing Cortex Code CLI..."
        
        # Official installation method
        curl -LsS https://ai.snowflake.com/static/cc-scripts/install.sh | sh
        
        # Add to PATH if not already there
        CORTEX_BIN="$HOME/.local/bin"
        if [[ ":$PATH:" != *":$CORTEX_BIN:"* ]]; then
            echo ""
            echo -e "${YELLOW}[NOTE]${NC} Adding $CORTEX_BIN to PATH..."
            
            # Detect shell and update appropriate config
            if [ -f "$HOME/.zshrc" ]; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
                echo "Added to ~/.zshrc"
            elif [ -f "$HOME/.bashrc" ]; then
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
                echo "Added to ~/.bashrc"
            fi
            
            # Also export for current session
            export PATH="$HOME/.local/bin:$PATH"
        fi
        
        # Verify installation
        if command -v cortex &> /dev/null; then
            echo -e "${GREEN}[SUCCESS]${NC} Cortex Code CLI installed!"
            cortex --version
        else
            echo -e "${YELLOW}[NOTE]${NC} You may need to restart your terminal or run:"
            echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        fi
    fi
fi
echo ""

# ============================================
# Check/Install OpenSSL
# ============================================
echo "Checking OpenSSL..."
echo "-------------------"

if command -v openssl &> /dev/null; then
    echo -e "${GREEN}[OK]${NC} OpenSSL is available"
    openssl version
else
    echo -e "${YELLOW}[WARN]${NC} OpenSSL not found"
    echo "OpenSSL is typically pre-installed on macOS and Linux."
    echo "If you need key-pair authentication, install OpenSSL:"
    echo "  macOS: brew install openssl"
    echo "  Linux: sudo apt install openssl"
fi
echo ""

# ============================================
# Create Snowflake directories
# ============================================
echo "Setting up directories..."
echo "-------------------------"

mkdir -p "$HOME/.snowflake/keys"
chmod 700 "$HOME/.snowflake/keys"
echo -e "${GREEN}[OK]${NC} Created ~/.snowflake/keys directory"

mkdir -p "$HOME/.snowflake/cortex/skills"
echo -e "${GREEN}[OK]${NC} Created ~/.snowflake/cortex/skills directory"
echo ""

# ============================================
# Check for Snowflake Account
# ============================================
echo "Snowflake Account Check..."
echo "--------------------------"

if [ -f "$HOME/.snowflake/connections.toml" ]; then
    echo -e "${GREEN}[OK]${NC} connections.toml found"
    echo "Existing connections:"
    snow connection list 2>/dev/null || echo "  (run 'snow connection list' to see connections)"
else
    echo -e "${YELLOW}[INFO]${NC} No Snowflake connection configured yet."
    echo ""
    echo "Do you have a Snowflake account?"
    echo ""
    echo "  If YES: You'll configure it in Module 2 of the lab"
    echo ""
    echo "  If NO:  Sign up for a free Cortex Code trial:"
    echo "          https://signup.snowflake.com/cortex-code?utm_cta=pushdown-signup"
    echo ""
    
    read -p "Would you like to open the trial signup page? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Open URL based on OS
        case "$OS" in
            Darwin)
                open "https://signup.snowflake.com/cortex-code?utm_cta=pushdown-signup"
                ;;
            Linux)
                if command -v xdg-open &> /dev/null; then
                    xdg-open "https://signup.snowflake.com/cortex-code?utm_cta=pushdown-signup"
                else
                    echo "Open this URL in your browser:"
                    echo "https://signup.snowflake.com/cortex-code?utm_cta=pushdown-signup"
                fi
                ;;
        esac
    fi
fi
echo ""

# ============================================
# Summary
# ============================================
echo "=============================================="
echo "                SETUP COMPLETE"
echo "=============================================="
echo ""
echo "Next steps:"
echo ""
echo "1. If you opened a new terminal, your PATH should include cortex"
echo ""
echo "2. Verify installation:"
echo "   snow --version"
echo "   cortex --version"
echo ""
echo "3. Run the prerequisite check:"
echo "   bash scripts/prereq_check.sh"
echo ""
echo "4. Open README.md and start with Module 1"
echo ""
echo -e "${GREEN}Happy learning!${NC}"
