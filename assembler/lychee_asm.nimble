# Package

version       = "0.1.0"
author        = "imagineeeinc"
description   = "An assembler for the lychee 8 bit computer"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["lasm"]


# Dependencies

requires "nim >= 2.0.2"
requires "docopt >= 0.6.7"