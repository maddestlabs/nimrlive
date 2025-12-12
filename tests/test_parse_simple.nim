import nimini
import std/strutils

let sourceCode = readFile("test_simple_multiline.nim")

# Try to compile it
let frontend = getNimFrontend()
let program = compileSource(sourceCode, frontend)

echo "Successfully parsed test file!"
echo "Number of statements: ", program.stmts.len

# Try to generate code from it
let backend = newNimBackend()
let ctx = newCodegenContext(backend)
let generatedCode = genProgram(program, ctx)

echo ""
echo "Generated code:"
echo repeat("=", 50)
echo generatedCode
