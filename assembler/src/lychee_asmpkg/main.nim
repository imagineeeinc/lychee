import std/[strutils, bitops]
import std/tables

proc extractByte(code: string): byte =
  return fromHex[byte](code[1..^1])

proc extractByteFromDec(code: string): byte =
  return byte parseInt code[1..^1]

proc extract2Bytes(code: string): array[2, byte] =
  return [fromHex[byte](code[1..2]), fromHex[byte](code[3..^1])]

proc assemble*(code: string): seq[byte] =
  let codeTree: seq[string] = code.splitLines()
  var rom: seq[byte] = newSeq[byte]()
  var jp_list: Table[int, string] = initTable[int, string]()
  var jp_labels: Table[string, int] = initTable[string, int]()
  var pc: int = 0
  for n in 0..<len(codeTree):
    let line = codeTree[n]
    let piece = line.split(" ")

    # Comment
    if piece[0].toLowerAscii().startsWith("#"):
      continue

    case piece[0].toLowerAscii()
    of "nop":
      rom.add(byte 0x00)

    of "halt":
      rom.add(byte 0x76)

    of "inc":
      case piece[1].toLowerAscii()
      # inc (hl)
      of "(hl)":
        rom.add(byte 0x34)
      # inc a
      of "a":
        rom.add(byte 0x3c)

    of "dec":
      case piece[1].toLowerAscii()
      # dec (hl)
      of "(hl)":
        rom.add(byte 0x35)
      # dec a
      of "a":
        rom.add(byte 0x3d)
    of "ld":
      var msb: byte = byte 0x00
      let shift_size: byte = byte 0x08
      var shift: byte = byte 0x00
      var hl: bool = false
      var direct: bool = false
      var direct_value: array[2, byte]
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
      of "timer":
        msb = byte 0xe0
      else:
        if piece[1].startsWith("$"):
          direct = true
          direct_value = extract2Bytes(piece[1])

      case piece[2].toLowerAscii()
      of "b":
        msb.setMask(0x00+shift)
        rom.add(msb)
      of "c":
        msb.setMask(0x01+shift)
        rom.add(msb)
      of "d":
        msb.setMask(0x02+shift)
        rom.add(msb)
      of "e":
        msb.setMask(0x03+shift)
        rom.add(msb)
      of "h":
        msb.setMask(0x04+shift)
        rom.add(msb)
      of "l":
        msb.setMask(0x05+shift)
        rom.add(msb)
      of "(hl)":
        if not hl:
          msb.setMask(0x06+shift)
        rom.add(msb)
      of "a":
        if msb == byte 0xe0:
          rom.add(byte 0xe3)
        elif direct == true:
          rom.add(0xea)
          rom.add(direct_value[0])
          rom.add(direct_value[1])
          inc pc
          inc pc
        else:
          msb.setMask(0x07+shift)
          rom.add(msb)
      of "timer":
        if msb == byte 0x70:
          rom.add(byte 0xe4)
      else:
        if piece[2].startsWith("$"):
          rom.add(byte 0x3e)
          rom.add(extractByte(piece[2]))
          inc pc
        elif piece[2].startsWith("."):
          rom.add(byte 0x3e)
          rom.add(extractByteFromDec(piece[2]))
          inc pc
        else:
          msb.setMask(0x07+shift)
          rom.add(msb)

    of "add":
      if piece[1].toLowerAscii() != "hl":
        # 8 Bit addition
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
            rom.add(extractByte(piece[2]))
            inc pc
          elif piece[2].startsWith("."):
            rom.add(byte 0xc6)
            rom.add(extractByteFromDec(piece[2]))
            inc pc
          else:
            rom.add(byte 0x87)
      # 16 Bit addition
      elif piece[1].toLowerAscii() == "hl":
        if piece[2].toLowerAscii() == "bc":
          rom.add(byte 0x09)
        elif piece[2].toLowerAscii() == "de":
          rom.add(byte 0x19)
        elif piece[2].toLowerAscii() == "hl":
          rom.add(byte 0x29)

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
          rom.add(extractByte(piece[2]))
          inc pc
        elif piece[2].startsWith("."):
          rom.add(byte 0xd6)
          rom.add(extractByteFromDec(piece[2]))
          inc pc
        else:
          rom.add(byte 0x97)

    of "and":
      case piece[2].toLowerAscii()
      of "b":
        rom.add(byte 0xa0)
      of "c":
        rom.add(byte 0xa1)
      of "d":
        rom.add(byte 0xa2)
      of "e":
        rom.add(byte 0xa3)
      of "h":
        rom.add(byte 0xa4)
      of "l":
        rom.add(byte 0xa5)
      of "(hl)":
        rom.add(byte 0xa6)
      of "a":
        rom.add(byte 0xa7)
      else:
        if piece[2].startsWith("$"):
          rom.add(byte 0xe6)
          rom.add(extractByte(piece[2]))
          inc pc
        elif piece[2].startsWith("."):
          rom.add(byte 0xe6)
          rom.add(extractByteFromDec(piece[2]))
          inc pc
        else:
          rom.add(byte 0xa7)

    of "xor":
      case piece[2].toLowerAscii()
      of "b":
        rom.add(byte 0xa8)
      of "c":
        rom.add(byte 0xa9)
      of "d":
        rom.add(byte 0xaa)
      of "e":
        rom.add(byte 0xab)
      of "h":
        rom.add(byte 0xac)
      of "l":
        rom.add(byte 0xad)
      of "(hl)":
        rom.add(byte 0xae)
      of "a":
        rom.add(byte 0xaf)
      else:
        if piece[2].startsWith("$"):
          rom.add(byte 0xee)
          rom.add(extractByte(piece[2]))
          inc pc
        elif piece[2].startsWith("."):
          rom.add(byte 0xee)
          rom.add(extractByteFromDec(piece[2]))
          inc pc
        else:
          rom.add(byte 0xaf)

    of "or":
      case piece[2].toLowerAscii()
      of "b":
        rom.add(byte 0xb0)
      of "c":
        rom.add(byte 0xb1)
      of "d":
        rom.add(byte 0xb2)
      of "e":
        rom.add(byte 0xb3)
      of "h":
        rom.add(byte 0xb4)
      of "l":
        rom.add(byte 0xb5)
      of "(hl)":
        rom.add(byte 0xb6)
      of "a":
        rom.add(byte 0xb7)
      else:
        if piece[2].startsWith("$"):
          rom.add(byte 0xf6)
          rom.add(extractByte(piece[2]))
          inc pc
        elif piece[2].startsWith("."):
          rom.add(byte 0xf6)
          rom.add(extractByteFromDec(piece[2]))
          inc pc
        else:
          rom.add(byte 0xb7)

    # Compare
    of "cp":
      case piece[2].toLowerAscii()
      of "b":
        rom.add(byte 0xb8)
      of "c":
        rom.add(byte 0xb9)
      of "d":
        rom.add(byte 0xba)
      of "e":
        rom.add(byte 0xbb)
      of "h":
        rom.add(byte 0xbc)
      of "l":
        rom.add(byte 0xbd)
      of "(hl)":
        rom.add(byte 0xbe)
      of "a":
        rom.add(byte 0xbf)
      else:
        if piece[2].startsWith("$"):
          rom.add(byte 0xfe)
          rom.add(extractByte(piece[2]))
          inc pc
        elif piece[2].startsWith("."):
          rom.add(byte 0xfe)
          rom.add(extractByteFromDec(piece[2]))
          inc pc
        else:
          rom.add(byte 0xbf)

    of "jp":
      var operand_pos = 1
      case piece[1].toLowerAscii()
      # Not Zero
      of "nz":
        rom.add(byte 0xc2)
        operand_pos += 1
      # Zero
      of "z":
        rom.add(byte 0xca)
        operand_pos += 1
      # Not Carry
      of "nc":
        rom.add(byte 0xd2)
        operand_pos += 1
      # Carry
      of "c":
        rom.add(byte 0xda)
        operand_pos += 1
      else:
        rom.add(byte 0xc3)
      # Immediate Address
      if piece[operand_pos].toLowerAscii().startsWith("$"):
        let bytes: array[2, byte] = extract2Bytes(piece[1])
        rom.add(bytes[0])
        rom.add(bytes[1])
      # Label
      elif piece[operand_pos].toLowerAscii().startsWith("&"):
        rom.add(byte 0x00)
        rom.add(byte 0x00)
        jp_list[pc] = piece[operand_pos][1..^1]
        inc pc
        inc pc
    # Labels
    else:
      if piece[0].endsWith(":"):
        jp_labels[piece[0][0..^2]] = pc
        dec pc
    inc pc
  # Insert Labels
  for key, val in jp_list:
    if val in jp_labels:
      let loc: int = jp_labels[val]
      if loc > 0xFF:
        rom[key+2] = byte (loc and 0xFF)
        rom[key+1] = byte ((loc shr 8) and 0xFF)
      else:
        rom[key+2] = byte loc

  result = rom
