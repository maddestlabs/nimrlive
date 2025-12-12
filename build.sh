#!/bin/bash

# Build script for nimrlive - Nim scripting with Raylib + Nimini + WebAssembly
# Compiles multiple nimrlive builds with different feature sets for optimal size
# 
# Builds:
#   - minimal (default): Basic 2D drawing, text, shapes - smallest size
#   - 3d: Adds 3D models, camera, lighting
#   - complete: Full raylib with audio, textures, shaders

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse command line arguments
BUILD_TYPE="${1:-all}"  # Default to building all variants

echo "==================================="
echo "Building nimrlive for WebAssembly"
echo "Build type: $BUILD_TYPE"
echo "==================================="

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

# Check for wasm-opt (binaryen tools for optimization)
if command -v wasm-opt &> /dev/null; then
  HAS_WASM_OPT=true
  echo -e "${GREEN}wasm-opt found - will optimize WASM binaries${NC}"
else
  HAS_WASM_OPT=false
  echo -e "${YELLOW}wasm-opt not found - skipping WASM optimization${NC}"
  echo -e "${YELLOW}Install binaryen for better compression: apt install binaryen${NC}"
fi

# Create docs directory if it doesn't exist
echo -e "${BLUE}Creating docs directory...${NC}"
mkdir -p docs

# Function to build a specific variant
build_variant() {
  local variant=$1
  local define_flag=$2
  local output_suffix=$3
  
  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}Building variant: $variant${NC}"
  echo -e "${BLUE}========================================${NC}"
  
  # Set output files based on variant
  if [ "$variant" = "minimal" ]; then
    # Minimal is the default, no suffix
    OUTPUT_HTML="docs/index.html"
  else
    OUTPUT_HTML="docs/index-${output_suffix}.html"
  fi
  
  # Clean previous build for this variant
  rm -f "${OUTPUT_HTML%.html}.js" "${OUTPUT_HTML%.html}.wasm" "$OUTPUT_HTML"
  
  # Compile
  echo -e "${BLUE}Compiling nimrlive.nim with $define_flag...${NC}"
  nim c -d:emscripten $define_flag \
    --passL:"-o $OUTPUT_HTML" \
    nimrlive.nim
  
  # Optimize WASM if wasm-opt is available
  if [ "$HAS_WASM_OPT" = true ]; then
    local wasm_file="${OUTPUT_HTML%.html}.wasm"
    if [ -f "$wasm_file" ]; then
      echo -e "${BLUE}Optimizing WASM with wasm-opt...${NC}"
      local original_size=$(stat -c%s "$wasm_file" 2>/dev/null || stat -f%z "$wasm_file")
      # Enable all MVP features and sign extension to avoid validation errors
      wasm-opt -Oz --enable-sign-ext --enable-mutable-globals --enable-nontrapping-float-to-int \
        "$wasm_file" -o "${wasm_file}.opt"
      mv "${wasm_file}.opt" "$wasm_file"
      local new_size=$(stat -c%s "$wasm_file" 2>/dev/null || stat -f%z "$wasm_file")
      local savings=$((original_size - new_size))
      local percent=$((savings * 100 / original_size))
      echo -e "${GREEN}Optimized: $original_size -> $new_size bytes (saved $savings bytes, $percent%)${NC}"
    fi
  fi
  
  # Verify build success
  if [ -f "$OUTPUT_HTML" ]; then
    echo -e "${GREEN}✓ $variant build successful!${NC}"
    ls -lh "${OUTPUT_HTML%.html}".*
  else
    echo -e "${RED}✗ $variant build failed!${NC}"
    return 1
  fi
}

# Build requested variants
case "$BUILD_TYPE" in
  minimal)
    build_variant "minimal" "-d:nimrlive_minimal" ""
    ;;
  3d)
    build_variant "3d" "-d:nimrlive_3d" "3d"
    ;;
  complete)
    build_variant "complete" "-d:nimrlive_complete" "complete"
    ;;
  all)
    build_variant "minimal" "-d:nimrlive_minimal" ""
    build_variant "3d" "-d:nimrlive_3d" "3d"
    build_variant "complete" "-d:nimrlive_complete" "complete"
    ;;
  *)
    echo -e "${RED}Unknown build type: $BUILD_TYPE${NC}"
    echo "Usage: $0 [minimal|3d|complete|all]"
    exit 1
    ;;
esac

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Build Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All builds completed successfully!${NC}"
echo ""
echo -e "${BLUE}Output files in docs/:${NC}"
ls -lh docs/index*.{html,js,wasm} 2>/dev/null | grep -v "cannot access" || true
echo ""
echo -e "${BLUE}To test locally:${NC}"
echo "  cd docs && python3 -m http.server 8000"
echo "  Then open:"
echo "    http://localhost:8000              (minimal build)"
echo "    http://localhost:8000?build=3d     (3d build)"
echo "    http://localhost:8000?build=complete (complete build)"
echo ""
echo -e "${BLUE}For GitHub Pages:${NC}"
echo "  1. Commit and push the docs/ directory"
echo "  2. Enable GitHub Pages in repository settings"
echo "  3. Set source to 'main' branch, '/docs' folder"
