#!/bin/bash
#
# Setup script for CoCo-Financial Fraud Dashboard
#
# Usage:
#   bash setup_dashboard.sh
#

set -e

echo "=========================================="
echo "CoCo-Financial Fraud Dashboard Setup"
echo "=========================================="

# Check Python
echo ""
echo "Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python 3 is not installed"
    exit 1
fi
PYTHON_VERSION=$(python3 --version)
echo "✓ Found $PYTHON_VERSION"

# Install dependencies
echo ""
echo "Installing Python dependencies..."
pip install --quiet streamlit snowflake-connector-python pandas altair

echo "✓ Dependencies installed"

# Check for secrets file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_DIR="$SCRIPT_DIR/.streamlit"
SECRETS_FILE="$SECRETS_DIR/secrets.toml"
SECRETS_TEMPLATE="$SECRETS_DIR/secrets.toml.template"

if [ ! -f "$SECRETS_FILE" ]; then
    echo ""
    echo "⚠️  Snowflake credentials not configured"
    echo ""
    echo "Please create $SECRETS_FILE with your Snowflake credentials."
    echo ""
    echo "Option 1: Copy and edit the template:"
    echo "  cp $SECRETS_TEMPLATE $SECRETS_FILE"
    echo "  # Then edit $SECRETS_FILE with your credentials"
    echo ""
    echo "Option 2: Create from scratch:"
    echo "  mkdir -p $SECRETS_DIR"
    echo "  cat > $SECRETS_FILE << EOF"
    echo "[connections.snowflake]"
    echo "account = \"your_account\""
    echo "user = \"your_user\""
    echo "password = \"your_password\""
    echo "warehouse = \"COMPUTE_WH\""
    echo "database = \"COCO_FINANCIAL\""
    echo "schema = \"FRAUD_ANALYTICS\""
    echo "EOF"
    echo ""
else
    echo "✓ Secrets file found"
fi

# Add secrets to gitignore if not already there
GITIGNORE="$(dirname "$SCRIPT_DIR")/.gitignore"
if [ -f "$GITIGNORE" ]; then
    if ! grep -q "secrets.toml" "$GITIGNORE" 2>/dev/null; then
        echo "" >> "$GITIGNORE"
        echo "# Streamlit secrets" >> "$GITIGNORE"
        echo ".streamlit/secrets.toml" >> "$GITIGNORE"
        echo "scripts/.streamlit/secrets.toml" >> "$GITIGNORE"
        echo "✓ Added secrets.toml to .gitignore"
    fi
fi

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "To run the dashboard:"
echo "  cd $SCRIPT_DIR"
echo "  streamlit run fraud_dashboard.py"
echo ""
echo "Or from the project root:"
echo "  streamlit run scripts/fraud_dashboard.py"
echo ""
