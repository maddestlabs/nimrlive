## Test multi-line const and type support

const
  Width = 800
  Height = 450

type
  Point = object
    x: float32
    y: float32

proc greet(name: string): string =
  return "Hello"

proc main() =
  let w = Width
  let h = Height
  let msg = greet("World")

main()
