## Simple animated raylib example in Nim using naylib

import raylib

const
  ScreenWidth = 800
  ScreenHeight = 450

type
  Ball = object
    position: Vector2
    velocity: Vector2
    radius: float32
    color: Color

proc initBall(): Ball =
  result.position = Vector2(x: ScreenWidth.float32 / 2.0, y: ScreenHeight.float32 / 2.0)
  result.velocity = Vector2(x: 5.0, y: 4.0)
  result.radius = 40.0
  result.color = Maroon

proc changeColor(color: Color, rDelta, gDelta, bDelta: int): Color =
  ## Create a new color by adding deltas to each RGB component
  Color(
    r: uint8((int(color.r) + rDelta) mod 256),
    g: uint8((int(color.g) + gDelta) mod 256),
    b: uint8((int(color.b) + bDelta) mod 256),
    a: 255
  )

proc update(ball: var Ball) =
  # Update ball position
  ball.position.x += ball.velocity.x
  ball.position.y += ball.velocity.y

  # Bounce off walls
  if ball.position.x >= (ScreenWidth.float32 - ball.radius) or ball.position.x <= ball.radius:
    ball.velocity.x *= -1.0
    ball.color = changeColor(ball.color, 40, 60, 80)

  if ball.position.y >= (ScreenHeight.float32 - ball.radius) or ball.position.y <= ball.radius:
    ball.velocity.y *= -1.0
    ball.color = changeColor(ball.color, 50, 30, 70)

proc draw(ball: Ball) =
  drawCircle(ball.position, ball.radius, ball.color)
  drawCircleLines(ball.position.x.int32, ball.position.y.int32, ball.radius, fade(White, 0.6))

proc main() =
  initWindow(ScreenWidth, ScreenHeight, "nimr - Raylib + Nim + WASM")
  setTargetFPS(60)

  var ball = initBall()

  while not windowShouldClose():
    ball.update()

    beginDrawing()
    clearBackground(RayWhite)
    
    ball.draw()
    
    drawText("Bouncing Ball Demo", 10, 10, 20, DarkGray)
    drawText("Made with Nim + Raylib (naylib)", 10, 35, 16, Gray)
    drawFPS(ScreenWidth - 100, 10)
    
    endDrawing()

  closeWindow()

when isMainModule:
  main()
