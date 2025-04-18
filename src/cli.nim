let doc = """
Lychee Emulator

Usage:
  lychee <rom>
  lychee <rom> -d
  lychee <rom> (--paused | -p)

Options:
  -h --help             Show this screen.
  --version             Show version.
  -d                    Launch in debug mode, which runs at 1Hz.
  --paused -p           Launch paused, good for steping instruction by instruction.
"""

import std/[strutils, monotimes, times]

import illwill
import docopt

import lycheepkg/emulator
import fileLoading

const platform = "CLI"
const NimblePkgVersion {.strdefine.} = ""

let args = docopt(doc, version = "Lychee Emulator $1 $2" % [platform, NimblePkgVersion])

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
tb.drawHorizLine(14, 21, 3, doubleStyle=true)

# lychee setup
const color_table = [
  [0x00, 0x00, 0x00],
  [0x1D, 0x2B, 0x53],
  [0x7E, 0x25, 0x53],
  [0x00, 0x87, 0x51],
  [0xAB, 0x52, 0x36],
  [0x5F, 0x57, 0x4F],
  [0xC2, 0xC3, 0xC7],
  [0xFF, 0xF1, 0xE8],
  [0xFF, 0x00, 0x4D],
  [0xFF, 0xA3, 0x00],
  [0xFF, 0xEC, 0x27],
  [0x00, 0xE4, 0x36],
  [0x29, 0xAD, 0xFF],
  [0x83, 0x76, 0x9C],
  [0xFF, 0x77, 0xA8],
  [0xFF, 0xCC, 0xAA]
]

# lychee clock
var debug: bool = if args["-d"]: true else: false
let sixtyhz = initDuration(milliseconds=int(1000/60))
let debugclockhz = initDuration(seconds=1)
let defaultclockhz = initDuration(microseconds=int(1000000/100000))
var clockhz = if args["-d"]: debugclockhz else: defaultclockhz
var sixtylast = getMonoTime()
var clocklast = getMonoTime()
var paused: bool = if args["--paused"]: true else: false

proc lycheeDraw(emu: LycheeEmulator) =
  for y in 0..44:
    for x in 0..63:
      let pos = (x + y*63)*2
      var c: int = fromHex[int](emu.ram[pos+mem_offset].toHex)
      let color = emu.ram[pos+mem_offset+1]
      # Most significant nibble
      let msn = color shr 4
      # Least significant nibble
      let lsn = color and 0x0f
      let foreground = color_table[lsn]
      if c >= 32:
        tb.write(x, y, resetStyle, $c.char)

proc runUpdate(emu: LycheeEmulator) =
  let cur = getMonoTime()
  if cur - sixtylast > sixtyhz:
    # timers
    if emu.r.timer != 0:
      dec emu.r.timer
    sixtylast = getMonoTime()
  if cur - clocklast > clockhz or (debug and paused):
    let exit_code = emu.cycle()
    if exit_code == 1:
      # TODO: Make a clean exit
      exitProc()
    clocklast = getMonoTime()

proc lycheeUpdate(emu: LycheeEmulator) =
  var key = getKey()
  case key
  of Key.None: discard
  of Key.Escape, Key.Q: exitProc()
  of Key.D:
    if debug == false:
      debug = true
      clockhz = debugclockhz
      # tb.write(13, 1, resetStyle, "Debug: ", fgGreen, "On ")
    else:
      debug = false
      clockhz = defaultclockhz
      # tb.write(13, 1, resetStyle, "Debug: ", fgRed, "Off")
  of Key.Space:
    paused = not paused
    # tb.write(13, 2, resetStyle, "Paused:", if paused: fgGreen else: fgRed, if paused: "On " else: "Off")
  of Key.N:
    if paused:
      runUpdate(emu)
  of Key.CtrlB:
    writeFile($args["<rom>"] & "-" & "dump.bin", emu.mem_dump())

  else:
    discard
  #[ tb.write(2, 1, resetStyle, "A: ", fgGreen, emu.r.a.toHex)
  tb.write(2, 2, resetStyle, "BC: ", fgGreen, emu.r.b.toHex, emu.r.c.toHex)
  tb.write(2, 3, resetStyle, "DE: ", fgGreen, emu.r.d.toHex, emu.r.e.toHex)
  tb.write(2, 4, resetStyle, "HL: ", fgGreen, emu.r.h.toHex, emu.r.l.toHex)
  tb.write(2, 5, resetStyle, "PC: ", fgGreen, toHex(emu.r.pc, 4))
  tb.write(2, 6, resetStyle, "SP: ", fgGreen, toHex(emu.r.sp, 4))
  tb.write(2, 8, resetStyle, "MBR: ", fgGreen, emu.ram[emu.r.pc].toHex)
  tb.write(13, 4, resetStyle, "Z: ", fgGreen, if emu.f.z: "1" else: "0")
  tb.write(13, 5, resetStyle, "C: ", fgGreen, toHex(emu.f.c, 2))
  tb.write(13, 6, resetStyle, "Timer: ", fgGreen, toHex(emu.r.timer, 2))

  tb.display() ]#

# main
when isMainModule:
  # lychee loading
  var romContent: seq[string]
  if args["<rom>"]:
    romContent = readRomFile($args["<rom>"])
  else:
    echo "Provide rom file"
    quit(1)
  var emu = initLycheeEmulator()
  emu.loadRom(romContent)
  if terminalWidth() < 64 or terminalHeight() < 45:
    echo "Your terminal is $1x$2" % [$terminalWidth(), $terminalHeight()]
    echo "Terminal too small, need at least 64x45"
    quit(1)
  else:
    var displaylast = getMonoTime()
    while true:
      if getMonoTime() - displaylast > sixtyhz:
        displaylast = getMonoTime()
        tb.clear()
        lycheeDraw(emu)
        tb.display()
        lycheeUpdate(emu)
      if paused == false:
        runUpdate(emu)