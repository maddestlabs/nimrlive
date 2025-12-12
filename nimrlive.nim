## NimRLive - Live Nim scripting with raylib using Nimini
## Entry point that loads and executes Nim scripts with naylib bindings
##
## Build variants:
##   -d:nimrlive_minimal  - Basic 2D, text, shapes (default, smallest)
##   -d:nimrlive_3d       - Adds 3D models, camera, lighting
##   -d:nimrlive_complete - Full raylib with audio, textures, shaders

import nimini
import raylib

# Import appropriate bindings based on build configuration
when defined(nimrlive_complete):
  import raylib_bindings  # Full bindings
  const BUILD_TYPE = "complete"
elif defined(nimrlive_3d):
  import raylib_bindings  # 3D bindings (TODO: create separate file)
  const BUILD_TYPE = "3d"
else:
  # Default to minimal build
  import raylib_bindings_minimal
  const BUILD_TYPE = "minimal"

import std/[os, strutils]

when defined(emscripten):
  # State management for gist loading
  var waitingForGist = false
  var gistCodeLoaded = false
  
  # Export function to set waiting state before initialization
  proc setWaitingForGist() {.exportc.} =
    echo "Setting waitingForGist flag"
    waitingForGist = true
  
  # Detect required build based on code imports
  proc detectRequiredBuild(code: string): string =
    ## Analyze code to determine which build is needed
    ## Returns: "minimal", "3d", or "complete"
    
    # Check for audio functions
    if code.contains("loadSound") or code.contains("playSound") or 
       code.contains("loadMusic") or code.contains("playMusic"):
      return "complete"
    
    # Check for texture/image loading
    if code.contains("loadTexture") or code.contains("loadImage") or
       code.contains("drawTexture"):
      return "complete"
    
    # Check for 3D functions
    if code.contains("drawCube") or code.contains("drawModel") or
       code.contains("Camera3D") or code.contains("drawGrid"):
      return "3d"
    
    # Check for shader functions
    if code.contains("loadShader") or code.contains("beginShaderMode"):
      return "complete"
    
    # Default to minimal
    return "minimal"
  
  # Export function to check if rebuild is needed
  proc shouldRebuildForCode(code: cstring): cstring {.exportc.} =
    ## Check if the current build supports the code
    ## Returns empty string if OK, or required build name if rebuild needed
    let nimCode = $code
    let requiredBuild = detectRequiredBuild(nimCode)
    
    echo "Current build: ", BUILD_TYPE
    echo "Required build: ", requiredBuild
    
    if requiredBuild == BUILD_TYPE:
      return cstring("")
    else:
      return cstring(requiredBuild)
  
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
      echo "Runtime initialized and API registered (", BUILD_TYPE, " build)"
    else:
      echo "Runtime already initialized, re-registering API..."
      registerRaylibBindings()
    
    # Execute the loaded code
    try:
      echo "Tokenizing and parsing gist code..."
      let tokens = tokenizeDsl(nimCode)
      echo "Got ", tokens.len, " tokens"
      
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
