#!/bin/bash

# Setup local nimini development environment
# This script clones nimini alongside nimrlive for integrated development

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
NIMINI_DIR="$WORKSPACE_DIR/nimini"

echo "======================================"
echo "Setup Nimini Development Environment"
echo "======================================"

# Check if nimini already exists
if [ -d "$NIMINI_DIR" ]; then
    echo "✓ Nimini already cloned at $NIMINI_DIR"
    read -p "Pull latest changes? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "$NIMINI_DIR"
        git pull
        echo "✓ Updated nimini"
    fi
else
    echo "Cloning nimini to $NIMINI_DIR..."
    cd "$WORKSPACE_DIR"
    git clone https://github.com/maddestlabs/nimini.git
    echo "✓ Cloned nimini"
fi

# Update nim.cfg to use local path
echo ""
echo "Updating nim.cfg to use local nimini..."

cd "$SCRIPT_DIR"

# Check if path is already uncommented
if grep -q "^--path:\"../nimini/src\"" nim.cfg; then
    echo "✓ nim.cfg already configured for local nimini"
else
    # Uncomment the path line
    sed -i 's/^# --path:"..\/nimini\/src"/--path:"..\/nimini\/src"/' nim.cfg
    echo "✓ Updated nim.cfg to use local nimini"
fi

echo ""
echo "======================================"
echo "Development Environment Ready!"
echo "======================================"
echo ""
echo "You can now:"
echo "  1. Edit nimini source: $NIMINI_DIR/src/"
echo "  2. Test changes: cd $SCRIPT_DIR && nim c -r nimrlive.nim"
echo "  3. Changes take effect immediately!"
echo ""
echo "To revert to nimble-installed nimini:"
echo "  Comment out the --path line in nim.cfg"
echo ""
