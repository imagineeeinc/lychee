# import strutils

type Register = ref object
  a: int  # Accumulator [Wriable]              (Accu)
  f: int  # Flags [Non-writable]               (F) -> [https://gbdev.io/pandocs/CPU_Registers_and_Flags.html#the-flags-register-lower-8-bits-of-af-register]
  b: int  # Genral purpose registers [Wriable] (GEr)
  c: int  # Genral purpose registers [Wriable] (GEr)
  d: int  # Genral purpose registers [Wriable] (GEr)
  e: int  # Genral purpose registers [Wriable] (GEr)
  h: int  # Genral purpose registers [Wriable] (GEr)
  l: int  # Genral purpose registers [Wriable] (GEr)
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
      a: 0,
      f: 0,
      b: 0,
      c: 0,
      d: 0,
      e: 0,
      h: 0,
      l: 0,
      pc: 0,
      sp: 0
    ),
    program:newSeq[string]()
  )

proc loadRom*(self: LycheeEmulator, rom: seq[string]) =
  self.program = rom

proc start*(self: LycheeEmulator) =
  echo "start"
