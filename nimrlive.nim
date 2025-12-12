## NimRLive - Live Nim scripting with raylib using Nimini
## Entry point that loads and executes Nim scripts with naylib bindings

import nimini
import raylib
import raylib_bindings
import std/[os, strutils]

when defined(emscripten):
  # State management for gist loading
  var waitingForGist = false
  var gistCodeLoaded = false
  
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
      registerRaylibBindings()
      echo "Runtime initialized and API registered"
    else:
      echo "Runtime already initialized, re-registering API..."
      registerRaylibBindings()
    
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

proc loadAndExecuteScript(scriptPath: string) =
  ## Load a Nim script file and execute it with Nimini
  if not fileExists(scriptPath):
    echo "Error: Script file not found: ", scriptPath
    return
  
  let code = readFile(scriptPath)
  
  # Initialize Nimini runtime
  initRuntime()
  registerRaylibBindings()
  
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
      registerRaylibBindings()
      echo "Ready - waiting for gist or user interaction"
  else:
    # Native mode: check command line arguments
    if paramCount() > 0:
      let scriptPath = paramStr(1)
      echo "Loading script: ", scriptPath
      loadAndExecuteScript(scriptPath)
    else:
      # No arguments, show usage and exit
      echo "NimRLive - Live Nim scripting with raylib using Nimini"
      echo ""
      echo "Usage: nimrlive <script.nim>"
      echo ""
      echo "Example: ./nimrlive nimr.nim"
      quit(0)

when isMainModule:
  main()
