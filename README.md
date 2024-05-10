# Lychee
A bare bones 8 bit computer emulator.
### About
Lychee is a simple and bare bones emulator for a fictional computer with an instruction set heavily based on the GameBoy's CPU. Lychee is built to be restraining with no graphics, only supporting text mode graphics, and a ascii based keyboard.

## Specification
Check out the `docs/specs` folder for more on opcodes and specification.

## ROMS
Roms are either written in raw hex, using a hex editor. Or the official assembler found in the `/assembler` directory.

Examples are found in `/assembler/examples`.

And more info on the assembler at [`assembler/docs`](assembler/docs/)

## Compilation
Make sure the Nim compiler and Nimble package manager is installed.

To compile we need the [sokol-nim](https://github.com/floooh/sokol-nim) graphics library. Clone the repo locally, and install using nimble.
```bash
git clone https://github.com/floooh/sokol-nim.git
cd sokol-nim
nimble install
```

Next clone this repo and run.
```bash
git clone https://github.com/imagineeeinc/lychee.git
cd lychee

# Debug (Run)
nimble debug

# Build release
nimble release
```
### Compiling the assembler
```bash
# cd into the assembler
cd assembler
nimble build

# Try the example project
./lasm examples/loopchars.asm ../rom
# For windows
./lasm.exe examples/loopchars.asm ../rom
# Then run it in lychee
cd ..
nimble debug
```