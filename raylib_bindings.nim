## Raylib bindings for Nimini scripting
## This module exposes all raylib functions used in nimr.nim to the Nimini runtime
## without modifying core Nimini source code.

import nimini
import raylib
import std/[strutils, tables]

# Color constants that persist (not destroyed after registration)
var rayWhiteColor = RayWhite
var whiteColor = White
var blackColor = Black
var grayColor = Gray
var darkGrayColor = DarkGray
var maroonColor = Maroon

proc registerRaylibBindings*() =
  ## Register all naylib/raylib API functions with Nimini runtime
  ## This makes raylib functions callable from loaded scripts
  
  # Type conversion functions
  registerNative("int", proc(env: ref Env; args: seq[Value]): Value =
    case args[0].kind
    of vkInt: args[0]
    of vkFloat: valInt(args[0].f.int)
    of vkString: valInt(parseInt(args[0].s))
    else: valInt(0)
  )
  
  registerNative("int8", proc(env: ref Env; args: seq[Value]): Value =
    case args[0].kind
    of vkInt: valInt(args[0].i.int8.int)
    of vkFloat: valInt(args[0].f.int8.int)
    else: valInt(0)
  )
  
  registerNative("int16", proc(env: ref Env; args: seq[Value]): Value =
    case args[0].kind
    of vkInt: valInt(args[0].i.int16.int)
    of vkFloat: valInt(args[0].f.int16.int)
    else: valInt(0)
  )
  
  registerNative("int32", proc(env: ref Env; args: seq[Value]): Value =
    case args[0].kind
    of vkInt: valInt(args[0].i.int32.int)
    of vkFloat: valInt(args[0].f.int32.int)
    else: valInt(0)
  )
  
  registerNative("int64", proc(env: ref Env; args: seq[Value]): Value =
    case args[0].kind
    of vkInt: valInt(args[0].i.int64.int)
    of vkFloat: valInt(args[0].f.int64.int)
    else: valInt(0)
  )
  
  registerNative("uint", proc(env: ref Env; args: seq[Value]): Value =
    case args[0].kind
    of vkInt: valInt(args[0].i.uint.int)
    of vkFloat: valInt(args[0].f.uint.int)
    else: valInt(0)
  )
  
  registerNative("uint8", proc(env: ref Env; args: seq[Value]): Value =
    case args[0].kind
    of vkInt: valInt(args[0].i.uint8.int)
    of vkFloat: valInt(args[0].f.uint8.int)
    else: valInt(0)
  )
  
  registerNative("uint16", proc(env: ref Env; args: seq[Value]): Value =
    case args[0].kind
    of vkInt: valInt(args[0].i.uint16.int)
    of vkFloat: valInt(args[0].f.uint16.int)
    else: valInt(0)
  )
  
  registerNative("uint32", proc(env: ref Env; args: seq[Value]): Value =
    case args[0].kind
    of vkInt: valInt(args[0].i.uint32.int)
    of vkFloat: valInt(args[0].f.uint32.int)
    else: valInt(0)
  )
  
  registerNative("uint64", proc(env: ref Env; args: seq[Value]): Value =
    case args[0].kind
    of vkInt: valInt(args[0].i.uint64.int)
    of vkFloat: valInt(args[0].f.uint64.int)
    else: valInt(0)
  )
  
  registerNative("float", proc(env: ref Env; args: seq[Value]): Value =
    case args[0].kind
    of vkInt: valFloat(args[0].i.float)
    of vkFloat: args[0]
    of vkString: valFloat(parseFloat(args[0].s))
    else: valFloat(0.0)
  )
  
  registerNative("float32", proc(env: ref Env; args: seq[Value]): Value =
    case args[0].kind
    of vkInt: valFloat(args[0].i.float32.float)
    of vkFloat: valFloat(args[0].f.float32.float)
    else: valFloat(0.0)
  )
  
  registerNative("float64", proc(env: ref Env; args: seq[Value]): Value =
    case args[0].kind
    of vkInt: valFloat(args[0].i.float64)
    of vkFloat: args[0]
    else: valFloat(0.0)
  )
  
  registerNative("string", proc(env: ref Env; args: seq[Value]): Value =
    case args[0].kind
    of vkInt: valString($args[0].i)
    of vkFloat: valString($args[0].f)
    of vkString: args[0]
    of vkBool: valString($args[0].b)
    else: valString("")
  )
  
  registerNative("bool", proc(env: ref Env; args: seq[Value]): Value =
    case args[0].kind
    of vkInt: valBool(args[0].i != 0)
    of vkFloat: valBool(args[0].f != 0.0)
    of vkString: valBool(args[0].s.len > 0)
    of vkBool: args[0]
    else: valBool(false)
  )
  
  # Window management
  registerNative("initWindow", proc(env: ref Env; args: seq[Value]): Value =
    let width = args[0].i.int32
    let height = args[1].i.int32
    let title = args[2].s
    initWindow(width, height, title)
    valNil()
  )
  
  registerNative("closeWindow", proc(env: ref Env; args: seq[Value]): Value =
    closeWindow()
    valNil()
  )
  
  registerNative("windowShouldClose", proc(env: ref Env; args: seq[Value]): Value =
    valBool(windowShouldClose())
  )
  
  registerNative("setTargetFPS", proc(env: ref Env; args: seq[Value]): Value =
    setTargetFPS(args[0].i.int32)
    valNil()
  )
  
  # Drawing functions
  registerNative("beginDrawing", proc(env: ref Env; args: seq[Value]): Value =
    beginDrawing()
    valNil()
  )
  
  registerNative("endDrawing", proc(env: ref Env; args: seq[Value]): Value =
    endDrawing()
    valNil()
  )
  
  registerNative("clearBackground", proc(env: ref Env; args: seq[Value]): Value =
    if args[0].kind == vkMap:
      # Color is a map with r, g, b, a fields
      if args[0].map.hasKey("_ptr"):
        # Use the stored pointer if available
        let colorPtr = cast[ptr Color](args[0].map["_ptr"].ptrVal)
        clearBackground(colorPtr[])
      else:
        # Construct from map fields
        let color = Color(
          r: args[0].map["r"].i.uint8,
          g: args[0].map["g"].i.uint8,
          b: args[0].map["b"].i.uint8,
          a: args[0].map["a"].i.uint8
        )
        clearBackground(color)
    else:
      # Legacy: pointer value
      let colorPtr = cast[ptr Color](args[0].ptrVal)
      clearBackground(colorPtr[])
    valNil()
  )
  
  # Text drawing
  registerNative("drawText", proc(env: ref Env; args: seq[Value]): Value =
    let text = args[0].s
    let posX = args[1].i.int32
    let posY = args[2].i.int32
    let fontSize = args[3].i.int32
    if args[4].kind == vkMap:
      if args[4].map.hasKey("_ptr"):
        let colorPtr = cast[ptr Color](args[4].map["_ptr"].ptrVal)
        drawText(text, posX, posY, fontSize, colorPtr[])
      else:
        let color = Color(
          r: args[4].map["r"].i.uint8,
          g: args[4].map["g"].i.uint8,
          b: args[4].map["b"].i.uint8,
          a: args[4].map["a"].i.uint8
        )
        drawText(text, posX, posY, fontSize, color)
    else:
      let colorPtr = cast[ptr Color](args[4].ptrVal)
      drawText(text, posX, posY, fontSize, colorPtr[])
    valNil()
  )
  
  registerNative("drawFPS", proc(env: ref Env; args: seq[Value]): Value =
    let posX = args[0].i.int32
    let posY = args[1].i.int32
    drawFPS(posX, posY)
    valNil()
  )
  
  # Circle drawing (needed for nimr.nim)
  registerNative("drawCircle", proc(env: ref Env; args: seq[Value]): Value =
    # drawCircle(position: Vector2, radius: float32, color: Color)
    # Handle Vector2 as map or pointer
    var position: Vector2
    if args[0].kind == vkMap:
      position = Vector2(x: args[0].map["x"].f.float32, y: args[0].map["y"].f.float32)
    else:
      let posPtr = cast[ptr Vector2](args[0].ptrVal)
      position = posPtr[]
    
    let radius = args[1].f.float32
    
    # Handle Color as map or pointer
    if args[2].kind == vkMap:
      if args[2].map.hasKey("_ptr"):
        let colorPtr = cast[ptr Color](args[2].map["_ptr"].ptrVal)
        drawCircle(position, radius, colorPtr[])
      else:
        let color = Color(
          r: args[2].map["r"].i.uint8,
          g: args[2].map["g"].i.uint8,
          b: args[2].map["b"].i.uint8,
          a: args[2].map["a"].i.uint8
        )
        drawCircle(position, radius, color)
    else:
      let colorPtr = cast[ptr Color](args[2].ptrVal)
      drawCircle(position, radius, colorPtr[])
    valNil()
  )
  
  registerNative("drawCircleLines", proc(env: ref Env; args: seq[Value]): Value =
    # drawCircleLines(centerX: int32, centerY: int32, radius: float32, color: Color)
    let centerX = args[0].i.int32
    let centerY = args[1].i.int32
    let radius = args[2].f.float32
    if args[3].kind == vkMap:
      if args[3].map.hasKey("_ptr"):
        let colorPtr = cast[ptr Color](args[3].map["_ptr"].ptrVal)
        drawCircleLines(centerX, centerY, radius, colorPtr[])
      else:
        let color = Color(
          r: args[3].map["r"].i.uint8,
          g: args[3].map["g"].i.uint8,
          b: args[3].map["b"].i.uint8,
          a: args[3].map["a"].i.uint8
        )
        drawCircleLines(centerX, centerY, radius, color)
    else:
      let colorPtr = cast[ptr Color](args[3].ptrVal)
      drawCircleLines(centerX, centerY, radius, colorPtr[])
    valNil()
  )
  
  # Color manipulation
  registerNative("fade", proc(env: ref Env; args: seq[Value]): Value =
    # fade(color: Color, alpha: float32): Color
    let alpha = args[1].f.float32
    var fadedColor: Color
    if args[0].kind == vkMap:
      if args[0].map.hasKey("_ptr"):
        let colorPtr = cast[ptr Color](args[0].map["_ptr"].ptrVal)
        fadedColor = fade(colorPtr[], alpha)
      else:
        let color = Color(
          r: args[0].map["r"].i.uint8,
          g: args[0].map["g"].i.uint8,
          b: args[0].map["b"].i.uint8,
          a: args[0].map["a"].i.uint8
        )
        fadedColor = fade(color, alpha)
    else:
      let colorPtr = cast[ptr Color](args[0].ptrVal)
      fadedColor = fade(colorPtr[], alpha)
    
    # Return as a map
    var colorMap = initTable[string, Value]()
    colorMap["r"] = valInt(fadedColor.r.int)
    colorMap["g"] = valInt(fadedColor.g.int)
    colorMap["b"] = valInt(fadedColor.b.int)
    colorMap["a"] = valInt(fadedColor.a.int)
    valMap(colorMap)
  )
  
  # Register Color constants as actual color values (not functions)
  # These are constants, so they should be values, not functions that return values
  block:
    var colorMap = initTable[string, Value]()
    colorMap["r"] = valInt(rayWhiteColor.r.int)
    colorMap["g"] = valInt(rayWhiteColor.g.int)
    colorMap["b"] = valInt(rayWhiteColor.b.int)
    colorMap["a"] = valInt(rayWhiteColor.a.int)
    colorMap["_ptr"] = valPointer(addr rayWhiteColor)
    defineVar(runtimeEnv, "RayWhite", valMap(colorMap))
  
  block:
    var colorMap = initTable[string, Value]()
    colorMap["r"] = valInt(whiteColor.r.int)
    colorMap["g"] = valInt(whiteColor.g.int)
    colorMap["b"] = valInt(whiteColor.b.int)
    colorMap["a"] = valInt(whiteColor.a.int)
    colorMap["_ptr"] = valPointer(addr whiteColor)
    defineVar(runtimeEnv, "White", valMap(colorMap))
  
  block:
    var colorMap = initTable[string, Value]()
    colorMap["r"] = valInt(blackColor.r.int)
    colorMap["g"] = valInt(blackColor.g.int)
    colorMap["b"] = valInt(blackColor.b.int)
    colorMap["a"] = valInt(blackColor.a.int)
    colorMap["_ptr"] = valPointer(addr blackColor)
    defineVar(runtimeEnv, "Black", valMap(colorMap))
  
  block:
    var colorMap = initTable[string, Value]()
    colorMap["r"] = valInt(grayColor.r.int)
    colorMap["g"] = valInt(grayColor.g.int)
    colorMap["b"] = valInt(grayColor.b.int)
    colorMap["a"] = valInt(grayColor.a.int)
    colorMap["_ptr"] = valPointer(addr grayColor)
    defineVar(runtimeEnv, "Gray", valMap(colorMap))
  
  block:
    var colorMap = initTable[string, Value]()
    colorMap["r"] = valInt(darkGrayColor.r.int)
    colorMap["g"] = valInt(darkGrayColor.g.int)
    colorMap["b"] = valInt(darkGrayColor.b.int)
    colorMap["a"] = valInt(darkGrayColor.a.int)
    colorMap["_ptr"] = valPointer(addr darkGrayColor)
    defineVar(runtimeEnv, "DarkGray", valMap(colorMap))
  
  block:
    var colorMap = initTable[string, Value]()
    colorMap["r"] = valInt(maroonColor.r.int)
    colorMap["g"] = valInt(maroonColor.g.int)
    colorMap["b"] = valInt(maroonColor.b.int)
    colorMap["a"] = valInt(maroonColor.a.int)
    colorMap["_ptr"] = valPointer(addr maroonColor)
    defineVar(runtimeEnv, "Maroon", valMap(colorMap))
  
  # Vector2 type constructor
  # Note: This requires more sophisticated type support in Nimini
  # For now, we'll need scripts to use a helper function
  registerNative("newVector2", proc(env: ref Env; args: seq[Value]): Value =
    # newVector2(x: float32, y: float32): ptr Vector2
    var vec = Vector2(x: args[0].f.float32, y: args[1].f.float32)
    # Warning: This creates a temporary - for production use, we'd need proper memory management
    valPointer(unsafeAddr vec)
  )
  
  # Color type constructor
  registerNative("newColor", proc(env: ref Env; args: seq[Value]): Value =
    # newColor(r: uint8, g: uint8, b: uint8, a: uint8): ptr Color
    var color = Color(
      r: args[0].i.uint8,
      g: args[1].i.uint8,
      b: args[2].i.uint8,
      a: args[3].i.uint8
    )
    valPointer(unsafeAddr color)
  )
  
  # Register Color as a helper that returns a map-based color for object constructor usage
  # This shouldn't be needed since object constructors create maps directly,
  # but we add it for safety
  # registerNative("Color", proc(env: ref Env; args: seq[Value]): Value =
  #   var colorMap = initTable[string, Value]()
  #   colorMap["r"] = args[0]
  #   colorMap["g"] = args[1]
  #   colorMap["b"] = args[2]
  #   colorMap["a"] = args[3]
  #   valMap(colorMap)
  # )
