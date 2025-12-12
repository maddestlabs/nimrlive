## Test multi-line const and type support in Nimini

const
  Width = 800
  Height = 450
  Title = "Test Window"

type
  Point = object
    x: float32
    y: float32
  
  Ball = object
    position: Point
    velocity: Point
    radius: float32

proc main() =
  echo "Constants:"
  echo "  Width: ", Width
  echo "  Height: ", Height  
  echo "  Title: ", Title
  echo ""
  echo "Types defined: Point, Ball"

when isMainModule:
  main()
