#!/bin/bash

# Build script for nimr - Nim + Raylib + WebAssembly
# Compiles nimr.nim to WebAssembly for GitHub Pages

set -e  # Exit on error

echo "==================================="
echo "Building nimr for WebAssembly"
echo "==================================="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Setup Emscripten environment (if running locally)
if [ -d "/workspaces/nimr/emsdk" ]; then
  echo -e "${BLUE}Setting up Emscripten environment (local)...${NC}"
  cd /workspaces/nimr/emsdk
  source ./emsdk_env.sh
  cd /workspaces/nimr
else
  echo -e "${BLUE}Using pre-configured Emscripten (CI)...${NC}"
fi

# Add Nim to PATH
export PATH=/home/codespace/.nimble/bin:$PATH

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

# Compile nimr.nim to WebAssembly
echo -e "${BLUE}Compiling nimr.nim to WebAssembly...${NC}"
nim c -d:emscripten -d:release --opt:size --mm:orc nimr.nim

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
