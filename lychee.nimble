# Package

version       = "0.1.0"
author        = "imagineeeinc"
description   = "An operand emulator"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["lychee"]


# Dependencies

requires "nim >= 2.0.2"
requires "illwill >= 0.3.2"
requires "https://github.com/floooh/sokol-nim.git"
requires "docopt >= 0.6.7"

task debug, "Debug Compiles":
  exec "nimble c --run src/lychee.nim"

task release, "Release Compiles":
  exec "nimble c -d:release src/lychee.nim"