# Lychee Assembler
Lychee assembly (and the instruction set) is *highly* similar to Gameboy assembly, and thus most of the knowledge transfers over.

## Contents
- [Lychee Assembler](#lychee-assembler)
	- [Contents](#contents)
	- [Assembler (LASM)](#assembler-lasm)
		- [Building](#building)
		- [Usage](#usage)
	- [Assembly Language](#assembly-language)
		- [Syntax](#syntax)
		- [Symbols](#symbols)
		- [Sections](#sections)

## Assembler (LASM)
The lychee assembler (lasm) is a very simple assembler which simply translates the assembly code to machine code that the CPU will understand.
### Building
- For Debug purposes.
	```bash
	nimble run
	# Pass args after a --
	nimble run -- ../examples/asm/loopchars.asm ../rom
	```
- For release and official usage.
	```bash
	nimble build -d:release
	```
- Copy the `lasm` or `lasm.exe` to your `PATH` or use in place.
	```bash
	./lasm ../examples/asm/loopchars.asm ../rom
	```
### Usage
Simply pass in the input file as the first argument and the output rom as the second argument.
```bash
lasm <input> <output>
# Example
lasm ./examples/asm/loopchars.asm ./rom
```
## Assembly Language
Lychee uses a derivative of the standard assembly.

### Syntax
Each instruction is on a new line, and this is very important or the assembler will parse properly. Each value on each line has to be separated by space, nothing else (no commas), so the opcode and subsequent operands have to be spaced y a space.

1. Opcode: The instruction to call
2. Operands: Any value that need to passed to the instruction.

```
ld a $10
\/ \ \_/
||  \_\\_>Operands
||
Opcode
```

### Symbols
Lychee assembly uses specialised symbols to to denote data types.
- `$00` (Hex): A `$` followed by numeric values represents a hex value.
- `&name` (Section Names): A `&` followed by a tag represents a position in the rom, useful for jumps.

### Sections
Sections are placed before a piece of code and is useful for the jump instruction, define a section by adding tag name followed by a `:`. Anything below that tag will be ran. Do not if you don't move to somewhere else, the CPU will just move to the next section. And this can be used strategically by placing sections next to each other for a planned behaviour.