# Enhanced Error Reporting in nimrtest

The `nimrtest.nim` tool now provides significantly more detailed error information to help you fix issues quickly.

## What's New

### 1. **Phase Tracking**
Errors now clearly show which phase failed:
- **TOKENIZATION** - Converting source code to tokens
- **PARSING** - Building the syntax tree
- **EXECUTION** - Running the code

### 2. **Line Number Context**
When possible, shows the exact line where the error occurred with surrounding context:
```
📄 Source Code Context (around line 13):
    10| var counter = 0
    11| while counter < 3:
    12|   counter = counter + 1
>>> 13|   drawUndefinedFunction(100, 100)
    14|   drawText("Hello", 10, 10, 20, BLACK)
    15|   endDrawing()
```

### 3. **Token Context**
For parsing errors, shows recent tokens:
```
Recent tokens:
    [45] IDENT 'counter'
    [46] ASSIGN '='
    [47] IDENT 'counter'
    [48] PLUS '+'
>>> [49] INT '1'
```

### 4. **API Call History**
Shows the last 10 API calls before an error:
```
Last 10 API calls:
    1. initWindow(800, 450, Test)
    2. setTargetFPS(60)
    3. beginDrawing()
    4. clearBackground(4294572543)
>>> 5. drawText(Hello, 10, 10, 20, 0)
```

### 5. **Smart Suggestions**
Context-aware suggestions based on error type:
```
💡 Suggestions:
  • Function or variable not defined
  • Check spelling and ensure it's registered or declared
  • For raylib functions, ensure they're in the mock bindings

🔧 Debugging Steps:
  1. Check if all called functions are registered
  2. Verify variable names are spelled correctly
  3. Ensure types match (int vs float, etc.)
  4. Review registered raylib functions (see error above)
  5. Add missing functions to nimrtest.nim mock bindings
```

## Error Examples

### Parsing Error (Unsupported Syntax)

**test_parse_error.nim:**
```nim
# This uses proc which nimini doesn't fully support  
proc myFunction(x: int): int =
  return x * 2

var result = myFunction(5)
```

**Output:**
```
======================================================================
❌ ERROR IN PARSING PHASE
======================================================================

🔍 Error Details:
  Type: Exception
  Message: Expected ':' at line 2

🔍 Parsing Context:
  Tokens generated: 42

Recent tokens:
    [36] IDENT 'myFunction'
    [37] LPAREN '('
    [38] IDENT 'x'
>>> [39] COLON ':'

💡 Suggestions:
  • Missing ':' in type/object declaration or named parameter
  • Nimini may not support all Nim syntax - try simplifying
  • Check if you're using 'type' blocks (not fully supported)
  • 📖 Nimini supports a subset of Nim syntax
  • 📖 Try removing: type blocks, proc definitions, complex expressions
  • 📖 Use simple statements: var, let, const, if, while, for

🔧 Debugging Steps:
  1. Simplify complex expressions
  2. Remove 'type' and 'proc' declarations (use inline code)
  3. Check for unsupported Nim features
  4. Review nimini documentation: docs/NEW_FEATURES_SUMMARY.md
  5. Try: nim r niminitest.nim test_parse_error.nim
```

### Runtime Error (Undefined Function)

**Note:** Runtime errors that use `quit()` in the nimini runtime will terminate immediately and show minimal output. This is a limitation of the nimini runtime design.

**test_undefined.nim:**
```nim
initWindow(800, 450, "Test")

# This function doesn't exist
drawSuperCircle(100, 100, 50, RED)

closeWindow()
```

**Output:**
```
Testing: test_undefined.nim

===================================
HEADLESS NIMINI + RAYLIB TEST
===================================

Initializing runtime...
✓ Registered headless raylib bindings (mock)

Tokenizing code...
✓ Got 45 tokens
Parsing code...
✓ Parsed 3 statements

Executing program (mock raylib)...
--------------------------------------------------
⚠️  Note: Runtime errors (undefined variables/functions) will cause immediate termination

📝 Mock: initWindow(800, 450, "Test")
Runtime Error: Undefined variable 'drawSuperCircle'
```

**How to fix:** Add the missing function to nimrtest.nim's `registerHeadlessRaylibBindings()` procedure, or fix the typo in your code.

### Successful Execution

**test_success.nim:**
```nim
initWindow(800, 450, "Test")
setTargetFPS(60)

var counter = 0
while counter < 3:
  counter = counter + 1
  beginDrawing()
  clearBackground(RAYWHITE)
  drawText("Hello", 10, 10, 20, BLACK)
  drawCircle(400, 225, 50.0, RED)
  endDrawing()

closeWindow()
```

**Output:**
```
===================================
✅ SUCCESS - Code executed!
===================================

📊 Statistics:
  • Total API calls: 20

📋 API Usage:
  • initWindow: 1 call(s)
  • setTargetFPS: 1 call(s)
  • beginDrawing: 3 call(s)
  • clearBackground: 3 call(s)
  • drawText: 3 call(s)
  • drawCircle: 3 call(s)
  • endDrawing: 3 call(s)
  • closeWindow: 1 call(s)
```

## Limitations

### Runtime Errors
The nimini runtime uses `quit()` for runtime errors (undefined variables, type mismatches, etc.), which terminates the program immediately. This means:

- ✅ **Can catch:** Tokenization errors, parsing errors
- ❌ **Cannot catch:** Runtime errors (undefined variables, type mismatches)
- ⚠️  **Workaround:** Runtime errors will still show the error message before terminating

### What You Get for Each Error Type

| Error Type | Line Numbers | Code Context | Suggestions | Stack Trace |
|------------|--------------|--------------|-------------|-------------|
| **Tokenization** | ✅ | ✅ | ✅ | ✅ |
| **Parsing** | ✅ | ✅ | ✅ | ✅ |
| **Runtime** | ❌ | ❌ | ❌ | ❌ |

## Tips for Better Error Messages

1. **Start simple** - Test with minimal code first
2. **Add incrementally** - Add features one at a time
3. **Check spelling** - Most runtime errors are typos
4. **Review bindings** - Make sure functions are registered in nimrtest.nim
5. **Use niminitest** - For parsing-only validation: `nim r niminitest.nim your_file.nim`

## Common Errors and Fixes

### "Expected ':'" 
- **Cause:** Unsupported Nim syntax (type declarations, complex expressions)
- **Fix:** Simplify code, remove type blocks and proc definitions

### "Undefined variable 'functionName'"
- **Cause:** Function not registered or typo
- **Fix:** Check spelling, add to `registerHeadlessRaylibBindings()` if needed

### "Cannot convert X to Y"
- **Cause:** Type mismatch (passing int where float expected, etc.)
- **Fix:** Add explicit type conversion: `float(myInt)` or `int(myFloat)`

## Adding New Functions to Mock

To add a new raylib function to the headless test:

```nim
registerNative("myNewFunction", proc(env: ref Env, args: seq[Value]): Value =
  logCall("myNewFunction", $args[0].i, $args[1].s)
  echo "📝 Mock: myNewFunction(", args[0].i, ", \"", args[1].s, "\")"
  result = valNil()  # or valInt(...), valFloat(...), etc.
)
```

Place this in the `registerHeadlessRaylibBindings()` procedure in nimrtest.nim.
