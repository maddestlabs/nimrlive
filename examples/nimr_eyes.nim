# import raylib, std/[math, lenientops]

const
  ScreenWidth = 800
  ScreenHeight = 450

proc main =
  # Initialization
  initWindow(ScreenWidth, ScreenHeight, "raylib [shapes] example - following eyes")
  setTargetFPS(60)

  var screenW = float(getScreenWidth())
  var screenH = float(getScreenHeight())

  var
    scleraLeftPosition = Vector2(
      x: screenW/2.0 - 100.0, 
      y: screenH/2.0
    )
    scleraRightPosition = Vector2(
      x: screenW/2.0 + 100.0, 
      y: screenH/2.0
    )
    scleraRadius = 80.0

    irisLeftPosition = Vector2(
      x: screenW/2.0 - 100.0, 
      y: screenH/2.0
    )
    irisRightPosition = Vector2(
      x: screenW/2.0 + 100.0, 
      y: screenH/2.0
    )
    irisRadius = 24.0

  var
    angle = 0.0
    dx = 0.0
    dy = 0.0
    dxx = 0.0
    dyy = 0.0

  # Main game loop
  while not windowShouldClose():
    # Update
    irisLeftPosition = getMousePosition()
    irisRightPosition = getMousePosition()

    # Check not inside the left eye sclera
    if not checkCollisionPointCircle(irisLeftPosition, scleraLeftPosition, scleraRadius - irisRadius):
      dx = irisLeftPosition.x - scleraLeftPosition.x
      dy = irisLeftPosition.y - scleraLeftPosition.y

      angle = arctan2(dy, dx)

      dxx = (scleraRadius - irisRadius) * cos(angle)
      dyy = (scleraRadius - irisRadius) * sin(angle)

      irisLeftPosition.x = scleraLeftPosition.x + dxx
      irisLeftPosition.y = scleraLeftPosition.y + dyy

    # Check not inside the right eye sclera
    if not checkCollisionPointCircle(irisRightPosition, scleraRightPosition, scleraRadius - irisRadius):
      dx = irisRightPosition.x - scleraRightPosition.x
      dy = irisRightPosition.y - scleraRightPosition.y

      angle = arctan2(dy, dx)

      dxx = (scleraRadius - irisRadius) * cos(angle)
      dyy = (scleraRadius - irisRadius) * sin(angle)

      irisRightPosition.x = scleraRightPosition.x + dxx
      irisRightPosition.y = scleraRightPosition.y + dyy

    # Draw
    beginDrawing()
    clearBackground(RayWhite)

    drawCircle(scleraLeftPosition, scleraRadius, LightGray)
    drawCircle(irisLeftPosition, irisRadius, Brown)
    drawCircle(irisLeftPosition, 10, Black)

    drawCircle(scleraRightPosition, scleraRadius, LightGray)
    drawCircle(irisRightPosition, irisRadius, DarkGreen)
    drawCircle(irisRightPosition, 10, Black)

    drawFPS(10, 10)
    endDrawing()
  
  closeWindow()

main()