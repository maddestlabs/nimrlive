# NimR

Simple animated [raylib](https://www.raylib.com/) example in Nim compiled to WebAssembly for easy deployment on GitHub Pages. No need to install anything, GitHub Actions take care of everything.

Check it out live: **[Demo](https://maddestlabs.github.io/nimr/)**

## Quick Start

- Create a project from the [template](https://github.com/new?template_name=nimr&template_owner=maddestlabs).
- Edit nimr.nim and save your changes.
- Enable GitHub Pages to see your changes live.

## Features

- Built with [Nim](https://nim-lang.org) + [naylib](https://github.com/planetis-m/naylib) + [raylib](https://www.raylib.com). Super fast compilation, small binaries, readable code.
- Auto-compiled to WebAssembly using Emscripten.
- Automatic deployment to GitHub Pages.

## Building Locally

Prerequisites
- [Nim](https://nim-lang.org/install.html) (2.0+)

### Build for Desktop (Native)

```bash
# Install Nim
curl https://nim-lang.org/choosenim/init.sh -sSf | sh

# Install dependencies
nimble install naylib -y

# Build for desktop
nim c -d:release nimr.nim
```

### Build for Web (WASM)

Prerequisites
- [Emscripten](https://emscripten.org/docs/getting_started/downloads.html)

```bash
# Install dependencies
nimble install naylib -y

# Build for web (output in docs/)
nim c -d:emscripten nimr.nim

# Serve locally (optional)
cd docs && python3 -m http.server 8080
```

## Project Structure

```
nimr/
├── src/
│   └── nimr.nim          # Main application source
├── web/
│   └── shell.html        # HTML template for WASM
├── docs/                 # Generated WASM output (GitHub Pages)
├── nim.cfg               # Nim configuration
├── nimr.nimble           # Package definition
└── .github/workflows/
    └── deploy.yml        # CI/CD workflow
```

## License

MIT License - see [LICENSE](LICENSE) for details.
