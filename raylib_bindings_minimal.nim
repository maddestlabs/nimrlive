## Minimal Raylib bindings for Nimini scripting
## Only includes: window management, basic 2D drawing, text, shapes
## This is the smallest build for fastest loading

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
var redColor = Red
var greenColor = Green
var blueColor = Blue
var yellowColor = Yellow

proc registerRaylibBindings*() =
  ## Register minimal raylib API functions with Nimini runtime
  ## Minimal: window, 2D shapes, text, colors only
  
  # Type conversion functions
  registerNative("int", proc(env: ref Env; args: seq[Value]): Value =
    case args[0].kind
    of vkInt: args[0]
    of vkFloat: valInt(args[0].f.int)
    of vkString: valInt(parseInt(args[0].s))
    else: valInt(0)
  )
  
  registerNative("float", proc(env: ref Env; args: seq[Value]): Value =
    case args[0].kind
    of vkInt: valFloat(args[0].i.float)
    of vkFloat: args[0]
    of vkString: valFloat(parseFloat(args[0].s))
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
      if args[0].map.hasKey("_ptr"):
        let colorPtr = cast[ptr Color](args[0].map["_ptr"].ptrVal)
        clearBackground(colorPtr[])
      else:
        let color = Color(
          r: args[0].map["r"].i.uint8,
          g: args[0].map["g"].i.uint8,
          b: args[0].map["b"].i.uint8,
          a: args[0].map["a"].i.uint8
        )
        clearBackground(color)
    else:
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
  
  # Circle drawing
  registerNative("drawCircle", proc(env: ref Env; args: seq[Value]): Value =
    var position: Vector2
    if args[0].kind == vkMap:
      position = Vector2(x: args[0].map["x"].f.float32, y: args[0].map["y"].f.float32)
    else:
      let posPtr = cast[ptr Vector2](args[0].ptrVal)
      position = posPtr[]
    
    let radius = args[1].f.float32
    
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
  
  # Rectangle drawing
  registerNative("drawRectangle", proc(env: ref Env; args: seq[Value]): Value =
    let x = args[0].i.int32
    let y = args[1].i.int32
    let width = args[2].i.int32
    let height = args[3].i.int32
    if args[4].kind == vkMap:
      if args[4].map.hasKey("_ptr"):
        let colorPtr = cast[ptr Color](args[4].map["_ptr"].ptrVal)
        drawRectangle(x, y, width, height, colorPtr[])
      else:
        let color = Color(
          r: args[4].map["r"].i.uint8,
          g: args[4].map["g"].i.uint8,
          b: args[4].map["b"].i.uint8,
          a: args[4].map["a"].i.uint8
        )
        drawRectangle(x, y, width, height, color)
    else:
      let colorPtr = cast[ptr Color](args[4].ptrVal)
      drawRectangle(x, y, width, height, colorPtr[])
    valNil()
  )
  
  # Color manipulation
  registerNative("fade", proc(env: ref Env; args: seq[Value]): Value =
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
    
    var colorMap = initTable[string, Value]()
    colorMap["r"] = valInt(fadedColor.r.int)
    colorMap["g"] = valInt(fadedColor.g.int)
    colorMap["b"] = valInt(fadedColor.b.int)
    colorMap["a"] = valInt(fadedColor.a.int)
    valMap(colorMap)
  )
  
  # Register Color constants
  template registerColor(name: string, colorVar: untyped) =
    block:
      var colorMap = initTable[string, Value]()
      colorMap["r"] = valInt(colorVar.r.int)
      colorMap["g"] = valInt(colorVar.g.int)
      colorMap["b"] = valInt(colorVar.b.int)
      colorMap["a"] = valInt(colorVar.a.int)
      colorMap["_ptr"] = valPointer(addr colorVar)
      defineVar(runtimeEnv, name, valMap(colorMap))
  
  registerColor("RayWhite", rayWhiteColor)
  registerColor("White", whiteColor)
  registerColor("Black", blackColor)
  registerColor("Gray", grayColor)
  registerColor("DarkGray", darkGrayColor)
  registerColor("Maroon", maroonColor)
  registerColor("Red", redColor)
  registerColor("Green", greenColor)
  registerColor("Blue", blueColor)
  registerColor("Yellow", yellowColor)
  
  # Vector2 type constructor
  registerNative("newVector2", proc(env: ref Env; args: seq[Value]): Value =
    var vec = Vector2(x: args[0].f.float32, y: args[1].f.float32)
    valPointer(unsafeAddr vec)
  )
  
  # Color type constructor
  registerNative("newColor", proc(env: ref Env; args: seq[Value]): Value =
    var color = Color(
      r: args[0].i.uint8,
      g: args[1].i.uint8,
      b: args[2].i.uint8,
      a: args[3].i.uint8
    )
    valPointer(unsafeAddr color)
  )
