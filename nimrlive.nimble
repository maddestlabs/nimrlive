# Package

version       = "0.1.0"
author        = "Maddest Labs"
description   = "Live Nim scripting with raylib using Nimini"
license       = "MIT"
bin           = @["nimrlive"]
srcDir        = "."

# Dependencies

requires "nim >= 2.0.0"
requires "naylib >= 25.10"
# nimini is now vendored in this repo - see nimini/ directory
