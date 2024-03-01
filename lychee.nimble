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
# TODO: Create bindings for RSGL(https://github.com/ColleagueRiley/RSGL) and use it
# TODO: Use NiGui(https://github.com/simonkrauter/NiGui) for debugging ui maybe on a seprate thread

task debug, "Debug Compiles for 64 bit":
  exec "nimble c --cpu:amd64 --run src/lychee.nim"

task release, "Release Compiles for 64 bit":
  exec "nimble c --cpu:amd64 -d:release src/lychee.nim"