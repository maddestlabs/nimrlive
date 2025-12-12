import nimini

let sourceCode = readFile("nimr.nim")

# Try to compile it
let frontend = getNimFrontend()
let program = compileSource(sourceCode, frontend)

echo "Successfully parsed nimr.nim!"
echo "Number of statements: ", program.stmts.len
