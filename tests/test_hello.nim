# Simple test script for nimrlive

initWindow(800, 600, "Hello from Command Line!")
setTargetFPS(60)

while not windowShouldClose():
  beginDrawing()
  clearBackground(RayWhite)
  drawText("Hello from nimrlive CLI!", 200, 250, 40, DarkGray)
  drawText("Press ESC to close", 280, 300, 20, Gray)
  drawFPS(10, 10)
  endDrawing()

closeWindow()
