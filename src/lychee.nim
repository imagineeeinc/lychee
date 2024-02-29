import std/[strutils]
import lycheepkg/emulator

proc chunkString(input: string): seq[string] =
  var result: seq[string] = @[]
  var i = 0
  while i < len(input):
    var chunk: string
    if i + 1 < len(input):
      chunk = input[i..i+1]
    else:
      chunk = input[i..i]
    result.add(chunk)
    i += 2
  return result

proc readRomFile(filePath: string): seq[string] =
  var
    f: File
    content: string# seq[byte]
  try:
    f = open(filePath, fmRead)
    content = f.readAll()
    f.close()
  except IOError:
    echo "Error reading the file: ", filePath
    quit(1)

  return chunkString(content.toHex)

when isMainModule:
  let romContent = readRomFile("./rom")
  echo romContent
  var emu = initLycheeEmulator()
  emu.loadRom(romContent)
  while true:
    emu.cycle()
