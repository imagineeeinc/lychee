# Hardware specification
The lychee follows the CPU and quite a bit of the hardware architecture of a GameBoy. It has been built to be quite bare bones and has very limited functionality.

To read the full specification as a list read the [`specs` document](spec.md)

## Display
To keep things simple it has a simple text based graphics output. No Bitmaps or tiles.

It consists of 65x45 character display (2880 characters in total). Each character supports 4 bit colour, 16 predefined colours. Each character supports a foreground colour and background colour, represented by a byte, with the upper 4 bits representing the background and the lower 4 bits representing the foreground.

The character set is the default C64 character set.

## CPU
The CPU heavily borrows many of the instruction set and behaviours from the Z80 from a GameBoy.

It uses an 8 bit instruction set and a 16 bit address bus.

However the CPU is clocked at only 500Hz (over and under clock-able).

The CPU also contains a fixed 60Hz timer, that can be used to timed operations.

### Registers
- `a`: Accumulator
- `f`: Flags (*not-writable*)
- `b`: General purpose registers
- `c`: General purpose registers
- `d`: General purpose registers
- `e`: General purpose registers
- `h`: General purpose registers
- `l`: General purpose registers
- `pc`: Program counter (*not-writable*)
- `sp`: Stack pointer (*not-writable*)

The `h` and `l` registers are quite often merged to create a 16 bit register used for memory addresses or 16 bit math; denoted by `hl` or `(hl)` to point to an address in memory that is stored in `hl`.

### Flags
These flags are set when an operation results in these.
- `c`: carry
- `z`: zero
- `n`: subtraction
- `h`: half carry
#### Examples
- If a math operation overflows then `c` is set.
- If a math operation returns 0 then `z` is set.

### Memory
Lychee used memory-mapped memory and I/O. This means all that the ROM, Work RAM, Character display memory and I/O all live under the same memory address range.

Lychee uses a 16 bit address bus, thus 65536 possible address locations. This is then split between the different parts of the machine.
1. ($0000-$8000) 32 kb: ROM
2. ($8001-$9680) 5760 bytes: Character display memory
3. ($9681-$9999) 2432 bytes: Flags & I/O
4. ($A000 - $FFFF) 24 kb: Work RAM (High RAM)

#### Character display memory
Between `$8001`-`$9680` is where all the character data is stored. For each address that stores the character, the adjacent memory address is the character's colour data.

As the address goes up we move along the from left to right, once we reach the end of a line we loop back to the left of the next line.