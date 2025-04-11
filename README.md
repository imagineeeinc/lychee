<p align="center">
	<img src="./lychee.png">
</p>
<h1 align="center">Lychee</h1>

A bare bones 8 bit computer emulator.
### About
Lychee is a simple and bare bones emulator for a fictional computer with an instruction set heavily based on the GameBoy's CPU. Lychee is built to be restraining with no graphics, only supporting text mode graphics, and a ascii based keyboard.

**Still a work in progress, as the instruction set and docs is being added** 

## Specification
Check out the [`docs/specs`](docs/spec) folder for more on opcodes and specification.

## ROMS
Roms are either written in raw hex, using a hex editor (example roms in `/examples/roms`). Or use the official assembler found in the `/assembler` directory. Assembly examples are found in `/examples/asm`.

And more info on the assembler at [`docs/assembler`](docs/assembler)

## Usage
### Compilation
#### Compiling the Emulator
Make sure the [Nim compiler and Nimble package manager](https://nim-lang.org/) is installed.

Clone this repo and compile using nimble.
```bash
git clone https://github.com/imagineeeinc/lychee.git
cd lychee

# Debug (Run)
nimble debug

# Build release
nimble release
```
#### Compiling the assembler
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