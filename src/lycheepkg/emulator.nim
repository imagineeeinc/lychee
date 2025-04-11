import strutils

const mem_size: int = 24576 # 24kb
const vmem_size: int = 5760 # 5.6kb
const mem_offset*: int = 0x8001

const workmem_start: int = 0xA000

type Flags = ref object
  c*: bool # carry
  z*: bool # zero
  n*: bool # subtraction
  h*: bool # half carry

type Register = ref object
  a*: byte  # Accumulator [Wriable]              (Accu)
  f*: byte  # Flags [Non-writable]               (F) -> [https://gbdev.io/pandocs/CPU_Registers_and_Flags.html#the-flags-register-lower-8-bits-of-af-register]
  b*: byte  # General purpose registers [Wriable] (GEr)
  c*: byte  # General purpose registers [Wriable] (GEr)
  d*: byte  # General purpose registers [Wriable] (GEr)
  e*: byte  # General purpose registers [Wriable] (GEr)
  h*: byte  # General purpose registers [Wriable] (GEr)
  l*: byte  # General purpose registers [Wriable] (GEr)
  pc*: int # Program counter [Writable]         (PC)
  sp*: int # Stack pointer [Non-writable]       (SP)


type LycheeEmulator* = ref object
  r*: Register
  f*: Flags
  program*: seq[string]
  workram*: array[mem_size+vmem_size, byte]


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
    f: Flags(
      c: false,
      z: false,
      n: false,
      h: false
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

  self.f.z = false

  # Constants
  let hl = fromHex[int](toHex(parseHexInt(self.r.h.toHex & self.r.l.toHex) - mem_offset))
  let a16 = fromHex[int](toHex(parseHexInt(program[pc+1] & program[pc+2]) - mem_offset))

  case msn
  of 0x00:
    case lsn
    of 0x00:
      discard
    else:
      discard
  of 0x03:
    case lsn
    of 0x04:# inc (hl)
      inc self.workram[hl]
      if self.r.a == 0x00:
        self.f.z = true
    of 0x05:# dec (hl)
      dec self.workram[hl]
      if self.r.a == 0x00:
        self.f.z = true
    of 0x0C:# inc a
      inc self.r.a
      if self.r.a == 0x00:
        self.f.z = true
    of 0x0D:# dec a
      dec self.r.a
      if self.r.a == 0x00:
        self.f.z = true
    of 0x0E:# ld a, d8
      self.r.a = fromHex[byte](program[pc+1])
      inc self.r.pc
    else:
      discard
  of 0x04:
    case lsn
    of 0x00:# ld b, b
      self.r.b = self.r.b
    of 0x01:# ld b, c
      self.r.b = self.r.c
    of 0x02:# ld b, d
      self.r.b = self.r.d
    of 0x03:# ld b, e
      self.r.b = self.r.e
    of 0x04:# ld b, h
      self.r.b = self.r.h
    of 0x05:# ld b, l
      self.r.b = self.r.l
    of 0x06:# ld b, (hl)
      self.r.b = self.workram[hl]
    of 0x07:# ld b, a
      self.r.b = self.r.a
    of 0x08:# ld c, b
      self.r.c = self.r.b
    of 0x09:# ld c, c
      self.r.c = self.r.c
    of 0x0A:# ld c, d
      self.r.c = self.r.d
    of 0x0B:# ld c, e
      self.r.c = self.r.e
    of 0x0C:# ld c, h
      self.r.c = self.r.h
    of 0x0D:# ld c, l
      self.r.c = self.r.l
    of 0x0E:# ld c, (hl)
      self.r.c = self.workram[hl]
    of 0x0F:# ld c, a
      self.r.c = self.r.a
    else:
      discard
  of 0x05:
    case lsn
    of 0x00:# ld d, b
      self.r.d = self.r.b
    of 0x01:# ld d, c
      self.r.d = self.r.c
    of 0x02:# ld d, d
      self.r.d = self.r.d
    of 0x03:# ld d, e
      self.r.d = self.r.e
    of 0x04:# ld d, h
      self.r.d = self.r.h
    of 0x05:# ld d, l
      self.r.d = self.r.l
    of 0x06:# ld d, (hl)
      self.r.d = self.workram[hl]
    of 0x07:# ld d, a
      self.r.d = self.r.a
    of 0x08:# ld e, b
      self.r.e = self.r.b
    of 0x09:# ld e, c
      self.r.e = self.r.c
    of 0x0A:# ld e, d
      self.r.e = self.r.d
    of 0x0B:# ld e, e
      self.r.e = self.r.e
    of 0x0C:# ld e, h
      self.r.e = self.r.h
    of 0x0D:# ld e, l
      self.r.e = self.r.l
    of 0x0E:# ld e, (hl)
      self.r.e = self.workram[hl]
    of 0x0F:# ld e, a
      self.r.e = self.r.a
    else:
      discard
  of 0x06:
    case lsn
    of 0x00:# ld h, b
      self.r.h = self.r.b
    of 0x01:# ld h, c
      self.r.h = self.r.c
    of 0x02:# ld h, d
      self.r.h = self.r.d
    of 0x03:# ld h, e
      self.r.h = self.r.e
    of 0x04:# ld h, h
      self.r.h = self.r.h
    of 0x05:# ld h, l
      self.r.h = self.r.l
    of 0x06:# ld h, (hl)
      self.r.h = self.workram[hl]
    of 0x07:# ld h, a
      self.r.h = self.r.a
    of 0x08:# ld l, b
      self.r.l = self.r.b
    of 0x09:# ld l, c
      self.r.l = self.r.c
    of 0x0A:# ld l, d
      self.r.l = self.r.d
    of 0x0B:# ld l, e
      self.r.l = self.r.e
    of 0x0C:# ld l, h
      self.r.l = self.r.h
    of 0x0D:# ld l, l
      self.r.l = self.r.l
    of 0x0E:# ld l, (hl)
      self.r.l = self.workram[hl]
    of 0x0F:# ld l, a
      self.r.l = self.r.a
    else:
      discard
  of 0x07:
    case lsn
    of 0x00:# ld (hl), b
      self.workram[hl] = self.r.b
    of 0x01:# ld (hl), c
      self.workram[hl] = self.r.c
    of 0x02:# ld (hl), d
      self.workram[hl] = self.r.d
    of 0x03:# ld (hl), e
      self.workram[hl] = self.r.e
    of 0x04:# ld (hl), h
      self.workram[hl] = self.r.h
    of 0x05:# ld (hl), l
      self.workram[hl] = self.r.l
    of 0x06:# halt
      return 1
    of 0x07:# ld (hl), a
      self.workram[hl] = self.r.a
    of 0x08:# ld a, b
      self.r.a = self.r.b
    of 0x09:# ld a, c
      self.r.a = self.r.c
    of 0x0A:# ld a, d
      self.r.a = self.r.d
    of 0x0B:# ld a, e
      self.r.a = self.r.e
    of 0x0C:# ld a, h
      self.r.a = self.r.h
    of 0x0D:# ld a, l
      self.r.a = self.r.l
    of 0x0E:# ld a, (hl)
      self.r.a = self.workram[hl]
    of 0x0F:# ld a, a
      self.r.a = self.r.a
    else:
      discard
  of 0x08:
    case lsn
    of 0x00: # add a, b
      self.r.a += self.r.b
      if self.r.a == 0x00:
        self.f.z = true
    of 0x01: # add a, c
      self.r.a += self.r.c
      if self.r.a == 0x00:
        self.f.z = true
    of 0x02: # add a, d
      self.r.a += self.r.d
      if self.r.a == 0x00:
        self.f.z = true
    of 0x03: # add a, e
      self.r.a += self.r.e
      if self.r.a == 0x00:
        self.f.z = true
    of 0x04: # add a, h
      self.r.a += self.r.h
      if self.r.a == 0x00:
        self.f.z = true
    of 0x05: # add a, l
      self.r.a += self.r.l
      if self.r.a == 0x00:
        self.f.z = true
    of 0x06: # add a, (hl)
      self.r.a += self.workram[hl]
      if self.r.a == 0x00:
        self.f.z = true
    of 0x07: # add a, a
      self.r.a += self.r.a
      if self.r.a == 0x00:
        self.f.z = true
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
  of 0x09:
    case lsn
    of 0x00: # sub b
      self.r.a -= self.r.b
      if self.r.a == 0x00:
        self.f.z = true
    of 0x01: # sub c
      self.r.a -= self.r.c
      if self.r.a == 0x00:
        self.f.z = true
    of 0x02: # sub d
      self.r.a -= self.r.d
      if self.r.a == 0x00:
        self.f.z = true
    of 0x03: # sub e
      self.r.a -= self.r.e
      if self.r.a == 0x00:
        self.f.z = true
    of 0x04: # sub h
      self.r.a -= self.r.h
      if self.r.a == 0x00:
        self.f.z = true
    of 0x05: # sub l
      self.r.a -= self.r.l
      if self.r.a == 0x00:
        self.f.z = true
    of 0x06: # sub (hl)
      self.r.a -= self.workram[hl]
      if self.r.a == 0x00:
        self.f.z = true
    of 0x07: # sub a
      self.r.a -=  self.r.a
      if self.r.a == 0x00:
        self.f.z = true
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
    of 0x06:# add a, d8
      self.r.a += fromHex[byte](program[pc+1])
      if self.r.a == 0x00:
        self.f.z = true
      inc self.r.pc
    else:
      discard
  of 0x0D:
    case lsn
    of 0x06: # sub a, d8
      self.r.a -= fromHex[byte](program[pc+1])
      if self.r.a == 0x00:
        self.f.z = true
      inc self.r.pc
    else:
      discard
  of 0x0E:
    case lsn
    of 0x0A:# ld a16, a
      self.workram[a16] = self.r.a
      inc(self.r.pc, 2)
    else:
      discard
  of 0x0F:
    case lsn
    of 0x0A:# ld a, a16
      self.r.a = self.workram[a16]
      inc(self.r.pc, 2)
    else:
      discard
  else:
    discard
  return 0

