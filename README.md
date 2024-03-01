# Lychee
A bare bones 8 bit computer emulator.
### About
Lychee is a simple and bare bones emulator for a fictional computer with an instruction set heavily based on the GameBoy's CPU. Lychee is built to be restraining with no graphics, only supporting text mode graphics, and a ascii based keyboard.

## Specification
Check out the `docs/specs` folder for more on opcodes and specification.

## ROMS
Roms are currently written in raw hex (no assembler right now), written using a hex editor you can write down opcodes in a file.

example rom:
```
3e 0a 47 3e 14 90 c3 00 00
```