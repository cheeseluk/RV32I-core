# Results: single-cycle RV32I core

Measurements of the single-cycle design, taken on 2026-10-15. They are the
baseline for later changes, such as the M extension or a pipeline.

## Summary

| | |
|---|---|
| ISA | RV32I (all 40 base instructions; no CSRs or traps) |
| Microarchitecture | Single-cycle, separate instruction and data memories |
| rv32ui riscv-tests | **40 / 40 pass** |
| Instructions checked against the reference model | **536,472, 0 mismatches** |
| Benchmark (N-Queens, C) | 524,217 instructions, CPI 1.0, 21.0 ms at 25 MHz |
| FPGA | Nexys A7-100T (xc7a100tcsg324-1), 25 MHz |
| Resources | 3,894 LUTs (6.1%), 1,177 FFs (0.9%), 0 block RAM, 0 DSP |
| Timing | WNS +12.458 ns at 25 MHz, so an estimated maximum clock of about 36 MHz |
| Power (Vivado estimate) | 0.231 W |
| RTL size | 465 lines (core), 192 lines (FPGA wrapper) |

---

## 1. Verification

### Unit testbenches (`tb/`, run with `sim.ps1`)

| Testbench | Covers | Result |
|---|---|---|
| `alu_tb` | All 10 RV32I ALU operations; signed vs unsigned compare; shift amounts above 31 (only the low 5 bits count); arithmetic right shift of negative values | PASS |
| `regfile_tb` | Reset; writing and reading back all 32 registers through both read ports; writes to `x0` ignored | PASS |
| `imm_gen_tb` | All 5 immediate formats, including the largest and smallest values and alternating-bit patterns that catch swapped fields | PASS |
| `control_tb` | Control signals for an instruction from every opcode group, `srai` vs `slli`, a CSR instruction, all-zeros and all-ones words (must be illegal) | PASS |
| `branch_unit_tb` | All 6 conditions over edge values (0, 1, −1, `INT_MIN`, `INT_MAX`), plus cases where signed and unsigned disagree | PASS |
| `lsu_tb` | Byte enables and lane placement for `sb`/`sh`/`sw` at every offset; sign and zero extension for all 5 loads | PASS |
| `imem_tb`, `dmem_tb` | Loading from a file; word addressing; byte-enable writes | PASS |

### Programs, compared instruction by instruction with `tools/iss.py`

| Program | Tests | Instructions run | Image size (words) |
|---|---|---:|---:|
| `first.S` | First program: `add`, `sub`, `lw`, `sw`, `beq` | 9 | 12 |
| `alu.S` | Every register-register and immediate ALU instruction | 167 | 210 |
| `branch.S` | All 6 branches, taken and not taken, signed/unsigned edge cases, a backward branch | 67 | 72 |
| `jump.S` | `jal`, `jalr`, link registers, clearing bit 0 of the target | 58 | 68 |
| `mem.S` | Byte, halfword and word loads and stores, with sign extension | 114 | 138 |
| `upper.S` | `lui`, `auipc` | 44 | 57 |
| `system.S` | `fence` is a no-op; `ebreak` halts the core | 8 | 13 |
| `queens.c` | Benchmark (section 2) | 524,217 | 153 |
| **rv32ui suite** | 40 tests: shortest `simple`, 3 instructions; longest `ld_st`, 925 | 11,788 | — |
| **Total** | | **536,472** | |

The rv32ui suite comes from riscv-tests at commit `d7e86f7` (2026-10-14).
Two of its 42 tests are excluded: `fence_i` (needs the Zifencei extension and self-modifying code)
and `ma_data` (needs misaligned access).

### Board-level simulation (`fpga/nexys_top_tb.sv`)

| Program | Expected | Observed (read back from the display pins) |
|---|---|---|
| `leds` with switches = `a5a5` | LEDs = `a5a5` | LEDs = `a5a5` |
| `alu`, `first`, `queens` | display `00000001`, LD16 green | as expected |
| Program that stores FAIL code 5 | display `00000005`, LD16 red | as expected |
| Program containing an illegal instruction | LD17 red | as expected |

The same simulation also ran in Vivado's simulator (XSim) with matching output.
`queens` was then run on the board itself: the display showed `00000001` (PASS).

---

## 2. Benchmark: N-Queens

`sw/c/queens.c` counts every solution to the N-Queens problem for N = 1 to 8 by recursive
backtracking, and checks the counts against the known answers (1, 0, 0, 2, 10, 4, 40, 92).
It also keeps a checksum that needs a variable multiply. RV32I has no `mul` instruction,
so GCC calls `__mulsi3` from libgcc.
Built with `riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -O2`.

### Performance

| | |
|---|---:|
| Instructions | 524,217 |
| Cycles | 524,217 |
| CPI | 1.00 |
| Run time at 25 MHz | 20.97 ms |
| Run time at the estimated maximum clock (36.3 MHz) | 14.4 ms |
| Throughput at 25 MHz | 25 MIPS |

Instruction and cycle counts come from simulation. On a single-cycle core they are equal by construction.

### Instruction mix

| Class | Count | Share |
|---|---:|---:|
| ALU, immediate (`addi`, `slli`, …) | 234,393 | 44.7% |
| Conditional branch | 124,643 | 23.8% |
| Load | 62,146 | 11.9% |
| Store | 48,453 | 9.2% |
| ALU, register-register | 39,557 | 7.5% |
| `jalr` | 7,888 | 1.5% |
| `auipc` | 3,946 | 0.8% |
| `lui` | 3,144 | 0.6% |
| `jal` | 47 | <0.1% |

### Control flow

| | |
|---|---:|
| Branches taken | 85,942 of 124,643 (69.0%) |
| Function calls / returns | 3,944 / 3,944 |
| Maximum call depth | 10 frames (`main` + 9 levels of `solve`) |

### Time by function

| Function | Instructions | Share |
|---|---:|---:|
| `solve` | 334,329 | 63.8% |
| `__mulsi3` (software multiply) | 189,600 | 36.2% |
| `_start` (stack setup, clearing `.bss`) | 199 | <0.1% |
| `main` | 89 | <0.1% |

### Memory footprint

| Section | Size |
|---|---:|
| `.text` | 564 B |
| `.data` / `.rodata` | 36 B |
| `.bss` | 188 B |
| Stack (deepest point) | 592 B |

### What this suggests for later designs

- **M extension:** a hardware multiplier would remove most of the 36% spent in `__mulsi3`.
- **Pipelining:** 25% of instructions change control flow, and 69% of branches are taken.
  A 5-stage pipeline without branch prediction would waste about 2 cycles on each taken branch or jump:
  roughly 94k × 2 ≈ 190k cycles. Add stalls where an instruction uses the result of the load just before it (loads are 12% of instructions).
  The expected CPI is 1.4 or more, in exchange for a much shorter clock period.
- **Branch prediction:** most taken branches are loop back-edges. Even a fixed rule (predict backward branches taken) would recover most of the branch cost.

---

## 3. FPGA implementation

**Setup:**
- **Board:** Digilent Nexys A7-100T (xc7a100tcsg324-1, speed grade -1).
- **Tools:** Vivado 2026.1, run in non-project mode with default settings (`fpga/build.tcl`).
- **Clock:** 25 MHz, from an MMCM (100 MHz × 10 ÷ 40).
- **Program:** `queens`, built into the bitstream.

### Timing

| Check | Worst slack | Total violation | Failing / total endpoints |
|---|---:|---:|---:|
| Setup | **+12.458 ns** | 0.000 ns | 0 / 23,903 |
| Hold | +0.122 ns | 0.000 ns | 0 / 23,903 |
| Pulse width | +3.000 ns | 0.000 ns | 0 / 3,230 |

**Critical path:** from `cpu/dp/pc_reg[7]` to `cpu/dp/rf/x_reg[25][0]`, over a requirement of 40.000 ns.

| | |
|---|---|
| Data path delay | 27.403 ns: 5.147 ns of logic (18.8%) and 22.256 ns of routing (81.2%) |
| Logic levels | 18 (LUT2 ×1, LUT5 ×2, LUT6 ×9, MUXF7 ×4, MUXF8 ×1, RAMS64E ×1) |
| Route | PC → instruction ROM (merged into the decode logic) → register file read → address computation → data RAM read (`RAMS64E` + `MUXF7`/`MUXF8`) → load alignment → register file write |
| Estimated maximum clock | 1 / (40 − 12.458) ns ≈ **36.3 MHz** |

This is the classic single-cycle critical path: one cycle must cover two memory
reads and the ALU, and most of the delay is in the wiring between them.

### Utilization

| Resource | Used | Available | Share |
|---|---:|---:|---:|
| Slice LUTs | 3,894 | 63,400 | 6.14% |
| … LUT as logic | 1,846 | 63,400 | 2.91% |
| … LUT as distributed RAM | 2,048 | 19,000 | 10.78% |
| Slice registers (FFs) | 1,177 | 126,800 | 0.93% |
| F7 / F8 muxes | 1,364 / 607 | 31,700 / 15,850 | 4.30% / 3.83% |
| CARRY4 | 63 | 15,850 | 0.40% |
| Slices | 1,282 | 15,850 | 8.09% |
| Block RAM tiles | 0 | 135 | 0% |
| DSP48 | 0 | 240 | 0% |
| Bonded I/O | 56 | 210 | 26.67% |
| BUFG | 1 | 32 | 3.13% |
| MMCM | 1 | 6 | 16.67% |

### Utilization by module

| Instance | LUTs | of which LUT-RAM | FFs |
|---|---:|---:|---:|
| `nexys_top` (total) | 3,894 | 2,048 | 1,177 |
| `cpu/dp` (datapath, including the merged instruction ROM) | 1,678 | 0 | 1,024 |
| `cpu/dp/rf` (register file) | 1,606 | 0 | 992 |
| `dmem_u` (16 KB data RAM) | 2,183 | 2,048 | 0 |
| top-level I/O, reset, display | 16 | 0 | 136 |

- **Register file:** 992 flip-flops = 31 registers × 32 bits (`x0` needs no storage).
  It is built from flip-flops rather than LUT-RAM because the reset clears every register.
- **Data memory:** 2,048 `RAMS64E` primitives = 4,096 words × 32 bits ÷ 64 bits per primitive.
  The 135 extra LUTs select between the RAM banks on reads.
- **Instruction memory:** has no entry of its own. Its contents are constants, so synthesis
  merged it into the decode logic inside the datapath.

### Power (Vivado estimate)

| Component | Power |
|---|---:|
| **Total on-chip** | **0.231 W** |
| Device static | 0.097 W |
| Dynamic | 0.134 W |
| … MMCM | 0.106 W |
| … signals | 0.018 W |
| … slice logic | 0.006 W |
| … I/O | 0.003 W |
| … clocks | 0.002 W |
| Junction temperature | 26.1 °C |

This is a vectorless estimate (Vivado rates its confidence as Low), made without
simulated switching activity. The clock generator (MMCM) accounts for most of the dynamic power.

### The numbers depend on the program

The program is part of the bitstream, and synthesis optimizes the logic around it.
The same design built with the small `leds` demo instead:

| | `queens` | `leds` |
|---|---:|---:|
| LUTs | 3,894 | 2,982 |
| FFs | 1,177 | 315 |
| Setup slack (WNS) | +12.458 ns | +17.013 ns (+16.215 ns in a GUI project build) |

`leds` writes to only a handful of registers, so synthesis removed most of the register file.
Use the `queens` figures as representative of the core.
A version with a writable instruction memory (for example, loaded by a bootloader) would not have this effect.

---

## 4. Code size

| Area | Files | Lines |
|---|---|---:|
| Core RTL | `rtl/*.sv` (11 files) | 465 |
| FPGA wrapper | `fpga/nexys_top.sv`, `fpga/sevenseg.sv` | 192 |
| Testbenches | `tb/*.sv`, `fpga/nexys_top_tb.sv` | 846 |
| Reference model and tools | `tools/iss.py`, `trace_diff.py`, `bin2hex.py` | 259 |

## 5. Tools

| Tool | Version |
|---|---|
| Icarus Verilog | 13.0 |
| Verilator (lint) | 5.050 |
| Vivado | 2026.1 |
| RISC-V GCC | 16.1.0 (`riscv64-unknown-elf`) |
| Python | 3.14.4 |

## Reproducing

```powershell
.\run_tests.ps1                  # rv32ui suite
.\run_prog.ps1                   # sw\ programs; traces go to build\sw\*.core.trace
.\fpga\build.ps1 queens -Sim     # board-level simulation
.\fpga\build.ps1 queens          # Vivado build; reports go to build\fpga\*.rpt
```

The instruction mix and per-function figures come from `build\sw\queens.core.trace`,
matched against the function addresses in `build\sw\queens.dump`.
