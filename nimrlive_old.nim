## NimRLive - Live Nim scripting with raylib using Nimini
## Entry point that loads and executes Nim scripts with naylib bindings

import nimini
import raylib
import std/[os, strutils, tables]

when defined(emscripten):
  # For WASM build, we'll receive code from JavaScript via C interop
  # These functions are exported by the JavaScript side in shell.html
  proc receiveGistCode(): cstring {.importc, nodecl.}
  proc hasGistCode(): bool {.importc, nodecl.}

proc registerNaylibApi(interp: var Nimini) =
  ## Register naylib/raylib API functions with Nimini interpreter
  ## This makes raylib functions callable from loaded scripts
  
  # Window management
  interp.registerProc("initWindow", initWindow)
  interp.registerProc("closeWindow", closeWindow)
  interp.registerProc("windowShouldClose", windowShouldClose)
  interp.registerProc("setTargetFPS", setTargetFPS)
  
  # Drawing functions
  interp.registerProc("beginDrawing", beginDrawing)
  interp.registerProc("endDrawing", endDrawing)
  interp.registerProc("clearBackground", clearBackground)
  
  # Shape drawing
  interp.registerProc("drawCircle", proc(position: Vector2, radius: float32, color: Color) =
    drawCircle(position, radius, color))
  interp.registerProc("drawCircleLines", drawCircleLines)
  interp.registerProc("drawRectangle", drawRectangle)
  interp.registerProc("drawRectangleRec", drawRectangleRec)
  interp.registerProc("drawRectangleLines", drawRectangleLines)
  
  # Text drawing
  interp.registerProc("drawText", drawText)
  interp.registerProc("drawFPS", drawFPS)
  
  # Colors and effects
  interp.registerProc("fade", fade)
  
  # Types - register Color constructors
  interp.registerValue("RayWhite", RayWhite)
  interp.registerValue("White", White)
  interp.registerValue("Black", Black)
  interp.registerValue("Maroon", Maroon)
  interp.registerValue("DarkGray", DarkGray)
  interp.registerValue("Gray", Gray)
  
  # Register Vector2 constructor
  interp.registerType("Vector2")
  interp.registerType("Color")

proc loadAndExecuteScript(scriptPath: string) =
  ## Load a Nim script file and execute it with Nimini
  if not fileExists(scriptPath):
    echo "Error: Script file not found: ", scriptPath
    return
  
  let code = readFile(scriptPath)
  var interp = newNimini()
  
  # Register all naylib functions
  interp.registerNaylibApi()
  
  # Execute the script
  try:
    interp.execute(code)
  except Exception as e:
    echo "Script execution error: ", e.msg

proc main() =
  when defined(emscripten):
    # WASM mode: check for Gist code from JavaScript
    if hasGistCode():
      let code = $receiveGistCode()
      var interp = newNimini()
      interp.registerNaylibApi()
      try:
        interp.execute(code)
      except Exception as e:
        echo "Gist script execution error: ", e.msg
    else:
      # No Gist provided, load default nimr.nim
      loadAndExecuteScript("nimr.nim")
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