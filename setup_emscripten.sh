#!/bin/bash

# Setup Emscripten environment for nimrlive
# This script should be sourced, not executed: source setup_emscripten.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EMSDK_DIR="$SCRIPT_DIR/emsdk"

# Check if emsdk exists
if [ ! -d "$EMSDK_DIR" ]; then
    echo "Error: emsdk not found at $EMSDK_DIR"
    echo "Please run: git clone https://github.com/emscripten-core/emsdk.git"
    echo "Then: cd emsdk && ./emsdk install 3.1.55 && ./emsdk activate 3.1.55"
    return 1 2>/dev/null || exit 1
fi

# Source the Emscripten environment
echo "Setting up Emscripten environment..."
source "$EMSDK_DIR/emsdk_env.sh"

# Verify emcc is available
if command -v emcc &> /dev/null; then
    echo "✓ Emscripten configured successfully"
    echo "  emcc version: $(emcc --version | head -n 1)"
else
    echo "✗ Error: emcc not found in PATH after sourcing emsdk_env.sh"
    return 1 2>/dev/null || exit 1
fi
