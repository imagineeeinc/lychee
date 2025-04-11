import std/[strutils, bitops]

proc assemble*(code: string): seq[byte] =
  let codeTree: seq[string] = code.splitLines()
  var rom: seq[byte] = newSeq[byte]()
  for line in codeTree:
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
      var shift: byte = byte 0x00
      var hl: bool = false
      case piece[1].toLowerAscii()
      of "b":
        msb = byte 0x40
      of "c":
        msb = byte 0x40
        shift = 0x07
      of "d":
        msb = byte 0x50
      of "e":
        msb = byte 0x50
        shift = 0x07
      of "h":
        msb = byte 0x60
      of "l":
        msb = byte 0x60
        shift = 0x07
      of "(hl)":
        msb = byte 0x70
        hl = true
      of "a":
        msb = byte 0x70
        shift = 0x07
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
        else:
          rom.add(bitor[byte](msb, 0x07+shift))

    else:
      discard
  for i in rom:
    echo i.toHex

  result = rom
