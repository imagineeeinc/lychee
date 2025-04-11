import std/[strutils, monotimes, times]
import illwill
import lycheepkg/emulator

proc exitProc() {.noconv.} =
  illwillDeinit()
  showCursor()
  quit(0)

illwillInit(fullscreen=true)
setControlCHook(exitProc)
hideCursor()

var tb = newTerminalBuffer(terminalWidth(), terminalHeight())

tb.setForegroundColor(fgBlack, true)
tb.drawRect(0, 0, 11, 9)
tb.drawHorizLine(2, 9, 7, doubleStyle=true)
tb.drawRect(12, 0, 12+11, 9)
#tb.drawHorizLine(2, 38, 3, doubleStyle=true)

#tb.write(2, 2, "Press ", fgYellow, "ESC", fgWhite,
#               " or ", fgYellow, "Q", fgWhite, " to quit")


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
  var emu = initLycheeEmulator()
  emu.loadRom(romContent)

  var debug: bool = false
  let sixtyhz = initDuration(microseconds=int(1000000/60))
  let debugclockhz = initDuration(seconds=1)
  let defaultclockhz = initDuration(microseconds=int(1000000/500))
  var clockhz = defaultclockhz
  var sixtylast = getMonoTime()
  var clocklast = getMonoTime()

  while true:
    let cur = getMonoTime()
    if cur - sixtylast > sixtyhz:
      # timers
      sixtylast = getMonoTime()
    if cur - clocklast > clockhz:
      discard emu.cycle()
      clocklast = getMonoTime()

    var key = getKey()
    case key
    of Key.None: discard
    of Key.Escape, Key.Q: exitProc()
    of Key.D:
      if debug == false:
        debug = true
        clockhz = debugclockhz
        tb.write(13, 1, resetStyle, "Debug: ", fgGreen, "On ")
      else:
        debug = false
        clockhz = defaultclockhz
        tb.write(13, 1, resetStyle, "Debug: ", fgRed, "Off")
    else:
      discard
    tb.write(2, 1, resetStyle, "A: ", fgGreen, emu.r.a.toHex)
    tb.write(2, 2, resetStyle, "BC: ", fgGreen, emu.r.b.toHex, emu.r.c.toHex)
    tb.write(2, 3, resetStyle, "DE: ", fgGreen, emu.r.d.toHex, emu.r.e.toHex)
    tb.write(2, 4, resetStyle, "HL: ", fgGreen, emu.r.h.toHex, emu.r.l.toHex)
    tb.write(2, 5, resetStyle, "PC: ", fgGreen, toHex(emu.r.pc, 4))
    tb.write(2, 6, resetStyle, "SP: ", fgGreen, toHex(emu.r.sp, 4))
    tb.write(2, 8, resetStyle, "MBR: ", fgGreen, emu.program[emu.r.pc])

    tb.display()
