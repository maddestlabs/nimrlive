import nimini
import std/strutils

let sourceCode = readFile("test_dot.nim")

let frontend = getNimFrontend()
let program = compileSource(sourceCode, frontend)

echo "Successfully parsed dot notation test!"

# Generate code
let backend = newNimBackend()
let ctx = newCodegenContext(backend)
let generatedCode = genProgram(program, ctx)

echo ""
echo "Generated code:"
echo repeat("=", 50)
echo generatedCode
