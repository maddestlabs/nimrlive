# Local Testing Guide for NimRLive

This guide explains how to test nimini/raylib code locally without deploying to WebAssembly or using gist URLs.

## Testing Options

### 1. **Headless Testing** (✅ Recommended for CI/CD)

Test your code without requiring a display server (X11/Wayland). Perfect for:
- Docker containers
- GitHub Actions / CI pipelines
- SSH sessions without X forwarding
- Automated testing

**Usage:**
```bash
nim r test_headless.nim <your_script.nim>
```

**Example:**
```bash
nim r test_headless.nim test_minimal.nim
```

**Features:**
- ✅ Validates function calls and logic
- ✅ Tracks API usage statistics
- ✅ Shows which raylib functions were called
- ✅ No display server required
- ✅ Fast execution (mocked rendering)
- ⚠️  Doesn't validate visual output

### 2. **Local Testing** (Native Execution)

Test with actual raylib rendering (requires display):

**Usage:**
```bash
nim r test_local.nim <your_script.nim>
```

**Features:**
- ✅ Full raylib rendering
- ✅ Real visual output
- ✅ Complete API validation
- ⚠️  Requires display server
- ⚠️  Slower (actual rendering)

### 3. **Nimini Test** (Existing Tool)

The original niminitest validates parsing and basic execution but doesn't include raylib bindings:

**Usage:**
```bash
nim r niminitest.nim <your_script.nim>
```

**Features:**
- ✅ Validates nimini parsing
- ✅ Tests basic execution
- ❌ No raylib bindings included
- ✅ Good for pure nimini code

## Creating Test Files

### Simple Test Example

Create `test_minimal.nim`:
```nim
## Minimal test for headless execution

initWindow(800, 450, "Test")
setTargetFPS(60)

var i = 0
while i < 5:
  i = i + 1
  beginDrawing()
  clearBackground(RAYWHITE)
  drawText("Hello", 10, 10, 20, BLACK)
  endDrawing()

closeWindow()
```

Run it:
```bash
nim r test_headless.nim test_minimal.nim
```

### Available Raylib Functions (Headless Mode)

The headless test mocks these raylib functions:

**Window Management:**
- `initWindow(width, height, title)`
- `closeWindow()`
- `windowShouldClose()` - Returns true after 10 iterations
- `setTargetFPS(fps)`

**Drawing:**
- `beginDrawing()`
- `endDrawing()`
- `clearBackground(color)`
- `drawCircle(x, y, radius, color)`
- `drawCircleV(position, radius, color)`
- `drawRectangle(x, y, width, height, color)`
- `drawText(text, x, y, fontSize, color)`
- `drawFPS(x, y)`

**Input:**
- `getMousePosition()` - Returns `{x: 400, y: 300}`
- `getMouseX()` - Returns `400`
- `getMouseY()` - Returns `300`
- `isMouseButtonPressed(button)` - Returns `false`
- `isKeyPressed(key)` - Returns `false`

**Time:**
- `getFrameTime()` - Returns `0.0166...` (~60 FPS)
- `getTime()` - Returns simulated time

**Colors:**
- `RAYWHITE`, `LIGHTGRAY`, `GRAY`, `DARKGRAY`, `BLACK`
- `RED`, `GREEN`, `BLUE`, `YELLOW`

## Comparison with WASM Testing

| Feature | Headless | WASM + Gist | Local Native |
|---------|----------|-------------|--------------|
| Speed | ⚡ Fast | 🐌 Slow (network) | ⚡ Fast |
| Setup | ✅ Easy | 🔧 Complex | ✅ Easy |
| CI/CD | ✅ Perfect | ❌ Hard | ⚠️  Need display |
| Visual Output | ❌ No | ✅ Yes | ✅ Yes |
| Automation | ✅ Easy | ❌ Hard | ⚠️  Need X server |
| Function Validation | ✅ Yes | ✅ Yes | ✅ Yes |
| Logic Testing | ✅ Yes | ✅ Yes | ✅ Yes |

## Best Practices

### 1. Development Workflow

```bash
# 1. Write your nimini code
vim my_game.nim

# 2. Test headless (fast validation)
nim r test_headless.nim my_game.nim

# 3. Fix any errors

# 4. Test with actual raylib (visual check)
nim r test_local.nim my_game.nim

# 5. Deploy to WASM when ready
./build.sh
```

### 2. CI/CD Integration

Add to your GitHub Actions:

```yaml
- name: Test nimini code
  run: |
    nim r test_headless.nim test_minimal.nim
    nim r test_headless.nim examples/*.nim
```

### 3. What to Test

**Use Headless Testing For:**
- ✅ Function call validation
- ✅ Logic correctness
- ✅ API usage patterns
- ✅ Loop termination
- ✅ Variable state
- ✅ Automated regression tests

**Use Visual Testing For:**
- ✅ Rendering correctness
- ✅ Color accuracy
- ✅ Animation smoothness
- ✅ User interaction
- ✅ Final QA before deployment

## Extending Headless Tests

To add more raylib functions to the headless test, edit `test_headless.nim`:

```nim
registerNative("myFunction", proc(env: ref Env, args: seq[Value]): Value =
  logCall("myFunction", $args[0].i)
  echo "📝 Mock: myFunction(", args[0].i, ")"
  result = valNil()
)
```

## Troubleshooting

### "Expected ':' at line X"
Your code uses Nim features not supported by nimini. Simplify the code:
- Avoid `type` declarations (use simple vars)
- Don't use `proc` declarations (use inline code)
- Use basic expressions only

### "Undefined function"
Add the function to the headless mock bindings in `test_headless.nim`.

### "Execution hangs"
Your `while` loop might not terminate. The headless `windowShouldClose()` returns true after 10 iterations by default. Adjust this in `test_headless.nim` if needed.

## Quick Reference

```bash
# Headless test (no display needed)
nim r test_headless.nim my_code.nim

# Local test (requires display)
nim r test_local.nim my_code.nim

# Original nimini test (no raylib)
nim r niminitest.nim my_code.nim

# Create a simple test file
cat > my_test.nim << 'EOF'
initWindow(800, 450, "Test")
setTargetFPS(60)
var i = 0
while i < 3:
  i = i + 1
  beginDrawing()
  clearBackground(RAYWHITE)
  drawText("Loop iteration", 10, 10, 20, BLACK)
  endDrawing()
closeWindow()
EOF

# Run it
nim r test_headless.nim my_test.nim
```

## Summary

Yes, you can test locally! Use:
- **`test_headless.nim`** for automated/CI testing (recommended)
- **`test_local.nim`** for visual validation
- **`niminitest.nim`** for basic nimini validation

The headless test is the answer to your question about testing in a headless container - it validates your code's logic and API usage without requiring a display server, making it perfect for containers and CI/CD pipelines.
