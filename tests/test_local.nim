#!/usr/bin/env nim
## Local testing script for nimrlive code
## Usage: nim r test_local.nim <your_test_file.nim>
## Example: nim r test_local.nim examples/nimr_ball.nim

import nimini
import raylib_bindings
import std/[os, strutils]

proc testCodeLocally(code: string): bool =
  ## Test nimini code with raylib bindings locally
  result = false
  
  echo "==================================="
  echo "LOCAL NIMINI + RAYLIB TEST"
  echo "==================================="
  echo ""
  
  # Initialize runtime
  echo "Initializing runtime..."
  initRuntime()
  initStdlib()
  registerRaylibBindings()
  echo "✓ Runtime initialized with raylib bindings"
  echo ""
  
  # Execute the code
  try:
    echo "Tokenizing code..."
    let tokens = tokenizeDsl(code)
    echo "✓ Got ", tokens.len, " tokens"
    
    echo "Parsing code..."
    let program = parseDsl(tokens)
    echo "✓ Parsed ", program.stmts.len, " statements"
    
    echo "Executing program..."
    execProgram(program, runtimeEnv)
    echo ""
    echo "==================================="
    echo "✅ SUCCESS - Code executed!"
    echo "==================================="
    result = true
    
  except Exception as e:
    echo ""
    echo "==================================="
    echo "❌ ERROR during execution"
    echo "==================================="
    echo "Error: ", e.msg
    echo ""
    echo "Stack trace:"
    echo e.getStackTrace()
    result = false

proc main() =
  if paramCount() == 0:
    echo "Usage: nim r test_local.nim <script.nim>"
    echo ""
    echo "Examples:"
    echo "  nim r test_local.nim examples/nimr_ball.nim"
    echo "  nim r test_local.nim my_test.nim"
    quit(1)
  
  let scriptPath = paramStr(1)
  
  if not fileExists(scriptPath):
    echo "Error: File not found: ", scriptPath
    quit(1)
  
  let code = readFile(scriptPath)
  
  if testCodeLocally(code):
    quit(0)
  else:
    quit(1)

when isMainModule:
  main()
