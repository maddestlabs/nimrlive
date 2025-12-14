#!/usr/bin/env nim
## Comprehensive test runner for nimrlive
## Runs multiple tests and generates a report
##
## Usage: nim r test_suite.nim [--headless]

import std/[os, strutils, times, terminal]
import nimini

# Import test configurations
const TestFiles = [
  "examples/nimr_ball.nim",
  "examples/following_eyes.nim"
]

type
  TestMode = enum
    tmLocal      ## Run with actual raylib (requires display)
    tmHeadless   ## Run with mock raylib (headless)
  
  TestResult = object
    file: string
    mode: TestMode
    success: bool
    duration: float
    error: string
    tokensCount: int
    statementsCount: int
    apiCalls: int

var results: seq[TestResult]

# Include headless mock bindings
include "test_headless"

proc runTestWithMode(filePath: string, mode: TestMode): TestResult =
  result.file = filePath
  result.mode = mode
  result.success = false
  
  if not fileExists(filePath):
    result.error = "File not found"
    return
  
  let code = readFile(filePath)
  let startTime = cpuTime()
  
  try:
    # Initialize runtime based on mode
    initRuntime()
    initStdlib()
    
    case mode
    of tmHeadless:
      callLog = @[]  # Reset call log
      registerHeadlessRaylibBindings()
    of tmLocal:
      when not defined(emscripten):
        import raylib_bindings
        registerRaylibBindings()
      else:
        result.error = "Local mode not available in WASM build"
        return
    
    # Execute
    let tokens = tokenizeDsl(code)
    result.tokensCount = tokens.len
    
    let program = parseDsl(tokens)
    result.statementsCount = program.stmts.len
    
    execProgram(program, runtimeEnv)
    
    if mode == tmHeadless:
      result.apiCalls = callLog.len
    
    result.success = true
    result.duration = cpuTime() - startTime
    
  except Exception as e:
    result.error = e.msg
    result.duration = cpuTime() - startTime

proc printResults() =
  ## Print a formatted test report
  echo ""
  echo "=" .repeat(80)
  stdout.styledWrite(fgCyan, styleBright, "NIMRLIVE TEST SUITE RESULTS\n")
  echo "=" .repeat(80)
  echo ""
  
  var passed = 0
  var failed = 0
  
  for result in results:
    let modeStr = case result.mode
      of tmLocal: "LOCAL"
      of tmHeadless: "HEADLESS"
    
    stdout.write("  ")
    if result.success:
      stdout.styledWrite(fgGreen, "✓ ")
      passed += 1
    else:
      stdout.styledWrite(fgRed, "✗ ")
      failed += 1
    
    stdout.write(result.file.extractFilename(), " [", modeStr, "] ")
    
    if result.success:
      stdout.styledWrite(fgGreen, "(", result.duration.formatFloat(ffDecimal, 3), "s)\n")
      echo "      Tokens: ", result.tokensCount, ", Statements: ", result.statementsCount
      if result.mode == tmHeadless:
        echo "      API Calls: ", result.apiCalls
    else:
      stdout.styledWrite(fgRed, "FAILED\n")
      echo "      Error: ", result.error
    echo ""
  
  echo "-" .repeat(80)
  stdout.write("Total: ")
  stdout.styledWrite(fgGreen, $passed, " passed")
  stdout.write(", ")
  
  if failed > 0:
    stdout.styledWrite(fgRed, $failed, " failed")
  else:
    stdout.write($failed, " failed")
  
  echo ""
  echo "=" .repeat(80)

proc main() =
  let args = commandLineParams()
  let headlessMode = args.len > 0 and args[0] == "--headless"
  
  echo "NimRLive Test Suite"
  echo ""
  
  if headlessMode:
    echo "Running in HEADLESS mode (mock raylib)"
  else:
    echo "Running in LOCAL mode (requires display)"
  
  echo ""
  echo "Found ", TestFiles.len, " test file(s)"
  echo ""
  
  for testFile in TestFiles:
    echo "Running: ", testFile, "..."
    
    let mode = if headlessMode: tmHeadless else: tmLocal
    let result = runTestWithMode(testFile, mode)
    results.add(result)
  
  printResults()
  
  # Exit with error code if any tests failed
  var anyFailed = false
  for result in results:
    if not result.success:
      anyFailed = true
      break
  
  if anyFailed:
    quit(1)
  else:
    quit(0)

when isMainModule:
  main()
