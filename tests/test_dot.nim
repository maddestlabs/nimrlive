## Test dot notation support

type
  Point = object
    x: float32
    y: float32

proc testDot() =
  var p = {x: 10.0, y: 20.0}
  p.x = 15.0
  let xval = p.x
  let yval = p.y

testDot()
