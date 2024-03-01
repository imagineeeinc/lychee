import strutils
import std/[times]

const mem_size: int = 22528

type Register = ref object
  a*: byte  # Accumulator [Wriable]              (Accu)
  f*: byte  # Flags [Non-writable]               (F) -> [https://gbdev.io/pandocs/CPU_Registers_and_Flags.html#the-flags-register-lower-8-bits-of-af-register]
  b*: byte  # Genral purpose registers [Wriable] (GEr)
  c*: byte  # Genral purpose registers [Wriable] (GEr)
  d*: byte  # Genral purpose registers [Wriable] (GEr)
  e*: byte  # Genral purpose registers [Wriable] (GEr)
  h*: byte  # Genral purpose registers [Wriable] (GEr)
  l*: byte  # Genral purpose registers [Wriable] (GEr)
  pc*: int # Program counter [Writable]         (PC)
  sp*: int # Stack pointer [Non-writable]       (SP)


type LycheeEmulator = ref object
  r*: Register
  program*: seq[string]
  workram*: array[mem_size, byte]


proc initLycheeEmulator*(): LycheeEmulator =
  result = LycheeEmulator(
    r: Register(
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
    program: newSeq[string]()
  )

proc loadRom*(self: LycheeEmulator, rom: seq[string]) =
  self.program = rom

proc cycle*(self: LycheeEmulator): int =
  let pc = self.r.pc
  let program = self.program
  let mar = fromHex[byte](program[pc])
  # Most significant nibble
  let msn = mar shr 4
  # Least significant nibble
  let lsn = mar and 0x0f

  inc self.r.pc
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
      # LD a, d8
      self.r.a = fromHex[byte](program[pc+1])
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
      # TODO: Fetch from work ram
      # self.r.b = fromHex[int](self.r.h.toHex & self.r.l.toHex)
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
      # TODO: Fetch from work ram
      # self.r.b = fromHex[int](self.r.h.toHex & self.r.l.toHex)
      discard
    of 0x0F:
      self.r.c = self.r.a
    else:
      discard
  of 0x09:
    case lsn
    # sub R
    of 0x00: # sub b
      self.r.a = self.r.a - self.r.b
    of 0x01: # sub c
      self.r.a = self.r.a - self.r.c
    of 0x02: # sub d
      self.r.a = self.r.a - self.r.d
    of 0x03: # sub e
      self.r.a = self.r.a - self.r.e
    of 0x04: # sub h
      self.r.a = self.r.a - self.r.h
    of 0x05: # sub l
      self.r.a = self.r.a - self.r.l
    of 0x06: # sub (hl)
      # TODO: Fetch from work ram and sub
      # self.r.a = fromHex[int](self.r.h.toHex & self.r.l.toHex)
      discard
    of 0x07: # sub a
      self.r.a = self.r.a -  self.r.a
    of 0x08:
      discard
    of 0x09:
      discard
    of 0x0A:
      discard
    of 0x0B:
      discard
    of 0x0C:
      discard
    of 0x0D:
      discard
    of 0x0E:
      discard
    of 0x0F:
      discard
    else:
      discard
  of 0x0C:
    case lsn
    of 0x03:# jp a16
      self.r.pc = fromHex[int](program[pc+1] & program[pc+2])
    else:
      discard
  of 0x0E:
    case lsn
    of 0x0A:# ld a16, A
      # TODO: Fetch from work ram and sub
      # self.r.a = fromHex[int](self.r.h.toHex & self.r.l.toHex)
      discard
    else:
      discard
  of 0x0F:
    case lsn
    of 0x0A:# ld A, a16
      # TODO: Fetch from work ram and sub
      # self.r.a = fromHex[int](self.r.h.toHex & self.r.l.toHex)
      discard
    else:
      discard
  else:
    discard

