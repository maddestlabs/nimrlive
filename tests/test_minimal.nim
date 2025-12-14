## Minimal test for headless execution

initWindow(800, 450, "Test")
setTargetFPS(60)

var i = 0
while i < 5:
  i = i + 1
  beginDrawing()
  clearBackground(RAYWHITE)
  drawText("Hello", 10, 10, 20, BLACK)
  endDrawing()

closeWindow()
