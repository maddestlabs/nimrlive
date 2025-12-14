#!/usr/bin/env nim
## Headless testing for nimrlive - validates code without rendering
## This runs in containers without display servers
##
## Usage: nim r test_headless.nim <script.nim>
## Example: nim r test_headless.nim examples/nimr_ball.nim

import nimini
import std/[os, strutils, tables, math]

# Track which raylib functions were called (for validation)
var callLog: seq[tuple[fn: string, args: seq[string]]]

proc logCall(fnName: string, args: varargs[string]) =
  var argSeq: seq[string] = @[]
  for arg in args:
    argSeq.add(arg)
  callLog.add((fn: fnName, args: argSeq))

# Track registered functions for validation
var registeredFunctions: seq[string] = @[]

# Mock raylib bindings that don't require a display
proc registerHeadlessRaylibBindings() =
  ## Register mock raylib functions for headless testing
  registeredFunctions = @[]
  
  # Window functions
  registerNative("initWindow", proc(env: ref Env, args: seq[Value]): Value =
    logCall("initWindow", $args[0].i, $args[1].i, args[2].s)
    echo "📝 Mock: initWindow(", args[0].i, ", ", args[1].i, ", \"", args[2].s, "\")"
    result = valNil()
  )
  
  registerNative("closeWindow", proc(env: ref Env, args: seq[Value]): Value =
    logCall("closeWindow")
    echo "📝 Mock: closeWindow()"
    result = valNil()
  )
  
  registerNative("windowShouldClose", proc(env: ref Env, args: seq[Value]): Value =
    logCall("windowShouldClose")
    # Return false for first few calls, then true to exit loop
    result = valBool(callLog.len > 10)
  )
  
  registerNative("setTargetFPS", proc(env: ref Env, args: seq[Value]): Value =
    logCall("setTargetFPS", $args[0].i)
    echo "📝 Mock: setTargetFPS(", args[0].i, ")"
    result = valNil()
  )
  
  # Screen functions
  registerNative("getScreenWidth", proc(env: ref Env, args: seq[Value]): Value =
    result = valInt(800)
  )
  
  registerNative("getScreenHeight", proc(env: ref Env, args: seq[Value]): Value =
    result = valInt(450)
  )
  
  # Drawing functions
  registerNative("beginDrawing", proc(env: ref Env, args: seq[Value]): Value =
    logCall("beginDrawing")
    result = valNil()
  )
  
  registerNative("endDrawing", proc(env: ref Env, args: seq[Value]): Value =
    logCall("endDrawing")
    result = valNil()
  )
  
  registerNative("clearBackground", proc(env: ref Env, args: seq[Value]): Value =
    logCall("clearBackground", $args[0].i)
    result = valNil()
  )
  
  # Drawing primitives
  registerNative("drawCircle", proc(env: ref Env, args: seq[Value]): Value =
    # Support both signatures:
    # drawCircle(x: int, y: int, radius: float, color: Color) - 4 args
    # drawCircle(position: Vector2, radius: float, color: Color) - 3 args
    if args.len == 4:
      logCall("drawCircle", $args[0].i, $args[1].i, $args[2].f, "Color")
    elif args.len == 3:
      logCall("drawCircle", "Vector2", $args[1].f, "Color")
    result = valNil()
  )
  
  registerNative("drawCircleV", proc(env: ref Env, args: seq[Value]): Value =
    logCall("drawCircleV", "Vector2", $args[1].f, $args[2].i)
    result = valNil()
  )
  
  registerNative("drawRectangle", proc(env: ref Env, args: seq[Value]): Value =
    logCall("drawRectangle", $args[0].i, $args[1].i, $args[2].i, $args[3].i, $args[4].i)
    result = valNil()
  )
  
  registerNative("drawText", proc(env: ref Env, args: seq[Value]): Value =
    logCall("drawText", args[0].s, $args[1].i, $args[2].i, $args[3].i, $args[4].i)
    echo "📝 Mock: drawText(\"", args[0].s, "\", ...)"
    result = valNil()
  )
  
  registerNative("drawFPS", proc(env: ref Env, args: seq[Value]): Value =
    logCall("drawFPS", $args[0].i, $args[1].i)
    result = valNil()
  )
  
  # Input functions
  registerNative("getMousePosition", proc(env: ref Env, args: seq[Value]): Value =
    # Return mock position as a map (Vector2-like)
    let posMap = valMap()
    posMap.map["x"] = valFloat(400.0)
    posMap.map["y"] = valFloat(300.0)
    result = posMap
  )
  
  registerNative("getMouseX", proc(env: ref Env, args: seq[Value]): Value =
    result = valInt(400)
  )
  
  registerNative("getMouseY", proc(env: ref Env, args: seq[Value]): Value =
    result = valInt(300)
  )
  
  registerNative("isMouseButtonPressed", proc(env: ref Env, args: seq[Value]): Value =
    result = valBool(false)
  )
  
  registerNative("isKeyPressed", proc(env: ref Env, args: seq[Value]): Value =
    result = valBool(false)
  )
  
  # Collision detection
  registerNative("checkCollisionPointCircle", proc(env: ref Env, args: seq[Value]): Value =
    # Mock: always return false to allow free movement
    result = valBool(false)
  )
  
  # Math functions
  registerNative("arctan2", proc(env: ref Env, args: seq[Value]): Value =
    let y = args[0].f
    let x = args[1].f
    result = valFloat(arctan2(y, x))
  )
  
  registerNative("cos", proc(env: ref Env, args: seq[Value]): Value =
    result = valFloat(cos(args[0].f))
  )
  
  registerNative("sin", proc(env: ref Env, args: seq[Value]): Value =
    result = valFloat(sin(args[0].f))
  )
  
  # Time functions
  registerNative("getFrameTime", proc(env: ref Env, args: seq[Value]): Value =
    result = valFloat(0.016666667) # ~60 FPS
  )
  
  registerNative("getTime", proc(env: ref Env, args: seq[Value]): Value =
    result = valFloat(float(callLog.len) * 0.016666667)
  )
  
  # Colors - define as Color objects (maps) in the runtime environment
  let createColor = proc(r, g, b, a: int): Value =
    var colorMap = initTable[string, Value]()
    colorMap["r"] = valInt(r)
    colorMap["g"] = valInt(g)
    colorMap["b"] = valInt(b)
    colorMap["a"] = valInt(a)
    Value(kind: vkMap, map: colorMap)
  
  defineVar(runtimeEnv, "RAYWHITE", createColor(245, 245, 245, 255))
  defineVar(runtimeEnv, "RayWhite", createColor(245, 245, 245, 255))
  defineVar(runtimeEnv, "LIGHTGRAY", createColor(200, 200, 200, 255))
  defineVar(runtimeEnv, "LightGray", createColor(200, 200, 200, 255))
  defineVar(runtimeEnv, "GRAY", createColor(130, 130, 130, 255))
  defineVar(runtimeEnv, "Gray", createColor(130, 130, 130, 255))
  defineVar(runtimeEnv, "DARKGRAY", createColor(80, 80, 80, 255))
  defineVar(runtimeEnv, "DarkGray", createColor(80, 80, 80, 255))
  defineVar(runtimeEnv, "BLACK", createColor(0, 0, 0, 255))
  defineVar(runtimeEnv, "Black", createColor(0, 0, 0, 255))
  defineVar(runtimeEnv, "RED", createColor(230, 41, 55, 255))
  defineVar(runtimeEnv, "GREEN", createColor(0, 228, 48, 255))
  defineVar(runtimeEnv, "BLUE", createColor(0, 121, 241, 255))
  defineVar(runtimeEnv, "YELLOW", createColor(253, 249, 0, 255))
  defineVar(runtimeEnv, "WHITE", createColor(255, 255, 255, 255))
  defineVar(runtimeEnv, "White", createColor(255, 255, 255, 255))
  defineVar(runtimeEnv, "MAROON", createColor(190, 33, 55, 255))
  defineVar(runtimeEnv, "Maroon", createColor(190, 33, 55, 255))
  defineVar(runtimeEnv, "BROWN", createColor(127, 106, 79, 255))
  defineVar(runtimeEnv, "Brown", createColor(127, 106, 79, 255))
  defineVar(runtimeEnv, "DARKGREEN", createColor(0, 117, 44, 255))
  defineVar(runtimeEnv, "DarkGreen", createColor(0, 117, 44, 255))
  
  echo "✓ Registered headless raylib bindings (mock)"

proc extractLineContext(code: string, errorMsg: string): tuple[lineNum: int, context: seq[string]] =
  ## Extract line number and surrounding context from error message
  result.lineNum = -1
  result.context = @[]
  
  # Try to extract line number from error message
  let lines = code.split('\n')
  var targetLine = -1
  
  # Look for "line X" or "Line X" in error message
  var i = 0
  while i < errorMsg.len - 5:
    if (errorMsg[i..i+4].toLowerAscii() == "line "):
      var numStr = ""
      var j = i + 5
      while j < errorMsg.len and errorMsg[j].isDigit:
        numStr.add(errorMsg[j])
        inc j
      if numStr.len > 0:
        try:
          targetLine = parseInt(numStr)
          break
        except:
          discard
    inc i
  
  if targetLine > 0 and targetLine <= lines.len:
    result.lineNum = targetLine
    # Get context: 3 lines before and after
    let startLine = max(0, targetLine - 4)
    let endLine = min(lines.len - 1, targetLine + 2)
    
    for i in startLine..endLine:
      let marker = if i == targetLine - 1: ">>> " else: "    "
      result.context.add(marker & $(i + 1) & "| " & lines[i])

proc getTokenContext(tokens: seq[Token], errorMsg: string): string =
  ## Get context about tokens when parsing fails
  result = ""
  
  if tokens.len == 0:
    return "No tokens were generated"
  
  # Show last few tokens
  result = "Recent tokens:\n"
  let startIdx = max(0, tokens.len - 10)
  for i in startIdx..<tokens.len:
    let marker = if i == tokens.len - 1: ">>> " else: "    "
    result.add(marker & "[" & $i & "] " & $tokens[i].kind & " '" & tokens[i].lexeme & "'\n")

proc suggestFix(errorMsg: string, phase: string): seq[string] =
  ## Provide helpful suggestions based on error type
  result = @[]
  
  let msgLower = errorMsg.toLowerAscii()
  
  if "expected ':'" in msgLower:
    result.add("Missing ':' in type/object declaration or named parameter")
    result.add("Nimini may not support all Nim syntax - try simplifying")
    result.add("Check if you're using 'type' blocks (not fully supported)")
  elif "expected '='" in msgLower:
    result.add("Missing '=' in assignment or const declaration")
    result.add("Check variable initialization syntax")
  elif "expected" in msgLower:
    result.add("Syntax error - unexpected token encountered")
    result.add("Check for missing/extra punctuation: () [] {} , ;")
  elif "undefined" in msgLower or "not found" in msgLower:
    result.add("Function or variable not defined")
    result.add("Check spelling and ensure it's registered or declared")
    result.add("For raylib functions, ensure they're in the mock bindings")
  elif "type mismatch" in msgLower or "cannot convert" in msgLower:
    result.add("Type error - value type doesn't match expected type")
    result.add("Check function arguments match expected types")
  elif "division by zero" in msgLower:
    result.add("Arithmetic error - attempted to divide by zero")
  
  if phase == "parsing":
    result.add("📖 Nimini supports a subset of Nim syntax")
    result.add("📖 Try removing: type blocks, proc definitions, complex expressions")
    result.add("📖 Use simple statements: var, let, const, if, while, for")

proc testCodeHeadless(code: string, scriptPath: string = ""): bool =
  ## Test nimini code with mock raylib bindings (headless)
  result = false
  callLog = @[]
  var phase = "initialization"
  var tokens: seq[Token] = @[]
  
  echo "==================================="
  echo "HEADLESS NIMINI + RAYLIB TEST"
  echo "==================================="
  echo ""
  echo "This test validates code execution"
  echo "without requiring a display server."
  echo ""
  
  # Initialize runtime
  try:
    echo "Initializing runtime..."
    initRuntime()
    initStdlib()
    registerHeadlessRaylibBindings()
    echo ""
  except Exception as e:
    echo "❌ FATAL: Runtime initialization failed"
    echo "Error: ", e.msg
    return false
  
  # Execute the code
  try:
    phase = "tokenization"
    echo "Tokenizing code..."
    tokens = tokenizeDsl(code)
    echo "✓ Got ", tokens.len, " tokens"
    
    phase = "parsing"
    echo "Parsing code..."
    let program = parseDsl(tokens)
    echo "✓ Parsed ", program.stmts.len, " statements"
    
    phase = "execution"
    echo ""
    echo "Executing program (mock raylib)..."
    echo "-" .repeat(50)
    echo "⚠️  Note: Runtime errors (undefined variables/functions) will cause immediate termination"
    echo ""
    execProgram(program, runtimeEnv)
    echo "-" .repeat(50)
    echo ""
    
    # Report statistics
    echo "==================================="
    echo "✅ SUCCESS - Code executed!"
    echo "==================================="
    echo ""
    echo "📊 Statistics:"
    echo "  • Total API calls: ", callLog.len
    echo ""
    
    # Show function call frequency
    var callCounts: Table[string, int]
    for call in callLog:
      if callCounts.hasKey(call.fn):
        callCounts[call.fn] += 1
      else:
        callCounts[call.fn] = 1
    
    echo "📋 API Usage:"
    for fn, count in callCounts:
      echo "  • ", fn, ": ", count, " call(s)"
    
    echo ""
    result = true
    
  except Exception as e:
    echo ""
    echo "=" .repeat(70)
    echo "❌ ERROR IN ", phase.toUpperAscii(), " PHASE"
    echo "=" .repeat(70)
    echo ""
    
    # Error details
    echo "🔍 Error Details:"
    echo "  Type: ", e.name
    echo "  Message: ", e.msg
    echo ""
    
    # Phase-specific context
    case phase
    of "tokenization":
      echo "🔍 Tokenization Context:"
      echo "  Failed to tokenize source code into tokens"
      echo "  This usually indicates invalid characters or malformed syntax"
      echo ""
      
    of "parsing":
      echo "🔍 Parsing Context:"
      echo "  Tokens generated: ", tokens.len
      echo ""
      echo getTokenContext(tokens, e.msg)
      echo ""
      
    of "execution":
      echo "🔍 Execution Context:"
      echo "  Parsed statements successfully"
      echo "  Error occurred during runtime execution"
      echo "  API calls before error: ", callLog.len
      echo ""
      
      if callLog.len > 0:
        echo "  Last ", min(10, callLog.len), " API calls:"
        let startIdx = max(0, callLog.len - 10)
        for i in startIdx..<callLog.len:
          let marker = if i == callLog.len - 1: ">>> " else: "    "
          echo marker, i + 1, ". ", callLog[i].fn, "(", callLog[i].args.join(", "), ")"
        echo ""
    else:
      discard
    
    # Source code context
    let (lineNum, context) = extractLineContext(code, e.msg)
    if context.len > 0:
      echo "📄 Source Code Context (around line ", lineNum, "):"
      for line in context:
        echo line
      echo ""
    elif scriptPath.len > 0:
      echo "📄 Script: ", scriptPath
      echo ""
    
    # Stack trace
    echo "📚 Stack Trace:"
    let trace = e.getStackTrace()
    if trace.len > 0:
      for line in trace.split('\n'):
        if line.len > 0:
          echo "  ", line
    else:
      echo "  (no stack trace available)"
    echo ""
    
    # Suggestions
    let suggestions = suggestFix(e.msg, phase)
    if suggestions.len > 0:
      echo "💡 Suggestions:"
      for suggestion in suggestions:
        echo "  • ", suggestion
      echo ""
    
    # Recovery hints
    echo "🔧 Debugging Steps:"
    case phase
    of "tokenization":
      echo "  1. Check for invalid characters in source code"
      echo "  2. Ensure strings are properly quoted"
      echo "  3. Look for unclosed brackets/parentheses"
      echo "  4. Try removing comments or complex syntax"
    of "parsing":
      echo "  1. Simplify complex expressions"
      echo "  2. Remove 'type' and 'proc' declarations (use inline code)"
      echo "  3. Check for unsupported Nim features"
      echo "  4. Review nimini documentation: docs/NEW_FEATURES_SUMMARY.md"
      echo "  5. Try: nim r niminitest.nim ", scriptPath
    of "execution":
      echo "  1. Check if all called functions are registered"
      echo "  2. Verify variable names are spelled correctly"
      echo "  3. Ensure types match (int vs float, etc.)"
      echo "  4. Review registered raylib functions (see error above)"
      echo "  5. Add missing functions to nimrtest.nim mock bindings"
    else:
      echo "  1. Check error message above for details"
      echo "  2. Simplify the code to isolate the issue"
    
    echo ""
    echo "=" .repeat(70)
    
    result = false

proc main() =
  if paramCount() == 0:
    echo "Usage: nim r nimrtest.nim <script.nim>"
    echo ""
    echo "Headless testing validates nimini + raylib code"
    echo "without requiring a display server (X11/Wayland)."
    echo ""
    echo "Perfect for:"
    echo "  • CI/CD pipelines"
    echo "  • Docker containers"
    echo "  • Headless servers"
    echo "  • Automated testing"
    echo ""
    echo "Examples:"
    echo "  nim r nimrtest.nim examples/nimr_ball.nim"
    echo "  nim r nimrtest.nim my_test.nim"
    echo ""
    echo "Features:"
    echo "  ✓ Detailed error reporting with line numbers"
    echo "  ✓ Code context highlighting"
    echo "  ✓ API call tracking"
    echo "  ✓ Helpful fix suggestions"
    quit(1)
  
  let scriptPath = paramStr(1)
  
  if not fileExists(scriptPath):
    echo "Error: File not found: ", scriptPath
    quit(1)
  
  let code = readFile(scriptPath)
  
  echo "Testing: ", scriptPath
  echo ""
  
  if testCodeHeadless(code, scriptPath):
    quit(0)
  else:
    quit(1)

when isMainModule:
  main()
