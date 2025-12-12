#!/bin/bash

# Build script for nimrlive - Nim scripting with Raylib + Nimini + WebAssembly
# Compiles nimrlive.nim to WebAssembly for GitHub Pages

set -e  # Exit on error

echo "==================================="
echo "Building nimrlive for WebAssembly"
echo "==================================="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Setup Emscripten environment
if [ -d "$SCRIPT_DIR/emsdk" ]; then
  echo -e "${BLUE}Setting up Emscripten environment (local)...${NC}"
  source "$SCRIPT_DIR/emsdk/emsdk_env.sh"
else
  echo -e "${BLUE}Using pre-configured Emscripten (CI)...${NC}"
fi

# Add Nim to PATH (handle both codespace and CI environments)
if [ -d "$HOME/.nimble/bin" ]; then
  export PATH=$HOME/.nimble/bin:$PATH
fi

# Verify emcc is available
echo -e "${BLUE}Verifying emcc...${NC}"
which emcc || { echo -e "${RED}emcc not found in PATH${NC}"; exit 1; }
emcc --version

# Create docs directory if it doesn't exist
echo -e "${BLUE}Creating docs directory...${NC}"
mkdir -p docs

# Clean previous builds
echo -e "${BLUE}Cleaning previous builds...${NC}"
rm -f docs/index.html docs/index.js docs/index.wasm

# Compile nimrlive.nim to WebAssembly
echo -e "${BLUE}Compiling nimrlive.nim to WebAssembly...${NC}"
nim c -d:emscripten -d:release --opt:size --mm:orc nimrlive.nim

# Check if build was successful
if [ -f "docs/index.html" ]; then
    echo -e "${GREEN}Build successful!${NC}"
    echo -e "${GREEN}Output files:${NC}"
    ls -lh docs/index.*
    echo ""
    echo -e "${BLUE}To test locally:${NC}"
    echo "  cd docs && python3 -m http.server 8000"
    echo "  Then open http://localhost:8000"
    echo ""
    echo -e "${BLUE}For GitHub Pages:${NC}"
    echo "  1. Commit and push the docs/ directory"
    echo "  2. Enable GitHub Pages in repository settings"
    echo "  3. Set source to 'main' branch, '/docs' folder"
else
    echo -e "${RED}Build failed! Output files not found.${NC}"
    exit 1
fi
