## NimRLive - Live Nim scripting with raylib using Nimini
## Entry point that loads and executes Nim scripts with naylib bindings

import nimini
import raylib
import std/[os, strutils]

when defined(emscripten):
  # State management for gist loading
  var waitingForGist = false
  var gistCodeLoaded = false
  
  # Forward declaration
  proc registerNaylibApi()
  
  # Export function to set waiting state before initialization
  proc setWaitingForGist() {.exportc.} =
    echo "Setting waitingForGist flag"
    waitingForGist = true
  
  # Export function to load code dynamically from JavaScript
  proc loadCodeFromJS(code: cstring) {.exportc.} =
    echo "loadCodeFromJS called with ", len($code), " bytes"
    if gistCodeLoaded:
      echo "Code already loaded, ignoring"
      return
    
    gistCodeLoaded = true
    let nimCode = $code
    
    echo "Code to execute:"
    echo "================================"
    echo nimCode
    echo "================================"
    
    # Initialize runtime if not already done
    if runtimeEnv == nil:
      echo "Initializing runtime..."
      initRuntime()
      registerNaylibApi()
      echo "Runtime initialized and API registered"
    else:
      echo "Runtime already initialized, re-registering API..."
      registerNaylibApi()
    
    # Debug: Check if drawFPS is registered
    echo "Checking runtime environment..."
    if runtimeEnv != nil:
      echo "runtimeEnv is not nil"
    else:
      echo "ERROR: runtimeEnv is nil!"
    
    # Execute the loaded code
    try:
      echo "Tokenizing and parsing gist code..."
      let tokens = tokenizeDsl(nimCode)
      echo "Got ", tokens.len, " tokens"
      
      # Debug: Print tokens to see what we're parsing
      echo "DEBUG: First 20 tokens:"
      for i in 0..<min(20, tokens.len):
        echo "  [", i, "] ", tokens[i].kind, " '", tokens[i].lexeme, "'"
      
      let program = parseDsl(tokens)
      echo "Parsed program, executing..."
      echo "Program has ", program.stmts.len, " statements"
      
      execProgram(program, runtimeEnv)
      echo "Gist code loaded and executed successfully"
    except Exception as e:
      echo "Gist code execution error: ", e.msg
      echo "Stack trace: ", e.getStackTrace()

# Color constants that need to persist (not be destroyed after registerNaylibApi returns)
var rayWhiteColor = RayWhite
var whiteColor = White
var blackColor = Black
var grayColor = Gray
var darkGrayColor = DarkGray
var maroonColor = Maroon

proc registerNaylibApi() =
  ## Register naylib/raylib API functions with Nimini runtime
  ## This makes raylib functions callable from loaded scripts
  
  echo "=== Registering Naylib API ==="
  
  # Window management
  registerNative("initWindow", proc(env: ref Env; args: seq[Value]): Value =
    let width = args[0].i.int32
    let height = args[1].i.int32
    let title = args[2].s
    initWindow(width, height, title)
    valNil()
  )
  
  registerNative("closeWindow", proc(env: ref Env; args: seq[Value]): Value =
    closeWindow()
    valNil()
  )
  
  registerNative("windowShouldClose", proc(env: ref Env; args: seq[Value]): Value =
    valBool(windowShouldClose())
  )
  
  registerNative("setTargetFPS", proc(env: ref Env; args: seq[Value]): Value =
    setTargetFPS(args[0].i.int32)
    valNil()
  )
  
  # Drawing functions
  registerNative("beginDrawing", proc(env: ref Env; args: seq[Value]): Value =
    beginDrawing()
    valNil()
  )
  
  registerNative("endDrawing", proc(env: ref Env; args: seq[Value]): Value =
    endDrawing()
    valNil()
  )
  
  registerNative("clearBackground", proc(env: ref Env; args: seq[Value]): Value =
    # Extract Color from args - for now assume it's passed as a pointer
    # This is where you'll enhance Nimini to support custom types better
    let colorPtr = cast[ptr Color](args[0].ptrVal)
    clearBackground(colorPtr[])
    valNil()
  )
  
  # Text drawing
  registerNative("drawText", proc(env: ref Env; args: seq[Value]): Value =
    let text = args[0].s
    let posX = args[1].i.int32
    let posY = args[2].i.int32
    let fontSize = args[3].i.int32
    let colorPtr = cast[ptr Color](args[4].ptrVal)
    drawText(text, posX, posY, fontSize, colorPtr[])
    valNil()
  )
  
  registerNative("drawFPS", proc(env: ref Env; args: seq[Value]): Value =
    let posX = args[0].i.int32
    let posY = args[1].i.int32
    drawFPS(posX, posY)
    valNil()
  )
  
  # Register Color constants as pointers (using global vars defined above)
  registerNative("RayWhite", proc(env: ref Env; args: seq[Value]): Value =
    valPointer(addr rayWhiteColor)
  )
  
  registerNative("White", proc(env: ref Env; args: seq[Value]): Value =
    valPointer(addr whiteColor)
  )
  
  registerNative("Black", proc(env: ref Env; args: seq[Value]): Value =
    valPointer(addr blackColor)
  )
  
  registerNative("Gray", proc(env: ref Env; args: seq[Value]): Value =
    valPointer(addr grayColor)
  )
  
  registerNative("DarkGray", proc(env: ref Env; args: seq[Value]): Value =
    valPointer(addr darkGrayColor)
  )
  
  registerNative("Maroon", proc(env: ref Env; args: seq[Value]): Value =
    valPointer(addr maroonColor)
  )
  
  echo "=== Naylib API registration complete ==="

proc loadAndExecuteScript(scriptPath: string) =
  ## Load a Nim script file and execute it with Nimini
  if not fileExists(scriptPath):
    echo "Error: Script file not found: ", scriptPath
    return
  
  let code = readFile(scriptPath)
  
  # Initialize Nimini runtime
  initRuntime()
  registerNaylibApi()
  
  # Tokenize, parse, and execute
  try:
    let tokens = tokenizeDsl(code)
    let program = parseDsl(tokens)
    execProgram(program, runtimeEnv)
  except Exception as e:
    echo "Script execution error: ", e.msg

proc main() =
  when defined(emscripten):
    # WASM mode: check if we should wait for dynamic gist loading
    if waitingForGist:
      echo "Waiting for gist to be loaded via loadCodeFromJS..."
      # The gist loading path will handle initialization, so do nothing here
      # Just return and let loadCodeFromJS() handle everything
      return
    else:
      # No Gist provided, running in standalone mode
      echo "No gist provided, running in standalone mode..."
      # Don't execute any script in standalone mode
      # Just initialize and let the user load a gist
      initRuntime()
      registerNaylibApi()
      echo "Ready - waiting for gist or user interaction"
  else:
    # Native mode: check command line arguments
    if paramCount() > 0:
      let scriptPath = paramStr(1)
      loadAndExecuteScript(scriptPath)
    else:
      # No arguments, load default nimr.nim
      loadAndExecuteScript("nimr.nim")

when isMainModule:
  main()
