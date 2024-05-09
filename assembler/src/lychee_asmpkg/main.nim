import std/strutils

proc assemble*(code: string): seq[string] =
  let codeTree: seq[string] = code.splitLines()
  for line in codeTree:
    let piece = line.split(" ")

  result = @[]