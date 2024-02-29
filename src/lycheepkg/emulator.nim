import strutils
import std/[times]

type Register = ref object
  a: byte  # Accumulator [Wriable]              (Accu)
  f: byte  # Flags [Non-writable]               (F) -> [https://gbdev.io/pandocs/CPU_Registers_and_Flags.html#the-flags-register-lower-8-bits-of-af-register]
  b: byte  # Genral purpose registers [Wriable] (GEr)
  c: byte  # Genral purpose registers [Wriable] (GEr)
  d: byte  # Genral purpose registers [Wriable] (GEr)
  e: byte  # Genral purpose registers [Wriable] (GEr)
  h: byte  # Genral purpose registers [Wriable] (GEr)
  l: byte  # Genral purpose registers [Wriable] (GEr)
  pc: int # Program counter [Writable]         (PC)
  sp: int # Stack pointer [Non-writable]       (SP)
type LycheeEmulator = ref object
  r: Register
  program: seq[string]

# proc loadProgram(self: LycheeEmulator, code: string) =
#   var curCommand: seq[string] = newSeq[string]()
#   for token in tokenize(code):
#     if token.token == "\n" and token.isSep == true:
#       self.program.add(curCommand)
#       curCommand = newSeq[string]()
#     elif token.token == "end":
#       self.program.add(@["end"])
#     elif token.isSep == false:
#       curCommand.add(token.token)

proc initLycheeEmulator*(): LycheeEmulator =
  result = LycheeEmulator(
    r:Register(
      a: 0x00,
      f: 0x00,
      b: 0x00,
      c: 0x00,
      d: 0x00,
      e: 0x00,
      h: 0x00,
      l: 0x00,
      pc: 0,
      sp: 0
    ),
    program:newSeq[string]()
  )

proc loadRom*(self: LycheeEmulator, rom: seq[string]) =
  self.program = rom

proc cycle*(self: LycheeEmulator): int =
  let pc = self.r.pc
  let mar = fromHex[byte](self.program[pc])
  # Most significant nibble
  let msn = mar shr 4
  # Least significant nibble
  let lsn = mar and 0x0f
  case msn
  of 0x00:
    case lsn
    of 0x00:
      discard
    else:
      discard
  of 0x03:
    case lsn
    of 0x0E:
      self.r.a = fromHex[byte](self.program[pc+1])
      inc self.r.pc
    else:
      discard
  of 0x04:
    case lsn
    of 0x00:
      self.r.b = self.r.b
    of 0x01:
      self.r.b = self.r.c
    of 0x02:
      self.r.b = self.r.d
    of 0x03:
      self.r.b = self.r.e
    of 0x04:
      self.r.b = self.r.h
    of 0x05:
      self.r.b = self.r.l
    of 0x06:
      # TODO: get from 16 bit mem address
      discard
    of 0x07:
      self.r.b = self.r.a
    of 0x08:
      self.r.c = self.r.b
    of 0x09:
      self.r.c = self.r.c
    of 0x0A:
      self.r.c = self.r.d
    of 0x0B:
      self.r.c = self.r.e
    of 0x0C:
      self.r.c = self.r.h
    of 0x0D:
      self.r.c = self.r.l
    of 0x0E:
      # TODO: get from 16 bit mem address
      discard
    of 0x0F:
      self.r.c = self.r.a
    else:
      discard
  else:
    discard
  echo self.r.a
  echo self.r.b
  inc self.r.pc
