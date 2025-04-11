import std/[strutils, monotimes, times]
import illwill
import lycheepkg/emulator

import sokol/log as slog
import sokol/gfx as sg
import sokol/app as sapp
import sokol/debugtext as sdtx
import sokol/glue as sglue

# sokol setup
const passAction = PassAction(
    colors: [
      ColorAttachmentAction(loadAction: loadActionClear, clearValue: (0, 0.125, 0.25, 1))
    ]
  )

proc init() {.cdecl.} =
  sg.setup(sg.Desc(
    environment: sglue.environment(),
    logger: sg.Logger(fn: slog.fn),
  ))

  # setup sokol/debugtext
  sdtx.setup(sdtx.Desc(
    fonts: [
      sdtx.fontC64()
    ],
    logger: sdtx.Logger(fn: slog.fn),
  ))

proc cleanup() {.cdecl.} =
  sdtx.shutdown()
  sg.shutdown()
  illwillDeinit()
  showCursor()
  quit(0)

proc printFont(fontIndex: int32, title: cstring, r: uint8, g: uint8, b: uint8) =
  sdtx.font(fontIndex)
  sdtx.color3b(r, g, b)
  sdtx.puts(title)
  for c in 32..<256:
    sdtx.putc(c.char)
    if 0 == ((c + 1) and 63):
      sdtx.crlf()
  sdtx.crlf()

# illwill setup
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

# lychee setup
proc chunkString(input: string): seq[string] =
  result = @[]
  var i = 0
  while i < len(input):
    var chunk: string
    if i + 1 < len(input):
      chunk = input[i..i+1]
    else:
      chunk = input[i..i]
    result.add(chunk)
    i += 2

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

# lychee clock
var debug: bool = false
let sixtyhz = initDuration(microseconds=int(1000000/60))
let debugclockhz = initDuration(seconds=1)
let defaultclockhz = initDuration(microseconds=int(1000000/500))
var clockhz = defaultclockhz
var sixtylast = getMonoTime()
var clocklast = getMonoTime()

proc lycheeUpdate(emu: LycheeEmulator) =
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

# main
when isMainModule:
  # lychee loading
  let romContent = readRomFile("./rom")
  var emu = initLycheeEmulator()
  emu.loadRom(romContent)

  # update func
  proc frame() {.cdecl.} =
    # set virtual canvas size to half display size so that
    # glyphs are 16x16 display pixels
    sdtx.canvas(sapp.widthf()*0.5, sapp.heightf()*0.5)
    sdtx.origin(0, 2)
    sdtx.home()
    print_font(0, "C64:\n",         0x79, 0x86, 0xcb)

    sg.beginPass(Pass(action: passAction, swapchain: sglue.swapchain()))
    sdtx.draw()
    sg.endPass()
    sg.commit()

    lychee_update(emu)

  sapp.run(sapp.Desc(
    initCb: init,
    frameCb: frame,
    cleanupCb: cleanup,
    enable_dragndrop: true,
    fullscreen: false,
    width: int32 16*64,
    height: int32 16*45,
    windowTitle: "lychee",
    icon: IconDesc(sokol_default: true),
    logger: sapp.Logger(fn: slog.fn),
  ))