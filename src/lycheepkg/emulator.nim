import strutils, system, std/[bitops]

const mem_size: int = 24576 # 24kb
const vmem_size: int = 5760 # 5.6kb
const mem_offset*: int = 0x8001
const ram_size*: int = 64 * 1024

const workmem_start: int = 0xA000

type Flags = ref object
  c*: byte # carry
  z*: bool # zero
  n*: bool # subtraction
  h*: bool # half carry

type Register = ref object
  a*: byte  # Accumulator [Wriable]                (Accu)
  f*: byte  # Flags [Non-writable]                 (F) -> [https://gbdev.io/pandocs/CPU_Registers_and_Flags.html#the-flags-register-lower-8-bits-of-af-register]
  b*: byte  # General purpose registers [Wriable] (GEr)
  c*: byte  # General purpose registers [Wriable] (GEr)
  d*: byte  # General purpose registers [Wriable] (GEr)
  e*: byte  # General purpose registers [Wriable] (GEr)
  h*: byte  # General purpose registers [Wriable] (GEr)
  l*: byte  # General purpose registers [Wriable] (GEr)
  pc*: int # Program counter [Writable]           (PC)
  sp*: int # Stack pointer [Non-writable]         (SP)
  timer*: int # Timer [Writable]


type LycheeEmulator* = ref object
  r*: Register
  f*: Flags
  program*: seq[string]
  ram*: array[ram_size, byte]


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
      c: 0x00,
      z: false,
      n: false,
      h: false
    ),
    program: newSeq[string]()
  )

proc loadRom*(self: LycheeEmulator, rom: seq[string]) =
  self.program = rom
  for pos in 0..<len(self.program):
    let instruction = self.program[pos]
    self.ram[pos] = fromHex[byte](instruction)

proc mem_dump*(self: LycheeEmulator): seq[byte] =
  var buf: seq[byte] = newSeq[byte](len(self.ram))
  for pos in 0..<len(self.ram):
    let instruction = self.ram[pos]
    buf[pos] = instruction
  result = buf

proc cycle*(self: LycheeEmulator): int =
  let pc = self.r.pc
  let mar = self.ram[pc]
  # Most significant nibble
  let msn = mar shr 4
  # Least significant nibble
  let lsn = mar and 0x0f

  inc self.r.pc

  let z = self.f.z
  let c = self.f.c
  self.f.z = false
  self.f.c = 0x00

  # Constants
  let hl = fromHex[int](toHex(parseHexInt(self.r.h.toHex & self.r.l.toHex)))
  let bc = fromHex[int](toHex(parseHexInt(self.r.b.toHex & self.r.c.toHex)))
  let de = fromHex[int](toHex(parseHexInt(self.r.d.toHex & self.r.e.toHex)))
  let a16 = fromHex[int](self.ram[pc+1].toHex & self.ram[pc+2].toHex)

  case msn
  of 0x00:
    case lsn
    of 0x00:
      discard
    of 0x09: # add hl bc
      let temp = hl
      let res = hl + bc
      let lsbyte = byte (res and 0xFF)
      let msbyte = byte ((res shr 8) and 0xFF)
      self.r.h = msbyte
      self.r.l = lsbyte
      if res <= temp:
        self.f.c = lsbyte
      if res == 0x00:
        self.f.z = true
    else:
      discard
  of 0x01:
    case lsn
    of 0x09: # add hl de
      let temp = hl
      let res = hl + de
      let msbyte = byte (res and 0xFF)
      let lsbyte = byte ((res shr 8) and 0xFF)
      self.r.h = msbyte
      self.r.l = lsbyte
      if res <= temp:
        self.f.c = lsbyte
      if res == 0x00:
        self.f.z = true
    else:
      discard
  of 0x02:
    case lsn
    of 0x09: # add hl hl
      let temp = hl
      let res = hl + hl
      let msbyte = byte (res and 0xFF)
      let lsbyte = byte ((res shr 8) and 0xFF)
      self.r.h = msbyte
      self.r.l = lsbyte
      if res <= temp:
        self.f.c = lsbyte
      if res == 0x00:
        self.f.z = true
    else:
      discard
  of 0x03:
    case lsn
    of 0x04:# inc (hl)
      inc self.ram[hl]
      if self.ram[hl] == 0x00:
        self.f.z = true
    of 0x05:# dec (hl)
      dec self.ram[hl]
      if self.ram[hl] == 0x00:
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
      self.r.a = self.ram[pc+1]
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
      self.r.b = self.ram[hl]
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
      self.r.c = self.ram[hl]
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
      self.r.d = self.ram[hl]
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
      self.r.e = self.ram[hl]
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
      self.r.h = self.ram[hl]
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
      self.r.l = self.ram[hl]
    of 0x0F:# ld l, a
      self.r.l = self.r.a
    else:
      discard
  of 0x07:
    case lsn
    of 0x00:# ld (hl), b
      self.ram[hl] = self.r.b
    of 0x01:# ld (hl), c
      self.ram[hl] = self.r.c
    of 0x02:# ld (hl), d
      self.ram[hl] = self.r.d
    of 0x03:# ld (hl), e
      self.ram[hl] = self.r.e
    of 0x04:# ld (hl), h
      self.ram[hl] = self.r.h
    of 0x05:# ld (hl), l
      self.ram[hl] = self.r.l
    of 0x06:# halt
      return 1
    of 0x07:# ld (hl), a
      self.ram[hl] = self.r.a
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
      self.r.a = self.ram[hl]
    of 0x0F:# ld a, a
      self.r.a = self.r.a
    else:
      discard
  of 0x08:
    case lsn
    of 0x00: # add a, b
      let temp = self.r.a
      self.r.a += self.r.b
      if self.r.a <= temp:
        self.f.c = self.r.a
      if self.r.a == 0x00:
        self.f.z = true
    of 0x01: # add a, c
      let temp = self.r.a
      self.r.a += self.r.c
      if self.r.a <= temp:
        self.f.c = self.r.a
      if self.r.a == 0x00:
        self.f.z = true
    of 0x02: # add a, d
      let temp = self.r.a
      self.r.a += self.r.d
      if self.r.a <= temp:
        self.f.c = self.r.a
      if self.r.a == 0x00:
        self.f.z = true
    of 0x03: # add a, e
      let temp = self.r.a
      self.r.a += self.r.e
      if self.r.a <= temp:
        self.f.c = self.r.a
      if self.r.a == 0x00:
        self.f.z = true
    of 0x04: # add a, h
      let temp = self.r.a
      self.r.a += self.r.h
      if self.r.a <= temp:
        self.f.c = self.r.a
      if self.r.a == 0x00:
        self.f.z = true
    of 0x05: # add a, l
      let temp = self.r.a
      self.r.a += self.r.l
      if self.r.a <= temp:
        self.f.c = self.r.a
      if self.r.a == 0x00:
        self.f.z = true
    of 0x06: # add a, (hl)
      let temp = self.r.a
      self.r.a += self.ram[hl]
      if self.r.a <= temp:
        self.f.c = self.r.a
      if self.r.a == 0x00:
        self.f.z = true
    of 0x07: # add a, a
      let temp = self.r.a
      self.r.a += self.r.a
      if self.r.a <= temp:
        self.f.c = self.r.a
      if self.r.a == 0x00:
        self.f.z = true
    of 0x08:
      discard
    of 0x09:
      discard
    of 0x0A:
      case lsn
      of 0x00: # and b
        self.r.a = bitand[byte](self.r.a, self.r.b)
        if self.r.a == 0x00:
          self.f.z = true
      of 0x01: # and c
        self.r.a = bitand[byte](self.r.a, self.r.c)
        if self.r.a == 0x00:
          self.f.z = true
      of 0x02: # and d
        self.r.a = bitand[byte](self.r.a, self.r.d)
        if self.r.a == 0x00:
          self.f.z = true
      of 0x03: # and e
        self.r.a = bitand[byte](self.r.a, self.r.e)
        if self.r.a == 0x00:
          self.f.z = true
      of 0x04: # and h
        self.r.a = bitand[byte](self.r.a, self.r.h)
        if self.r.a == 0x00:
          self.f.z = true
      of 0x05: # and l
        self.r.a = bitand[byte](self.r.a, self.r.l)
        if self.r.a == 0x00:
          self.f.z = true
      of 0x06: # and (hl)
        self.r.a = bitand[byte](self.r.a, self.ram[hl])
        if self.r.a == 0x00:
          self.f.z = true
      of 0x07: # and a
        self.r.a = bitand[byte](self.r.a, self.r.a)
        if self.r.a == 0x00:
          self.f.z = true
      of 0x08: # xor b
        self.r.a = bitxor[byte](self.r.a, self.r.b)
        if self.r.a == 0x00:
          self.f.z = true
      of 0x09: # xor c
        self.r.a = bitxor[byte](self.r.a, self.r.c)
        if self.r.a == 0x00:
          self.f.z = true
      of 0x0A: # xor d
        self.r.a = bitxor[byte](self.r.a, self.r.d)
        if self.r.a == 0x00:
          self.f.z = true
      of 0x0B: # xor e
        self.r.a = bitxor[byte](self.r.a, self.r.e)
        if self.r.a == 0x00:
          self.f.z = true
      of 0x0C: # xor h
        self.r.a = bitxor[byte](self.r.a, self.r.h)
        if self.r.a == 0x00:
          self.f.z = true
      of 0x0D: # xor l
        self.r.a = bitxor[byte](self.r.a, self.r.l)
        if self.r.a == 0x00:
          self.f.z = true
      of 0x0E: # xor (hl)
        self.r.a = bitxor[byte](self.r.a, self.ram[hl])
        if self.r.a == 0x00:
          self.f.z = true
      of 0x0F: # xor a
        self.r.a = bitxor[byte](self.r.a, self.r.a)
        if self.r.a == 0x00:
          self.f.z = true
      else:
        discard
    of 0x0B:
      case lsn
      of 0x00: # or b
        self.r.a = bitor[byte](self.r.a, self.r.b)
        if self.r.a == 0x00:
          self.f.z = true
      of 0x01: # or c
        self.r.a = bitor[byte](self.r.a, self.r.c)
        if self.r.a == 0x00:
          self.f.z = true
      of 0x02: # or d
        self.r.a = bitor[byte](self.r.a, self.r.d)
        if self.r.a == 0x00:
          self.f.z = true
      of 0x03: # or e
        self.r.a = bitor[byte](self.r.a, self.r.e)
        if self.r.a == 0x00:
          self.f.z = true
      of 0x04: # or h
        self.r.a = bitor[byte](self.r.a, self.r.h)
        if self.r.a == 0x00:
          self.f.z = true
      of 0x05: # or l
        self.r.a = bitor[byte](self.r.a, self.r.l)
        if self.r.a == 0x00:
          self.f.z = true
      of 0x06: # or (hl)
        self.r.a = bitor[byte](self.r.a, self.ram[hl])
        if self.r.a == 0x00:
          self.f.z = true
      of 0x07: # or a
        self.r.a = bitor[byte](self.r.a, self.r.a)
        if self.r.a == 0x00:
          self.f.z = true
      of 0x08: # cp b
        let temp = self.r.a
        let res = self.r.a - self.r.b
        if temp < self.r.b:
          self.f.c = res
        if res == 0x00:
          self.f.z = true
      of 0x09: # cp c
        let temp = self.r.a
        let res = self.r.a - self.r.c
        if temp < self.r.c:
          self.f.c = res
        if res == 0x00:
          self.f.z = true
      of 0x0A: # cp d
        let temp = self.r.a
        let res = self.r.a - self.r.d
        if temp < self.r.d:
          self.f.c = res
        if res == 0x00:
          self.f.z = true
      of 0x0B: # cp e
        let temp = self.r.a
        let res = self.r.a - self.r.e
        if temp < self.r.e:
          self.f.c = res
        if res == 0x00:
          self.f.z = true
      of 0x0C: # cp h
        let temp = self.r.a
        let res = self.r.a - self.r.h
        if temp < self.r.h:
          self.f.c = res
        if res == 0x00:
          self.f.z = true
      of 0x0D: # cp l
        let temp = self.r.a
        let res = self.r.a - self.r.l
        if temp < self.r.l:
          self.f.c = res
        if res == 0x00:
          self.f.z = true
      of 0x0E: # cp (hl)
        let temp = self.r.a
        let res = self.r.a - self.ram[hl]
        if temp < self.ram[hl]:
          self.f.c = res
        if res == 0x00:
          self.f.z = true
      of 0x0F: # cp a
        let temp = self.r.a
        let res = self.r.a - self.r.a
        if temp < self.r.a:
          self.f.c = res
        if res == 0x00:
          self.f.z = true
      else:
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
      let temp = self.r.a
      self.r.a -= self.r.b
      if temp < self.r.b:
        self.f.c = self.r.a
      if self.r.a == 0x00:
        self.f.z = true
    of 0x01: # sub c
      let temp = self.r.a
      self.r.a -= self.r.c
      if temp < self.r.c:
        self.f.c = self.r.a
      if self.r.a == 0x00:
        self.f.z = true
    of 0x02: # sub d
      let temp = self.r.a
      self.r.a -= self.r.d
      if temp < self.r.d:
        self.f.c = self.r.a
      if self.r.a == 0x00:
        self.f.z = true
    of 0x03: # sub e
      let temp = self.r.a
      self.r.a -= self.r.e
      if temp < self.r.e:
        self.f.c = self.r.a
      if self.r.a == 0x00:
        self.f.z = true
    of 0x04: # sub h
      let temp = self.r.a
      self.r.a -= self.r.h
      if temp < self.r.h:
        self.f.c = self.r.a
      if self.r.a == 0x00:
        self.f.z = true
    of 0x05: # sub l
      let temp = self.r.a
      self.r.a -= self.r.l
      if temp < self.r.l:
        self.f.c = self.r.a
      if self.r.a == 0x00:
        self.f.z = true
    of 0x06: # sub (hl)
      let temp = self.r.a
      self.r.a -= self.ram[hl]
      if temp < self.ram[hl]:
        self.f.c = self.r.a
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
    of 0x02:# jp NZ a16
      if not z == true:
        self.r.pc = a16
      else:
        inc(self.r.pc, 2)
    of 0x03:# jp a16
      self.r.pc = a16
    of 0x06:# add a, d8
      let temp = self.r.a
      self.r.a += self.ram[pc+1]
      if self.r.a <= temp:
        self.f.c = self.r.a
      if self.r.a == 0x00:
        self.f.z = true
      inc self.r.pc
    of 0x0A:# jp Z a16
      if z == true:
        self.r.pc = a16
      else:
        inc(self.r.pc, 2)
    else:
      discard
  of 0x0D:
    case lsn
    of 0x02:# jp NC a16
      if c == 0x00:
        self.r.pc = a16
      else:
        inc(self.r.pc, 2)
    of 0x06: # sub a, d8
      let temp = self.r.a
      self.r.a -= self.ram[pc+1]
      if temp < self.ram[pc+1]:
        self.f.c = self.r.a
      if self.r.a == 0x00:
        self.f.z = true
      inc self.r.pc
    of 0x0A:# jp C a16
      if c != 0x00:
        self.r.pc = a16
      else:
        inc(self.r.pc, 2)
    else:
      discard
  of 0x0E:
    case lsn
    of 0x03:# ld Timer, a
      self.r.timer = int self.r.a
      if self.r.timer == 0x00:
        self.f.z = true
    of 0x04:# ld a, Timer
      self.r.a = byte self.r.timer
      if self.r.a == 0x00:
        self.f.z = true
    of 0x08:# and d8
      self.r.a = self.r.a and self.ram[pc+1]
      if self.r.a == 0x00:
        self.f.z = true
    of 0x0A:# ld a16, a
      self.ram[a16] = self.r.a
      inc(self.r.pc, 2)
    else:
      discard
  of 0x0F:
    case lsn
    of 0x0A:# ld a, a16
      self.r.a = self.ram[a16]
      inc(self.r.pc, 2)
    else:
      discard
  else:
    discard
  return 0

