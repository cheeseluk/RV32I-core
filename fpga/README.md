# Running the core on a Nexys A7

`nexys_top.sv` puts the core on a Digilent Nexys A7 (100T or 50T; the Nexys 4 DDR
has the same pins). The program is built into the bitstream, so changing it
means building again.

## Files

| File | |
|---|---|
| `nexys_top.sv` | Board top level: core, memories, 25 MHz clock, reset, memory-mapped I/O |
| `sevenseg.sv` | Drives the 8-digit 7-segment display |
| `nexys_a7.xdc` | Pin constraints |
| `nexys_top_tb.sv` | Simulates the board and reads back what the LEDs and display show |
| `build.ps1` | Builds a program and simulates it, builds a bitstream, or loads it |
| `build.tcl`, `program.tcl` | Vivado scripts that `build.ps1` runs |
| `sw/leds.S` | Demo: LEDs follow the switches, the display counts up |

## Usage

```powershell
.\fpga\build.ps1 leds -Sim -Sw a5a5    # simulate first (seconds, not minutes)
.\fpga\build.ps1 leds                  # Vivado: build\fpga\nexys_top.bit
.\fpga\build.ps1 leds -Program         # build and load it onto the board over USB
.\fpga\build.ps1 queens -Part xc7a50ticsg324-1L    # Nexys A7-50T
```

Any program in `fpga/sw/`, `sw/` or `sw/c/` works. Needs Vivado (the free ML
Standard edition) with its `bin` folder on the PATH, plus the RISC-V gcc
toolchain and iverilog that the rest of the project uses.

Reports land in `build/fpga/`: `timing.rpt` (the worst setup slack must be
≥ 0, or the core may misbehave on the board) and `utilization.rpt`. If timing
fails, lower the clock: raise `CLK_DIV` in `nexys_top.sv`.

## Memory map

| Address | |
|---|---|
| `0x0000_0000` | 16 KB RAM: the program in imem, a copy in dmem for `.data` |
| `0x0000_0100` | RESULT (w): `1` = PASS, else FAIL. Shown on the display and LD16 |
| `0x1000_0000` | LED (r/w): LD15..LD0 |
| `0x1000_0004` | SW (r): SW15..SW0 |
| `0x1000_0008` | SEG (r/w): 8 hex digits on the 7-segment display |

## What the board shows

- **LD16:** green = the program stored 1 to RESULT (PASS), red = it stored something else
- **LD17:** blue = halted on `ecall` / `ebreak`, red = hit an illegal instruction
  (also what happens if a program runs off its end: unused memory is 0)
- **7-segment display:** the SEG register, or the last RESULT
- **CPU_RESET** (red button): restarts the program

The `sw/` test programs, C programs (through `crt0.S`) and riscv-tests all
store their result to RESULT, so they show PASS or FAIL without changes.
