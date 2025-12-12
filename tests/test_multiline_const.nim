## Test multi-line const support in Nimini

const
  Width = 800
  Height = 450
  Title = "Test"

proc main() =
  echo "Width: ", Width
  echo "Height: ", Height  
  echo "Title: ", Title

when isMainModule:
  main()
