import std/[strutils, bitops]
import std/tables

proc assemble*(code: string): seq[byte] =
  let codeTree: seq[string] = code.splitLines()
  var rom: seq[byte] = newSeq[byte]()
  var jp_list: Table[int, string] = initTable[int, string]()
  var jp_labels: Table[string, int] = initTable[string, int]()
  var pc: int = 0
  for n in 0..<len(codeTree):
    let line = codeTree[n]
    let piece = line.split(" ")
    case piece[0].toLowerAscii()
    of "nop":
      rom.add(byte 0x00)
    of "halt":
      rom.add(byte 0x76)
    of "inc":
      case piece[1].toLowerAscii()
      of "(hl)":
        rom.add(byte 0x34)
      of "a":
        rom.add(byte 0x3c)
    of "ld":
      var msb: byte = byte 0x00
      let shift_size: byte = byte 0x08
      var shift: byte = byte 0x00
      var hl: bool = false
      case piece[1].toLowerAscii()
      of "b":
        msb = byte 0x40
      of "c":
        msb = byte 0x40
        shift = shift_size
      of "d":
        msb = byte 0x50
      of "e":
        msb = byte 0x50
        shift = shift_size
      of "h":
        msb = byte 0x60
      of "l":
        msb = byte 0x60
        shift = shift_size
      of "(hl)":
        msb = byte 0x70
        hl = true
      of "a":
        msb = byte 0x70
        shift = shift_size

      case piece[2].toLowerAscii()
      of "b":
        rom.add(bitor[byte](msb, 0x00+shift))
      of "c":
        rom.add(bitor[byte](msb, 0x01+shift))
      of "d":
        rom.add(bitor[byte](msb, 0x02+shift))
      of "e":
        rom.add(bitor[byte](msb, 0x03+shift))
      of "h":
        rom.add(bitor[byte](msb, 0x04+shift))
      of "l":
        rom.add(bitor[byte](msb, 0x05+shift))
      of "(hl)":
        if not hl:
          rom.add(bitor[byte](msb, 0x06+shift))
      of "a":
        rom.add(bitor[byte](msb, 0x07+shift))
      else:
        if piece[2].startsWith("$"):
          rom.add(byte 0x3e)
          rom.add(fromHex[byte](piece[2][1..^1]))
          inc pc
        else:
          rom.add(bitor[byte](msb, 0x07+shift))
    of "add":
      case piece[2].toLowerAscii()
      of "b":
        rom.add(byte 0x80)
      of "c":
        rom.add(byte 0x81)
      of "d":
        rom.add(byte 0x82)
      of "e":
        rom.add(byte 0x83)
      of "h":
        rom.add(byte 0x84)
      of "l":
        rom.add(byte 0x85)
      of "(hl)":
        rom.add(byte 0x86)
      of "a":
        rom.add(byte 0x87)
      else:
        if piece[2].startsWith("$"):
          rom.add(byte 0xc6)
          rom.add(fromHex[byte](piece[2][1..^1]))
          inc pc
        else:
          rom.add(byte 0x87)
    of "sub":
      case piece[2].toLowerAscii()
      of "b":
        rom.add(byte 0x90)
      of "c":
        rom.add(byte 0x91)
      of "d":
        rom.add(byte 0x92)
      of "e":
        rom.add(byte 0x93)
      of "h":
        rom.add(byte 0x94)
      of "l":
        rom.add(byte 0x95)
      of "(hl)":
        rom.add(byte 0x96)
      of "a":
        rom.add(byte 0x97)
      else:
        if piece[2].startsWith("$"):
          rom.add(byte 0xd6)
          rom.add(fromHex[byte](piece[2][1..^1]))
          inc pc
        else:
          rom.add(byte 0x97)
    of "jp":
      if piece[1].toLowerAscii().startsWith("$"):
        rom.add(byte 0xc3)
        rom.add(fromHex[byte](piece[1][1..^1]))
      elif piece[1].toLowerAscii().startsWith("&"):
        rom.add(byte 0xc3)
        rom.add(byte 0x00)
        rom.add(byte 0x00)
        jp_list[pc] = piece[1][1..^1]
        inc pc
        inc pc
    else:
      if piece[0].endsWith(":"):
        jp_labels[piece[0][0..^2]] = pc
        dec pc
    inc pc
  for key, val in jp_list:
    if val in jp_labels:
      let loc: int = jp_labels[val]
      if loc > 0xFF:
        rom[key+1] = byte (loc and 0xFF)
        rom[key+2] = byte ((loc shr 8) and 0xFF)
      else:
        rom[key+2] = byte loc

  result = rom
