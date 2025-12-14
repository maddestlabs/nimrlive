# Clean, strict, Nim compatible runtime for Nimini

import std/[tables, math, strutils]
import ast

# ------------------------------------------------------------------------------
# Value Types
# ------------------------------------------------------------------------------

type
  ValueKind* = enum
    vkNil,
    vkInt,
    vkFloat,
    vkBool,
    vkString,
    vkFunction,
    vkMap,
    vkArray,
    vkPointer     # Raw pointer value


  NativeFunc* = proc(env: ref Env; args: seq[Value]): Value

  FunctionVal* = ref object
    isNative*: bool
    native*: NativeFunc
    params*: seq[string]
    stmts*: seq[Stmt]
    returnType*: TypeNode  # For implicit result variable

  Value* = ref object
    kind*: ValueKind
    i*: int
    f*: float
    b*: bool
    s*: string
    fnVal*: FunctionVal
    map*: Table[string, Value]
    arr*: seq[Value]
    ptrVal*: pointer  # For pointer values

  Env* = object
    vars*: Table[string, Value]
    parent*: ref Env
    deferStack*: seq[Stmt]  # Stack of deferred statements

proc `$`*(v: Value): string =
  case v.kind
  of vkNil: result = "nil"
  of vkInt: result = $v.i
  of vkFloat: result = $v.f
  of vkBool: result = $v.b
  of vkString: result = v.s
  of vkFunction: result = "<function>"
  of vkArray:
    result = "["
    for i, elem in v.arr:
      if i > 0: result.add(", ")
      result.add($elem)
    result.add("]")
  of vkMap:
    result = "{"
    var first = true
    for k, val in v.map:
      if not first: result.add(", ")
      result.add(k & ": " & $val)
      first = false
    result.add("}")
  of vkPointer: result = "<pointer>"

# ------------------------------------------------------------------------------
# Value Constructors
# ------------------------------------------------------------------------------

proc valNil*(): Value =
  Value(kind: vkNil, i: 0, f: 0.0, b: false, s: "", fnVal: nil)

# Keep i and f in sync so z.f works even for integer results
proc valInt*(i: int): Value =
  Value(kind: vkInt, i: i, f: float(i), b: false, s: "", fnVal: nil)

proc valFloat*(f: float): Value =
  Value(kind: vkFloat, i: int(f), f: f, b: false, s: "", fnVal: nil)

proc valBool*(b: bool): Value =
  Value(
    kind: vkBool,
    i: (if b: 1 else: 0),
    f: (if b: 1.0 else: 0.0),
    b: b,
    s: "",
    fnVal: nil
  )

proc valString*(s: string): Value =
  Value(
    kind: vkString,
    i: 0,
    f: 0.0,
    b: (s.len > 0),
    s: s,
    fnVal: nil
  )

proc valPointer*(p: pointer): Value =
  Value(kind: vkPointer, i: 0, f: 0.0, b: (p != nil), s: "", fnVal: nil, ptrVal: p)

proc valNativeFunc*(fn: NativeFunc): Value =
  Value(kind: vkFunction, fnVal: FunctionVal(
    isNative: true,
    native: fn,
    params: @[],
    stmts: @[]
  ))

proc valUserFunc*(params: seq[string]; stmts: seq[Stmt]; returnType: TypeNode = nil): Value =
  Value(kind: vkFunction, fnVal: FunctionVal(
    isNative: false,
    native: nil,
    params: params,
    stmts: stmts,
    returnType: returnType
  ))

proc valMap*(initialMap: Table[string, Value] = initTable[string, Value]()): Value =
  Value(kind: vkMap, map: initialMap)

# Alias for compatibility with plugin code
proc newMapValue*(): Value =
  valMap()

# Map access operators
proc `[]`*(v: Value; key: string): Value =
  if v.kind != vkMap:
    quit "Runtime Error: Cannot index non-map value"
  if key in v.map:
    return v.map[key]
  return valNil()

proc `[]=`*(v: Value; key: string; val: Value) =
  if v.kind != vkMap:
    quit "Runtime Error: Cannot set key on non-map value"
  v.map[key] = val

proc getByKey*(v: Value; key: string): Value =
  ## Get a value from a map by key. Returns valNil() if key not found.
  if v.kind != vkMap:
    quit "Runtime Error: getByKey called on non-map value"
  if key in v.map:
    return v.map[key]
  return valNil()

# Array access operators
proc `[]`*(v: Value; index: int): Value =
  if v.kind != vkArray:
    quit "Runtime Error: Cannot index non-array value"
  if index < 0 or index >= v.arr.len:
    quit "Runtime Error: Array index out of bounds: " & $index & " (length: " & $v.arr.len & ")"
  return v.arr[index]

proc `[]=`*(v: Value; index: int; val: Value) =
  if v.kind != vkArray:
    quit "Runtime Error: Cannot set index on non-array value"
  if index < 0 or index >= v.arr.len:
    quit "Runtime Error: Array index out of bounds: " & $index & " (length: " & $v.arr.len & ")"
  v.arr[index] = val

# ------------------------------------------------------------------------------
# Environment
# ------------------------------------------------------------------------------

proc newEnv*(parent: ref Env = nil): ref Env =
  new(result)
  result.vars = initTable[string, Value]()
  result.parent = parent

proc defineVar*(env: ref Env; name: string; v: Value) =
  env.vars[name] = v

proc setVar*(env: ref Env; name: string; v: Value) =
  var e = env
  while e != nil:
    if name in e.vars:
      e.vars[name] = v
      return
    e = e.parent
  env.vars[name] = v

proc getVar*(env: ref Env; name: string): Value =
  var e = env
  while e != nil:
    if name in e.vars:
      # echo "Found variable '", name, "' with kind: ", e.vars[name].kind
      return e.vars[name]
    e = e.parent
  quit "Runtime Error: Undefined variable '" & name & "'"

# ------------------------------------------------------------------------------
# Conversion Helpers
# ------------------------------------------------------------------------------

proc toBool(v: Value): bool =
  case v.kind
  of vkNil: false
  of vkBool: v.b
  of vkInt: v.i != 0
  of vkFloat: v.f != 0.0
  of vkString: v.s.len > 0
  of vkFunction: true
  of vkMap: v.map.len > 0
  of vkArray: v.arr.len > 0
  of vkPointer: v.ptrVal != nil

proc toFloat(v: Value): float =
  case v.kind
  of vkInt: float(v.i)
  of vkFloat: v.f
  of vkString:
    try:
      parseFloat(v.s)
    except:
      quit "Runtime Error: Cannot convert string '" & v.s & "' to float"
  of vkArray:
    quit "Runtime Error: Cannot convert array to float"
  else:
    quit "Runtime Error: Expected numeric value, got " & $v.kind & " (value: " & $v & ")"

proc toInt*(v: Value): int =
  case v.kind
  of vkInt: v.i
  of vkFloat: int(v.f)
  of vkString:
    try:
      parseInt(v.s)
    except:
      quit "Runtime Error: Cannot convert string '" & v.s & "' to int"
  of vkArray:
    quit "Runtime Error: Cannot convert array to int"
  else:
    quit "Runtime Error: Expected numeric value, got " & $v.kind & " (value: " & $v & ")"

# ------------------------------------------------------------------------------
# Return Propagation
# ------------------------------------------------------------------------------

type
  ExecResult = object
    hasReturn: bool
    value: Value

proc noReturn(): ExecResult =
  ExecResult(hasReturn: false, value: valNil())

proc withReturn(v: Value): ExecResult =
  ExecResult(hasReturn: true, value: v)

# ------------------------------------------------------------------------------
# Expression Evaluation
# ------------------------------------------------------------------------------

proc evalExpr(e: Expr; env: ref Env): Value
proc execStmt*(s: Stmt; env: ref Env): ExecResult
proc execBlock(sts: seq[Stmt]; env: ref Env): ExecResult

# Function call --------------------------------------------------------

proc evalCall(name: string; args: seq[Expr]; namedArgs: seq[tuple[name: string, value: Expr]]; env: ref Env): Value =
  # Check if this is a type constructor (capitalized name) with only named args
  # If so, create an object (map) with those fields
  if name.len > 0 and name[0].isUpperAscii and args.len == 0 and namedArgs.len > 0:
    echo "Creating type constructor for: ", name, " with ", namedArgs.len, " named args"
    var objMap = initTable[string, Value]()
    for namedArg in namedArgs:
      objMap[namedArg.name] = evalExpr(namedArg.value, env)
      echo "  Field '", namedArg.name, "' = ", objMap[namedArg.name].kind
    echo "Created map with ", objMap.len, " fields"
    return valMap(objMap)
  
  let val = getVar(env, name)
  if val.kind != vkFunction:
    quit "Runtime Error: '" & name & "' is not callable"

  let fn = val.fnVal

  if fn.isNative:
    var argVals: seq[Value] = @[]
    for a in args:
      argVals.add evalExpr(a, env)
    # Named args for native functions - just append them in order for now
    for namedArg in namedArgs:
      argVals.add evalExpr(namedArg.value, env)
    return fn.native(env, argVals)
  else:
    # User-defined function
    let callEnv = newEnv(env)
    var argVals: seq[Value] = @[]
    for a in args:
      argVals.add evalExpr(a, env)

    # Bind positional parameters
    for i, pname in fn.params:
      if i < argVals.len:
        defineVar(callEnv, pname, argVals[i])
      else:
        defineVar(callEnv, pname, valNil())
    
    # Bind named parameters - these override positional ones if present
    for namedArg in namedArgs:
      let paramValue = evalExpr(namedArg.value, env)
      defineVar(callEnv, namedArg.name, paramValue)

    # Initialize implicit 'result' variable if function has a return type
    if fn.returnType != nil:
      # Initialize result based on the return type
      var initialValue = valNil()
      if fn.returnType.kind == tkSimple:
        # Initialize with default values for common types
        case fn.returnType.typeName
        of "int", "int8", "int16", "int32", "int64",
           "uint", "uint8", "uint16", "uint32", "uint64":
          initialValue = valInt(0)
        of "float", "float32", "float64":
          initialValue = valFloat(0.0)
        of "bool":
          initialValue = valBool(false)
        of "string":
          initialValue = valString("")
        else:
          # For custom types (like Ball, Color), initialize as empty map
          initialValue = valMap()
      elif fn.returnType.kind == tkObject:
        # Object types initialize as empty maps
        initialValue = valMap()
      
      defineVar(callEnv, "result", initialValue)

    # Execute body, propagate return
    var returnValue = valNil()
    var hasReturnValue = false
    for i, st in fn.stmts:
      let res = execStmt(st, callEnv)
      if res.hasReturn:
        returnValue = res.value
        hasReturnValue = true
        break
      
      # If this is the last statement in a function with a return type,
      # and it's an expression statement, assign its value to 'result'
      if i == fn.stmts.len - 1 and fn.returnType != nil and st.kind == skExpr:
        let exprValue = evalExpr(st.expr, callEnv)
        setVar(callEnv, "result", exprValue)
    
    # Execute deferred statements in reverse order (LIFO)
    for i in countdown(callEnv.deferStack.len - 1, 0):
      discard execStmt(callEnv.deferStack[i], callEnv)
    
    if hasReturnValue:
      return returnValue
    
    # If no explicit return, return the 'result' variable if it exists
    if fn.returnType != nil:
      return getVar(callEnv, "result")
    
    valNil()

# Main evalExpr --------------------------------------------------------

proc evalExpr(e: Expr; env: ref Env): Value =
  case e.kind
  of ekInt:    valInt(e.intVal)
  of ekFloat:  valFloat(e.floatVal)
  of ekString: valString(e.strVal)
  of ekBool:   valBool(e.boolVal)
  of ekIdent:  getVar(env, e.ident)

  of ekUnaryOp:
    let v = evalExpr(e.unaryExpr, env)
    case e.unaryOp
    of "-":
      if v.kind == vkFloat:
        valFloat(-v.f)
      else:
        valInt(-toInt(v))
    of "not":
      valBool(not toBool(v))
    of "$":
      valString($v)
    else:
      quit "Unknown unary op: " & e.unaryOp

  of ekBinOp:
    # Handle logical operators with short-circuit evaluation
    if e.op == "and":
      let l = evalExpr(e.left, env)
      if not toBool(l):
        return valBool(false)
      let r = evalExpr(e.right, env)
      return valBool(toBool(r))
    elif e.op == "or":
      let l = evalExpr(e.left, env)
      if toBool(l):
        return valBool(true)
      let r = evalExpr(e.right, env)
      return valBool(toBool(r))

    # Evaluate both sides for other operators
    let l = evalExpr(e.left, env)
    let r = evalExpr(e.right, env)

    case e.op
    of "&":
      # String concatenation - handle first to avoid converting to float
      valString($l & $r)
    of "+":
      # Handle different types for + operator
      if l.kind == vkArray and r.kind == vkArray:
        # Array concatenation
        var result = l.arr
        result.add(r.arr)
        Value(kind: vkArray, arr: result)
      elif l.kind == vkInt and r.kind == vkInt:
        valInt(l.i + r.i)
      else:
        # Numeric addition
        valFloat(toFloat(l) + toFloat(r))
    of "-", "*", "/", "%", "mod", "div", "==", "!=", "<", "<=", ">", ">=":
      # Arithmetic and comparison operators need numeric conversion
      let bothInts = (l.kind == vkInt and r.kind == vkInt)
      let lf = toFloat(l)
      let rf = toFloat(r)

      case e.op
      of "-":
        if bothInts: valInt(l.i - r.i)
        else: valFloat(lf - rf)
      of "*":
        if bothInts: valInt(l.i * r.i)
        else: valFloat(lf * rf)
      of "/", "div":
        if bothInts: valInt(l.i div r.i)
        else: valFloat(lf / rf)
      of "%", "mod":
        if bothInts: valInt(l.i mod r.i)
        else: valFloat(lf mod rf)
      of "==": valBool(lf == rf)
      of "!=": valBool(lf != rf)
      of "<":  valBool(lf <  rf)
      of "<=": valBool(lf <= rf)
      of ">":  valBool(lf >  rf)
      of ">=": valBool(lf >= rf)
      else: valNil()  # Should never reach here
    
    # Range operators - return a special range value for for-loop iteration
    of "..", "..<":
      # For runtime, we'll create a custom value type that represents a range
      # For simplicity, we'll store it as a map with "start" and "end" keys
      let rangeMap = initTable[string, Value]()
      var rangeVal = valMap()
      rangeVal.map["start"] = valInt(toInt(l))
      if e.op == "..":
        rangeVal.map["end"] = valInt(toInt(r))  # Inclusive
      else:  # ..<
        rangeVal.map["end"] = valInt(toInt(r) - 1)  # Exclusive, so subtract 1
      rangeVal.map["is_range"] = valBool(true)
      rangeVal
    
    else:
      quit "Unknown binary op: " & e.op

  of ekCall:
    evalCall(e.funcName, e.args, e.namedArgs, env)

  of ekArray:
    var elements: seq[Value] = @[]
    for elem in e.elements:
      elements.add(evalExpr(elem, env))
    Value(kind: vkArray, arr: elements)

  of ekMap:
    var mapTable = initTable[string, Value]()
    for pair in e.mapPairs:
      mapTable[pair.key] = evalExpr(pair.value, env)
    Value(kind: vkMap, map: mapTable)

  of ekIndex:
    let target = evalExpr(e.indexTarget, env)
    let index = evalExpr(e.indexExpr, env)
    
    case target.kind
    of vkArray:
      let idx = toInt(index)
      if idx < 0 or idx >= target.arr.len:
        quit "Index out of bounds: " & $idx & " (array length: " & $target.arr.len & ")"
      target.arr[idx]
    of vkMap:
      if index.kind != vkString:
        quit "Map keys must be strings, got: " & $index.kind
      if index.s in target.map:
        target.map[index.s]
      else:
        valNil()  # Return nil for missing keys
    of vkString:
      let idx = toInt(index)
      if idx < 0 or idx >= target.s.len:
        quit "String index out of bounds: " & $idx & " (string length: " & $target.s.len & ")"
      valString($target.s[idx])
    else:
      quit "Cannot index value of type: " & $target.kind

  of ekCast:
    # Type casting - for runtime, we'll try to convert the value
    # In a full implementation, this would do proper type checking
    let val = evalExpr(e.castExpr, env)
    # For now, just return the value as-is
    # A real implementation would check the target type and convert
    val

  of ekAddr:
    # Address-of operator - for runtime simulation, return the value
    # In a real implementation with memory management, this would return a pointer
    evalExpr(e.addrExpr, env)

  of ekDeref:
    # Dereference operator - for runtime simulation, just evaluate
    # In a real implementation, this would dereference a pointer
    evalExpr(e.derefExpr, env)

  of ekDot:
    # Dot notation for field access
    # For runtime, we treat objects as maps
    let target = evalExpr(e.dotTarget, env)
    if target.kind == vkMap:
      if e.dotField in target.map:
        return target.map[e.dotField]
      else:
        quit "Runtime Error: Field '" & e.dotField & "' not found in object"
    else:
      # Provide more context about what went wrong
      var targetDesc = ""
      if e.dotTarget.kind == ekIdent:
        targetDesc = " (accessing '" & e.dotTarget.ident & "." & e.dotField & "')"
      quit "Runtime Error: Dot notation only works on objects, got " & $target.kind & targetDesc

  of ekObjConstr:
    # Object constructor: TypeName(field1: val1, field2: val2)
    # For runtime, we represent objects as maps with their fields
    var objMap = initTable[string, Value]()
    for field in e.objFields:
      objMap[field.name] = evalExpr(field.value, env)
    Value(kind: vkMap, map: objMap)

# ------------------------------------------------------------------------------
# Statement Execution
# ------------------------------------------------------------------------------

proc execBlock(sts: seq[Stmt]; env: ref Env): ExecResult =
  var res = noReturn()
  for st in sts:
    res = execStmt(st, env)
    if res.hasReturn:
      return res
  res

proc execStmt*(s: Stmt; env: ref Env): ExecResult =
  case s.kind
  of skExpr:
    discard evalExpr(s.expr, env)
    noReturn()

  of skVar:
    defineVar(env, s.varName, evalExpr(s.varValue, env))
    noReturn()

  of skLet:
    defineVar(env, s.letName, evalExpr(s.letValue, env))
    noReturn()

  of skConst:
    # Const is treated like let at runtime
    defineVar(env, s.constName, evalExpr(s.constValue, env))
    noReturn()

  of skAssign:
    # Handle assignment to variable or indexed expression
    let value = evalExpr(s.assignValue, env)
    case s.assignTarget.kind
    of ekIdent:
      # Simple variable assignment
      echo "ASSIGN: Setting variable '", s.assignTarget.ident, "' to ", value.kind
      setVar(env, s.assignTarget.ident, value)
    of ekIndex:
      # Array/map index assignment
      let target = evalExpr(s.assignTarget.indexTarget, env)
      let indexVal = evalExpr(s.assignTarget.indexExpr, env)
      case target.kind
      of vkArray:
        let idx = toInt(indexVal)
        if idx < 0 or idx >= target.arr.len:
          quit "Index out of bounds: " & $idx
        target.arr[idx] = value
      of vkMap:
        if indexVal.kind != vkString:
          quit "Map keys must be strings"
        target.map[indexVal.s] = value
      else:
        quit "Cannot index into non-array/map value"
    of ekDot:
      # Dot notation assignment (object field)
      # Handle nested dot notation: ball.position.x = value
      # We need to check if dotTarget is also a dot expression (nested access)
      if s.assignTarget.dotTarget.kind == ekDot:
        # Nested dot: e.g., ball.position.x
        # Evaluate the parent (ball.position) and modify it in place
        let parent = evalExpr(s.assignTarget.dotTarget.dotTarget, env)
        if parent.kind != vkMap:
          quit "Runtime Error: Cannot access field on non-object"
        
        let middleFieldName = s.assignTarget.dotTarget.dotField
        if middleFieldName notin parent.map:
          # Create the intermediate object if it doesn't exist
          parent.map[middleFieldName] = valMap()
        
        let middleObj = parent.map[middleFieldName]
        if middleObj.kind != vkMap:
          quit "Runtime Error: Intermediate field is not an object"
        
        # Now set the final field
        middleObj.map[s.assignTarget.dotField] = value
      else:
        # Simple dot: e.g., ball.position
        let target = evalExpr(s.assignTarget.dotTarget, env)
        if target.kind == vkMap:
          target.map[s.assignTarget.dotField] = value
        else:
          quit "Runtime Error: Dot notation assignment only works on objects"
    else:
      quit "Invalid assignment target"
    noReturn()

  of skIf:
    # Each branch gets its own scope
    if toBool(evalExpr(s.ifBranch.cond, env)):
      let childEnv = newEnv(env)
      return execBlock(s.ifBranch.stmts, childEnv)

    for br in s.elifBranches:
      if toBool(evalExpr(br.cond, env)):
        let childEnv = newEnv(env)
        return execBlock(br.stmts, childEnv)

    if s.elseStmts.len > 0:
      let childEnv = newEnv(env)
      return execBlock(s.elseStmts, childEnv)

    noReturn()

  of skFor:
    # Evaluate the iterable expression
    let iterableVal = evalExpr(s.forIterable, env)
    
    # Handle different iterable types
    if iterableVal.kind == vkMap and "is_range" in iterableVal.map and iterableVal.map["is_range"].b:
      # Range value created by .. or ..< operators
      let startVal = toInt(iterableVal.map["start"])
      let endVal = toInt(iterableVal.map["end"])
      for i in startVal .. endVal:
        let loopEnv = newEnv(env)
        defineVar(loopEnv, s.forVar, valInt(i))
        let res = execBlock(s.forBody, loopEnv)
        if res.hasReturn:
          return res
    elif iterableVal.kind == vkInt:
      # Simple case: iterate from 0 to value-1 (backward compatibility)
      for i in 0 ..< iterableVal.i:
        let loopEnv = newEnv(env)
        defineVar(loopEnv, s.forVar, valInt(i))
        let res = execBlock(s.forBody, loopEnv)
        if res.hasReturn:
          return res
    else:
      # For other cases, we could extend this to handle custom iterables
      quit "Runtime Error: Cannot iterate over value in for loop (not a range or integer)"

    noReturn()

  of skWhile:
    # Execute while loop
    while true:
      # Evaluate condition
      let condVal = evalExpr(s.whileCond, env)
      if not toBool(condVal):
        break
      
      # Execute body
      let res = execBlock(s.whileBody, env)
      
      # If body returns, propagate the return
      if res.hasReturn:
        return res
    
    noReturn()

  of skProc:
    var pnames: seq[string] = @[]
    for (n, _) in s.params:
      pnames.add(n)
    defineVar(env, s.procName, valUserFunc(pnames, s.body, s.procReturnType))
    noReturn()

  of skReturn:
    withReturn(evalExpr(s.returnVal, env))

  of skBlock:
    # Blocks in Nim don't create new variable scopes
    # They're mainly for control flow (break statements)
    return execBlock(s.stmts, env)

  of skDefer:
    # Defer statement - push to defer stack for execution at scope exit
    env.deferStack.add(s.deferStmt)
    noReturn()

  of skType:
    # Type definition - for runtime, we just store it as metadata
    # In a real implementation, this would register the type in a type system
    noReturn()

# ------------------------------------------------------------------------------
# Program Execution
# ------------------------------------------------------------------------------

var runtimeEnv*: ref Env

# ------------------------------------------------------------------------------
# Native Function Registration / Globals
# ------------------------------------------------------------------------------

proc registerNative*(name: string; fn: NativeFunc) =
  defineVar(runtimeEnv, name, valNativeFunc(fn))

proc initRuntime*() =
  runtimeEnv = newEnv(nil)
  # Note: Plugin system is initialized on-demand in plugin.nim
  # Note: Standard library functions are registered separately via initStdlib()
  
  # Register built-in print/echo functions
  registerNative("echo", proc(env: ref Env; args: seq[Value]): Value =
    for i, arg in args:
      if i > 0: stdout.write(" ")
      stdout.write($arg)
    stdout.write("\n")
    valNil()
  )
  registerNative("print", proc(env: ref Env; args: seq[Value]): Value =
    for i, arg in args:
      if i > 0: stdout.write(" ")
      stdout.write($arg)
    stdout.write("\n")
    valNil()
  )

proc execProgram*(prog: Program; env: ref Env) =
  discard execBlock(prog.stmts, env)

proc setGlobal*(name: string; v: Value) =
  defineVar(runtimeEnv, name, v)

proc setGlobalInt*(name: string; i: int) =
  setGlobal(name, valInt(i))

proc setGlobalFloat*(name: string; f: float) =
  setGlobal(name, valFloat(f))

proc setGlobalBool*(name: string; b: bool) =
  setGlobal(name, valBool(b))

proc setGlobalString*(name: string; s: string) =
  setGlobal(name, valString(s))
