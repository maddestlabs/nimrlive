## Minimal test for object constructor bug

type
  Point = object
    x: float32
    y: float32

proc makePoint(): Point =
  result.x = 10.0
  result.y = 20.0

proc main() =
  let point = makePoint()
  drawText("Testing", 10, 10, 20, Black)

main()
