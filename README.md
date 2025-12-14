# NimRLive

Live Nim scripting with raylib on the web. Write [raylib](https://www.raylib.com/) code in [Nim](https://nim-lang.org/), run it instantly in your browser using [Nimini](https://github.com/maddestlabs/nimini) scripting engine. Built around GitHub Gists - no installation required.

Check it out live: **[Demo](https://maddestlabs.github.io/nimrlive/)**

Examples on GitHub Gist:
- [nimr_eyes.nim](https://maddestlabs.github.io/tstorie?gist=9b0aee2ba116791b092f1b238975c295) | [Source Gist](https://gist.github.com/R3V1Z3/9b0aee2ba116791b092f1b238975c295)
- [nimr_ball.nim](https://maddestlabs.github.io/tstorie?gist=9da9160a65563ba711bfc68fd6f01c83) | [Source Gist](https://gist.github.com/R3V1Z3/9da9160a65563ba711bfc68fd6f01c83)

## Quick Start

### Try a Gist

- Create a [gist](https://gist.github.com/) with your raylib Nim code.
- See your gist code running live at `https://maddestlabs.github.io/nimrlive?gist=GistID`.

### Run Locally

```bash
# Compile and run a script
nim c -r nimrlive.nim yourscript.nim

# Or just run the default example
nim c -r nimrlive.nim
```

## Features

- **Live Scripting**: Execute Nim code dynamically using [Nimini](https://github.com/maddestlabs/nimini/) scripting engine
- **GitHub Gist Integration**: Load and run scripts directly from GitHub Gists via URL parameters
- **Headless Testing**: Test code in containers without display servers (perfect for CI/CD)
- **Local Testing**: Quick iteration with `./test.sh` - no WASM build needed
- **Native + WASM**: Develop locally with native compilation, deploy to web with WASM
- **Built on**: [Nim](https://nim-lang.org) + [naylib](https://github.com/planetis-m/naylib) + [raylib](https://www.raylib.com)
- **Auto-Deploy**: GitHub Actions automatically compiles and deploys to GitHub Pages

## How It Works

### Architecture

**NimRLive** combines three powerful technologies:

1. **Nimini** - A Nim scripting engine that interprets Nim code at runtime
2. **naylib** - Nim bindings for the raylib game library
3. **Emscripten** - Compiles everything to WebAssembly for browser execution

### Workflow

**Native Development:**
```bash
# Run any Nim script with raylib
nimrlive examples/nimr_ball.nim

# Default runs nimr.nim
nimrlive
```

**Web/WASM:**
- Load scripts from GitHub Gists: `?gist=YOUR_GIST_ID`
- Falls back to `nimr.nim` if no Gist specified
- Auto-deploys via GitHub Actions to GitHub Pages

### Example Script

```nim
import raylib

proc main() =
  initWindow(800, 450, "Hello NimRLive!")
  setTargetFPS(60)

  while not windowShouldClose():
    beginDrawing()
    clearBackground(RayWhite)
    drawText("Hello from Nimini!", 190, 200, 20, Gray)
    endDrawing()

  closeWindow()

when isMainModule:
  main()
```

Save this as a Gist and run it at: `https://maddestlabs.github.io/nimrlive?gist=YOUR_GIST_ID`

## Development Setup

### Prerequisites

- [Nim](https://nim-lang.org) compiler and nimble package manager
- Git

### Local Development with Emscripten

If you want to build WebAssembly locally:

1. **Install Emscripten SDK**
   ```bash
   # Clone this repository
   git clone https://github.com/maddestlabs/nimrlive.git
   cd nimrlive

   # Clone and setup Emscripten
   git clone https://github.com/emscripten-core/emsdk.git
   cd emsdk
   ./emsdk install 3.1.55
   ./emsdk activate 3.1.55
   cd ..
   ```

2. **Source Emscripten environment**
   ```bash
   # Use the convenience script
   source setup_emscripten.sh
   
   # Or manually
   source emsdk/emsdk_env.sh
   ```

3. **Install Nim dependencies**
   ```bash
   nimble install naylib nimini -y
   ```

4. **Build for WebAssembly**
   ```bash
   ./build.sh
   ```

**Note**: The `emsdk/` directory is gitignored and won't interfere with GitHub Pages or CI/CD processes. The GitHub Actions workflow uses its own Emscripten setup, so local installation is only needed for local WASM builds.

### Developing Nimini Features

If you want to develop Nimini features alongside NimRLive (recommended for adding raylib bindings):

```bash
# Quick setup - clones nimini and configures nim.cfg automatically
./setup_nimini_dev.sh
```

See [DEVELOPMENT.md](DEVELOPMENT.md) for detailed development workflows and best practices.

## Project Structure

```
nimrlive/
├── nimrlive.nim          # Main entry point (loads & executes scripts via Nimini)
├── nimr.nim              # Default example script (bouncing ball demo)
├── web/
│   └── shell.html        # HTML template with Gist fetching logic
├── docs/                 # Generated WASM output (GitHub Pages)
├── nim.cfg               # Nim/Emscripten configuration
├── nimrlive.nimble       # Package definition
├── build.sh              # Build script for WASM
└── .github/workflows/
    └── deploy.yml        # CI/CD workflow
```

## Development Goals

This project aims to:

- **Develop Nimini**: Enhance the Nimini scripting engine to handle all naylib/raylib examples
- **Educational Tool**: Make raylib + Nim more accessible through instant web demos
- **Rapid Prototyping**: Quick iteration with Gist-based sharing and live updates
- **Bridge Native/Web**: Seamless workflow from local development to web deployment

## Current Limitations

- Nimini API coverage is growing - not all naylib functions are registered yet
- Complex raylib features may require additional bindings
- Performance is good but native compilation will always be faster

## Contributing

Contributions welcome! Priority areas:
- Expanding naylib API coverage in Nimini
- Testing against raylib examples
- Improving error handling and debugging output
- Documentation and example scripts

## License

MIT License - see [LICENSE](LICENSE) for details.
