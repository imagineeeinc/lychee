# Emulator Desktop
The Lychee emulator desktop is the simplest way to currently run and debug programs.

## CLI
Simply run lychee by passing the path to the rom onin the command.
```bash
lychee ./rom
```
To  start of in the paused state, pass the `--paused` flag. To start of in debug slow mode, which runs at 1 cycle per second, pass the `-d` flag.
```bash
lychee rom --paused
lychee rom -d
```

## Debug tools
While the program is running. there will be a ui in the command line. This is used to visualize data in the emulator and send debug commands.

### View
Most numerical data is displayed in hex.

Simply The left most box holds the current registers, program counter, and the current instruction (MBR).

The 2nd left box is split into debug mode in the top and other data in the CPU in the bottom.

### Keyboard Shortcuts
- `<Space>`: Pause emulation.
- `n`: Jump to next instruction while paused.
- `d`: Enters debug mode at 1 cycle per second.
- `Ctrl+b`: Creates a memory dump from address `$0000` to `$ffff` in a hex file. Name will be: `<rom file name>-dump.bin`, will override any dump that exists.
- `<Esc>`/ `q`: Quit Emulator.

## GUI Window
The gui window is the visual representation of the character display and any keyboard inputs are entered through here.

### Loading roms on windows
Another way to load roms that works on windows is by simply dragging the rom over the executable in the Explorer.