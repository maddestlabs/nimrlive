# Recursive descent + Pratt parser for Nimini, the mini-Nim DSL

import std/[strutils]
import tokenizer
import ast

type
  Parser = object
    tokens: seq[Token]
    pos: int

# helpers --------------------------------------------------------------

proc typeNodeToString(t: TypeNode): string =
  ## Convert a type node to a simple string representation for parameters
  if t.isNil:
    return ""
  
  case t.kind
  of tkSimple:
    return t.typeName
  of tkPointer:
    # For parameters, we want "var T" or "ptr T" syntax
    return "ptr " & typeNodeToString(t.ptrType)
  of tkGeneric:
    result = t.genericName & "["
    for i, param in t.genericParams:
      if i > 0: result.add(", ")
      result.add(typeNodeToString(param))
    result.add("]")
  of tkProc:
    result = "proc"
  of tkObject:
    result = "object"

proc atEnd(p: Parser): bool =
  p.pos >= p.tokens.len or p.tokens[p.pos].kind == tkEOF

proc cur(p: Parser): Token =
  if p.pos < p.tokens.len: p.tokens[p.pos] else: p.tokens[^1]

proc advance(p: var Parser): Token =
  let t = p.cur()
  if not p.atEnd():
    inc p.pos
  t

proc match(p: var Parser; kinds: varargs[TokenKind]): bool =
  if p.atEnd(): return false
  for k in kinds:
    if p.cur().kind == k:
      discard p.advance()
      return true
  false

proc expect(p: var Parser; kind: TokenKind; msg: string): Token =
  if p.cur().kind != kind:
    quit "Parse Error: " & msg & " at line " & $p.cur().line
  advance(p)

# precedence -----------------------------------------------------------

proc precedence(op: string): int =
  case op
  of "or": 1
  of "and": 2
  of "==", "!=", "<", "<=", ">", ">=": 3
  of "..", "..<": 3  # Range operators at same level as comparison
  of "+", "-": 4
  of "*", "/", "%", "mod", "div": 5
  of "&": 4  # String concatenation at same level as + and -
  else: 0

# forward decl
proc parseExpr(p: var Parser; prec=0): Expr
proc parseStmt(p: var Parser): Stmt
proc parseBlock(p: var Parser): seq[Stmt]

# prefix parsing --------------------------------------------------------

proc parseType(p: var Parser): TypeNode =
  ## Parse a type annotation
  let t = p.cur()
  
  if t.kind != tkIdent:
    quit "Parse Error: Expected type name at line " & $t.line
  
  let typeName = t.lexeme
  discard p.advance()
  
  # Check for type modifiers: ptr, var, ref
  if typeName in ["ptr", "var", "ref"]:
    let innerType = parseType(p)
    return newPointerType(innerType)  # Note: treating var/ref the same as ptr for now
  
  # Check for object type
  if typeName == "object":
    # Expect newline and indent for object fields
    if p.cur().kind != tkNewline:
      # Empty object
      return newObjectType(@[])
    
    discard p.advance()
    if p.cur().kind != tkIndent:
      return newObjectType(@[])
    
    discard p.advance()
    
    # Parse object fields
    var fields: seq[ObjectField] = @[]
    while not p.atEnd() and p.cur().kind != tkDedent:
      if p.cur().kind == tkNewline:
        discard p.advance()
        continue
      
      # Parse fields (can be multiple: a, b, c: Type)
      var fieldNames: seq[string] = @[]
      fieldNames.add(expect(p, tkIdent, "Expected field name").lexeme)
      
      # Check for more field names before the type
      while p.cur().kind == tkComma:
        discard p.advance()  # consume comma
        if p.cur().kind == tkIdent:
          fieldNames.add(p.cur().lexeme)
          discard p.advance()  # consume the identifier
        else:
          quit "Parse Error: Expected field name after comma at line " & $p.cur().line
      
      discard expect(p, tkColon, "Expected ':' after field name")
      let fieldType = parseType(p)
      
      # Add all fields with the same type
      for fname in fieldNames:
        fields.add(ObjectField(name: fname, fieldType: fieldType))
      
      discard match(p, tkNewline)
    
    discard match(p, tkDedent)
    return newObjectType(fields)
  
  # Check for generic types like UncheckedArray[T] or seq[T]
  if p.cur().kind == tkLBracket:
    discard p.advance()
    var params: seq[TypeNode] = @[]
    params.add(parseType(p))
    while match(p, tkComma):
      params.add(parseType(p))
    discard expect(p, tkRBracket, "Expected ']'")
    return newGenericType(typeName, params)
  
  return newSimpleType(typeName)

proc parsePrefix(p: var Parser): Expr =
  let t = p.cur()

  case t.kind
  of tkInt:
    discard p.advance()
    newInt(parseInt(t.lexeme), t.line, t.col)

  of tkFloat:
    discard p.advance()
    newFloat(parseFloat(t.lexeme), t.line, t.col)

  of tkString:
    discard p.advance()
    newString(t.lexeme, t.line, t.col)

  of tkIdent:
    # Handle boolean literals and keyword operators
    if t.lexeme == "true":
      discard p.advance()
      return newBool(true, t.line, t.col)
    elif t.lexeme == "false":
      discard p.advance()
      return newBool(false, t.line, t.col)
    elif t.lexeme == "not":
      discard p.advance()
      let v = parseExpr(p, 100)
      return newUnaryOp("not", v, t.line, t.col)
    elif t.lexeme == "cast":
      # Parse cast[Type](expr)
      discard p.advance()
      discard expect(p, tkLBracket, "Expected '[' after cast")
      let castType = parseType(p)
      discard expect(p, tkRBracket, "Expected ']'")
      discard expect(p, tkLParen, "Expected '(' after cast type")
      let expr = parseExpr(p)
      discard expect(p, tkRParen, "Expected ')'")
      return newCast(castType, expr, t.line, t.col)
    elif t.lexeme == "addr":
      # Parse addr expr
      discard p.advance()
      let expr = parseExpr(p, 100)
      return newAddr(expr, t.line, t.col)

    discard p.advance()
    if p.cur().kind == tkLParen:
      discard p.advance()
      
      # Skip newlines and indents after opening parenthesis
      while p.cur().kind in [tkNewline, tkIndent]:
        discard p.advance()
      
      var args: seq[Expr] = @[]
      var namedArgs: seq[tuple[name: string, value: Expr]] = @[]
      
      if p.cur().kind != tkRParen:
        # Check if this is a named parameter or object constructor
        # We need to peek ahead to see if there's a colon after the first identifier
        let isNamed = p.cur().kind == tkIdent and p.pos + 1 < p.tokens.len and p.tokens[p.pos + 1].kind == tkColon
        
        if isNamed:
          # Parse named arguments
          while true:
            # Skip newlines and indents/dedents between arguments
            while p.cur().kind in [tkNewline, tkIndent, tkDedent]:
              discard p.advance()
            
            if p.cur().kind == tkRParen:
              break
            let paramName = expect(p, tkIdent, "Expected parameter name").lexeme
            discard expect(p, tkColon, "Expected ':' after parameter name")
            let paramValue = parseExpr(p)
            namedArgs.add((paramName, paramValue))
            if not match(p, tkComma):
              break
        else:
          # Parse positional arguments
          args.add(parseExpr(p))
          while match(p, tkComma):
            args.add(parseExpr(p))
      
      # Skip newlines and dedents before closing parenthesis
      while p.cur().kind in [tkNewline, tkDedent]:
        discard p.advance()
      
      discard expect(p, tkRParen, "Expected ')'")
      
      # If all arguments are named, this might be an object constructor
      if args.len == 0 and namedArgs.len > 0:
        # Check if the identifier is a type (capitalized) - treat as object constructor
        if t.lexeme.len > 0 and t.lexeme[0].isUpperAscii():
          return newObjConstr(t.lexeme, namedArgs, t.line, t.col)
      
      newCall(t.lexeme, args, namedArgs, t.line, t.col)
    else:
      newIdent(t.lexeme, t.line, t.col)

  of tkOp:
    if t.lexeme in ["-", "$"]:
      discard p.advance()
      let v = parseExpr(p, 100)
      newUnaryOp(t.lexeme, v, t.line, t.col)
    else:
      quit "Unexpected prefix operator at line " & $t.line

  of tkLParen:
    discard p.advance()
    let e = parseExpr(p)
    discard expect(p, tkRParen, "Expected ')'")
    e

  of tkLBracket:
    discard p.advance()
    var elements: seq[Expr] = @[]
    if p.cur().kind != tkRBracket:
      elements.add(parseExpr(p))
      while match(p, tkComma):
        elements.add(parseExpr(p))
    discard expect(p, tkRBracket, "Expected ']'")
    newArray(elements, t.line, t.col)

  of tkLBrace:
    # Parse map literal {key: value, key2: value2, ...}
    discard p.advance()
    var pairs: seq[tuple[key: string, value: Expr]] = @[]
    if p.cur().kind != tkRBrace:
      # Parse first key-value pair
      if p.cur().kind != tkIdent and p.cur().kind != tkString:
        quit "Map literal keys must be identifiers or strings at line " & $t.line
      let key = p.cur().lexeme
      discard p.advance()
      discard expect(p, tkColon, "Expected ':' after map key")
      let value = parseExpr(p)
      pairs.add((key, value))
      
      # Parse remaining pairs
      while match(p, tkComma):
        if p.cur().kind == tkRBrace:
          break  # Allow trailing comma
        if p.cur().kind != tkIdent and p.cur().kind != tkString:
          quit "Map literal keys must be identifiers or strings at line " & $p.cur().line
        let pairKey = p.cur().lexeme
        discard p.advance()
        discard expect(p, tkColon, "Expected ':' after map key")
        let pairValue = parseExpr(p)
        pairs.add((pairKey, pairValue))
    
    discard expect(p, tkRBrace, "Expected '}'")
    newMap(pairs, t.line, t.col)

  else:
    quit "Unexpected token in expression at line" & $t.line & ": " & $t.kind & " '" & t.lexeme & "'"

# Pratt led -------------------------------------------------------------

proc parseExpr(p: var Parser; prec=0): Expr =
  var left = parsePrefix(p)
  while true:
    let cur = p.cur()
    
    # Handle array indexing
    if cur.kind == tkLBracket:
      discard p.advance()
      let indexExpr = parseExpr(p)
      discard expect(p, tkRBracket, "Expected ']'")
      left = newIndex(left, indexExpr, cur.line, cur.col)
      continue
    
    # Check for dot notation (field access)
    if cur.kind == tkDot:
      discard p.advance()
      let fieldName = expect(p, tkIdent, "Expected field name after '.'").lexeme
      
      # Check if this is a type conversion (e.g., x.float32, y.int32)
      # Common Nim type names that can be used for conversion
      if fieldName in ["int", "int8", "int16", "int32", "int64", 
                       "uint", "uint8", "uint16", "uint32", "uint64",
                       "float", "float32", "float64", "string", "bool", "char"]:
        # This is a type conversion, convert to a function call: float32(left)
        left = newCall(fieldName, @[left], @[], cur.line, cur.col)
        continue
      
      left = newDot(left, fieldName, cur.line, cur.col)
      
      # Check if this is a method call with parentheses
      if p.cur().kind == tkLParen:
        discard p.advance()
        
        # Skip newlines and indents after opening parenthesis
        while p.cur().kind in [tkNewline, tkIndent]:
          discard p.advance()
        
        var args: seq[Expr] = @[]
        var namedArgs: seq[tuple[name: string, value: Expr]] = @[]
        
        if p.cur().kind != tkRParen:
          # Check if this is a named parameter
          let isNamed = p.cur().kind == tkIdent and p.pos + 1 < p.tokens.len and p.tokens[p.pos + 1].kind == tkColon
          
          if isNamed:
            # Parse named arguments
            while true:
              # Skip newlines and indents/dedents between arguments
              while p.cur().kind in [tkNewline, tkIndent, tkDedent]:
                discard p.advance()
              
              if p.cur().kind == tkRParen:
                break
              let paramName = expect(p, tkIdent, "Expected parameter name").lexeme
              discard expect(p, tkColon, "Expected ':' after parameter name")
              let paramValue = parseExpr(p)
              namedArgs.add((paramName, paramValue))
              if not match(p, tkComma):
                break
          else:
            # Parse positional arguments
            args.add(parseExpr(p))
            while match(p, tkComma):
              args.add(parseExpr(p))
        
        # Skip newlines and dedents before closing parenthesis
        while p.cur().kind in [tkNewline, tkDedent]:
          discard p.advance()
        
        discard expect(p, tkRParen, "Expected ')'")
        
        # Convert the dot expression to a method call
        # For ball.update(), left is now Dot(ball, "update")
        # We need to convert this to a Call
        if left.kind == ekDot:
          left = newCall(left.dotField, @[left.dotTarget] & args, namedArgs, cur.line, cur.col)
        else:
          # This shouldn't happen, but handle it gracefully
          quit "Parse Error: Method call on non-dot expression at line " & $cur.line
      
      continue
    
    var isOp = false
    var opLexeme = ""

    # Check if current token is an operator or keyword operator (and/or/mod/div)
    if cur.kind == tkOp:
      isOp = true
      opLexeme = cur.lexeme
    elif cur.kind == tkIdent and (cur.lexeme in ["and", "or", "mod", "div"]):
      isOp = true
      opLexeme = cur.lexeme

    if not isOp:
      break

    let thisPrec = precedence(opLexeme)
    if thisPrec <= prec:
      break
    let t = advance(p)    # SAFE (value is used)
    let right = parseExpr(p, thisPrec)
    left = newBinOp(opLexeme, left, right, t.line, t.col)
  left

# statements ------------------------------------------------------------

proc parseVarStmt(p: var Parser; isLet: bool; isConst: bool = false): Stmt =
  let kw = advance(p)
  
  # Check if this is a multi-line block (const/let/var followed by newline and indent)
  if p.cur().kind == tkNewline:
    discard p.advance()
    if p.cur().kind == tkIndent:
      discard p.advance()
      
      # Parse multiple declarations in the block
      var stmts: seq[Stmt] = @[]
      while not p.atEnd() and p.cur().kind != tkDedent:
        if p.cur().kind == tkNewline:
          discard p.advance()
          continue
        
        # Parse each declaration: name [: type] = value
        let nameTok = expect(p, tkIdent, "Expected identifier")
        
        var typeAnnotation: TypeNode = nil
        if p.cur().kind == tkColon:
          discard p.advance()
          typeAnnotation = parseType(p)
        
        discard expect(p, tkOp, "Expected '='")
        let val = parseExpr(p)
        
        if isConst:
          stmts.add(newConst(nameTok.lexeme, val, typeAnnotation, nameTok.line, nameTok.col))
        elif isLet:
          stmts.add(newLet(nameTok.lexeme, val, typeAnnotation, nameTok.line, nameTok.col))
        else:
          stmts.add(newVar(nameTok.lexeme, val, typeAnnotation, nameTok.line, nameTok.col))
        
        discard match(p, tkNewline)
      
      discard match(p, tkDedent)
      
      # Return a block statement containing all the declarations
      return newBlock(stmts, kw.line, kw.col)
  
  # Single-line declaration: const/let/var name [: type] = value
  let nameTok = expect(p, tkIdent, "Expected identifier")
  
  var typeAnnotation: TypeNode = nil
  if p.cur().kind == tkColon:
    discard p.advance()
    typeAnnotation = parseType(p)
  
  discard expect(p, tkOp, "Expected '='")
  let val = parseExpr(p)
  
  if isConst:
    newConst(nameTok.lexeme, val, typeAnnotation, kw.line, kw.col)
  elif isLet:
    newLet(nameTok.lexeme, val, typeAnnotation, kw.line, kw.col)
  else:
    newVar(nameTok.lexeme, val, typeAnnotation, kw.line, kw.col)

proc parseAssign(p: var Parser; targetExpr: Expr; line, col: int): Stmt =
  # targetExpr is already parsed (e.g., identifier or array index)
  let opTok = expect(p, tkOp, "Expected assignment operator")
  let op = opTok.lexeme
  
  # Check if this is a compound assignment (+=, -=, etc.)
  if op.len == 2 and op[1] == '=':
    # Compound assignment: x += y becomes x = x + y
    let baseOp = $op[0]  # Extract the base operator (+, -, *, /, %, &)
    let val = parseExpr(p)
    let expandedExpr = newBinOp(baseOp, targetExpr, val, line, col)
    return newAssignExpr(targetExpr, expandedExpr, line, col)
  else:
    # Regular assignment
    let val = parseExpr(p)
    return newAssignExpr(targetExpr, val, line, col)

proc parseIf(p: var Parser): Stmt =
  let tok = advance(p)
  let cond = parseExpr(p)
  discard expect(p, tkColon, "Expected ':'")
  discard expect(p, tkNewline, "Expected newline")
  let body = parseBlock(p)
  var node = newIf(cond, body, tok.line, tok.col)

  # Skip newlines before checking for elif
  while p.cur().kind == tkNewline:
    discard p.advance()
  
  while p.cur().kind == tkIdent and p.cur().lexeme == "elif":
    discard p.advance()
    let c = parseExpr(p)
    discard expect(p, tkColon, "Expected ':'")
    discard expect(p, tkNewline, "Expected newline")
    node.addElif(c, parseBlock(p))
    # Skip newlines before checking for next elif or else
    while p.cur().kind == tkNewline:
      discard p.advance()

  if p.cur().kind == tkIdent and p.cur().lexeme == "else":
    discard p.advance()
    discard expect(p, tkColon, "Expected ':'")
    discard expect(p, tkNewline, "Expected newline")
    node.addElse(parseBlock(p))

  node

proc parseFor(p: var Parser): Stmt =
  let tok = advance(p)
  let varTok = expect(p, tkIdent, "Expected loop variable name")

  # Expect "in" keyword
  if p.cur().kind != tkIdent or p.cur().lexeme != "in":
    quit "Parse Error: Expected 'in' after for variable at line " & $p.cur().line
  discard p.advance()

  # Parse the iterable expression (e.g., 1..5, range(1,10), someArray, etc.)
  let iterableExpr = parseExpr(p)

  discard expect(p, tkColon, "Expected ':'")
  discard expect(p, tkNewline, "Expected newline")

  let body = parseBlock(p)
  newFor(varTok.lexeme, iterableExpr, body, tok.line, tok.col)

proc parseWhile(p: var Parser): Stmt =
  let tok = advance(p)
  let cond = parseExpr(p)
  discard expect(p, tkColon, "Expected ':'")
  discard expect(p, tkNewline, "Expected newline")
  let body = parseBlock(p)
  newWhile(cond, body, tok.line, tok.col)

proc parseProc(p: var Parser): Stmt =
  let tok = advance(p)
  let nameTok = expect(p, tkIdent, "Expected proc name")
  discard expect(p, tkLParen, "Expected '('")

  var params: seq[(string,string)] = @[]
  if p.cur().kind != tkRParen:
    while true:
      # Collect parameter names (can be multiple: a, b, c: Type)
      var paramNames: seq[string] = @[]
      paramNames.add(expect(p, tkIdent, "Expected parameter name").lexeme)
      
      # Check for more parameter names before the type
      while p.cur().kind == tkComma:
        discard p.advance()  # consume comma
        # Now check if the next token is an identifier
        if p.cur().kind == tkIdent:
          paramNames.add(p.cur().lexeme)
          discard p.advance()  # consume the identifier
        else:
          quit "Parse Error: Expected parameter name after comma at line " & $p.cur().line
      
      discard expect(p, tkColon, "Expected ':'")
      let ptypeNode = parseType(p)
      let ptype = typeNodeToString(ptypeNode)
      
      # Add all parameter names with the same type
      for pname in paramNames:
        params.add((pname, ptype))
      
      if not match(p, tkComma):
        break

  discard expect(p, tkRParen, "Expected ')'")
  
  # Optional return type and pragmas
  var returnType: TypeNode = nil
  var pragmas: seq[string] = @[]
  
  # Check for return type: proc name(): Type = or proc name() =
  if p.cur().kind == tkColon:
    discard p.advance()
    # Check if this is a return type (followed by a type name, not newline)
    if p.cur().kind == tkIdent:
      returnType = parseType(p)
      # After return type, expect = sign
      discard expect(p, tkOp, "Expected '='")
      discard expect(p, tkNewline, "Expected newline")
    elif p.cur().kind == tkNewline:
      # No return type, just the colon before newline (proc body)
      discard p.advance()
    else:
      quit "Parse Error: Unexpected token after ':' at line " & $p.cur().line
  elif p.cur().kind == tkOp and p.cur().lexeme == "=":
    # proc name() = (no return type, using = instead of :)
    discard p.advance()
    discard expect(p, tkNewline, "Expected newline")
  else:
    # Optional pragmas {.cdecl.} before colon
    if p.cur().kind == tkLBrace:
      discard p.advance()
      if p.cur().kind == tkDot:
        discard p.advance()
        if p.cur().kind == tkIdent:
          pragmas.add(p.cur().lexeme)
          discard p.advance()
        if p.cur().kind == tkDot:
          discard p.advance()
        if p.cur().kind == tkRBrace:
          discard p.advance()
    
    discard expect(p, tkColon, "Expected ':'")
    discard expect(p, tkNewline, "Expected newline")

  let body = parseBlock(p)
  newProc(nameTok.lexeme, params, body, returnType, pragmas, tok.line, tok.col)

proc parseReturn(p: var Parser): Stmt =
  let tok = advance(p)
  let v = parseExpr(p)
  newReturn(v, tok.line, tok.col)

proc parseBlockStmt(p: var Parser): Stmt =
  let tok = advance(p)
  discard expect(p, tkColon, "Expected ':'")
  discard expect(p, tkNewline, "Expected newline")
  let body = parseBlock(p)
  newBlock(body, tok.line, tok.col)

proc parseStmt(p: var Parser): Stmt =
  # Skip unexpected indent/dedent tokens to make parser more robust
  while p.cur().kind == tkIndent or p.cur().kind == tkDedent:
    discard p.advance()
    if p.atEnd():
      quit "Unexpected end of input"
  
  let t = p.cur()

  if t.kind == tkIdent:
    case t.lexeme
    of "var": return parseVarStmt(p, false, false)
    of "let": return parseVarStmt(p, true, false)
    of "const": return parseVarStmt(p, false, true)
    of "defer":
      discard p.advance()
      discard expect(p, tkColon, "Expected ':' after defer")
      let deferredStmt = parseStmt(p)
      return newDefer(deferredStmt, t.line, t.col)
    of "type":
      discard p.advance()
      
      # Check if this is a multi-line block (type followed by newline and indent)
      if p.cur().kind == tkNewline:
        discard p.advance()
        if p.cur().kind == tkIndent:
          discard p.advance()
          
          # Parse multiple type declarations in the block
          var stmts: seq[Stmt] = @[]
          while not p.atEnd() and p.cur().kind != tkDedent:
            if p.cur().kind == tkNewline:
              discard p.advance()
              continue
            
            # Parse each declaration: Name = TypeValue
            let typeName = expect(p, tkIdent, "Expected type name").lexeme
            discard expect(p, tkOp, "Expected '='")
            let typeValue = parseType(p)
            stmts.add(newType(typeName, typeValue, t.line, t.col))
            
            discard match(p, tkNewline)
          
          discard match(p, tkDedent)
          
          # Return a block statement containing all the type declarations
          return newBlock(stmts, t.line, t.col)
      
      # Single-line declaration: type Name = value
      let typeName = expect(p, tkIdent, "Expected type name").lexeme
      discard expect(p, tkOp, "Expected '='")
      let typeValue = parseType(p)
      return newType(typeName, typeValue, t.line, t.col)
    of "if": return parseIf(p)
    of "for": return parseFor(p)
    of "while": return parseWhile(p)
    of "proc": return parseProc(p)
    of "return": return parseReturn(p)
    of "block": return parseBlockStmt(p)
    else:
      # Parse as expression first (could be assignment target or just expression)
      let e = parseExpr(p)
      # Check if this is an assignment (=, +=, -=, *=, /=, %=, &=)
      if p.cur().kind == tkOp and (p.cur().lexeme == "=" or (p.cur().lexeme.len == 2 and p.cur().lexeme[1] == '=')):
        return parseAssign(p, e, t.line, t.col)
      return newExprStmt(e, t.line, t.col)

  let e = parseExpr(p)
  newExprStmt(e, t.line, t.col)

# blocks ---------------------------------------------------------------

proc parseBlock(p: var Parser): seq[Stmt] =
  result = @[]
  if not match(p, tkIndent):
    quit "Expected indent block at line " & $p.cur().line

  while not p.atEnd():
    if match(p, tkDedent):
      break
    if p.cur().kind == tkNewline:
      discard p.advance()
      continue
    result.add(parseStmt(p))
    discard match(p, tkNewline)

# root ---------------------------------------------------------------

proc parseDsl*(tokens: seq[Token]): Program =
  var p = Parser(tokens: tokens, pos: 0)
  var stmts: seq[Stmt] = @[]

  while not p.atEnd():
    if p.cur().kind == tkNewline:
      discard p.advance()
      continue
    # Skip unexpected indent/dedent tokens at top level
    if p.cur().kind == tkIndent or p.cur().kind == tkDedent:
      discard p.advance()
      continue
    stmts.add(parseStmt(p))
    discard match(p, tkNewline)

  Program(stmts: stmts)
