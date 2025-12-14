## Simple test for headless execution
## This tests basic raylib function calls without complex types

# Initialize the window
initWindow(800, 450, "Nimini Test")
setTargetFPS(60)

# Simple variable
var counter = 0

# Main game loop
while not windowShouldClose():
  # Update
  counter = counter + 1
  
  # Draw
  beginDrawing()
  clearBackground(RAYWHITE)
  
  drawText("Hello from Nimini!", 10, 10, 20, BLACK)
  drawCircle(400, 225, 50.0, RED)
  drawFPS(10, 40)
  
  endDrawing()

closeWindow()
