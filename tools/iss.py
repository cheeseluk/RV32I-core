"""RV32I instruction-set simulator: the reference model for the core.

Runs a hex file (one 32-bit word per line, from bin2hex.py) and writes one
trace line per instruction, in the same format as core_tb.sv:

    pc instr [xN=value] [mem[addr]=data]

It sets up memory and stops the same way core_tb does, so the two traces can
be diffed line by line with trace_diff.py:
  - the hex is loaded into a separate imem and dmem of MEM_WORDS words each,
    and addresses wrap around at that size;
  - it stops on ecall/ebreak (result = x3), a store to RESULT_ADDR
    (result = the stored word), an illegal instruction, or a timeout;
  - result 1 = PASS, (n << 1) | 1 = FAIL test #n.

The model is written from the ISA spec, not from the RTL, so a bug in one
is unlikely to be repeated in the other.

Usage: python tools/iss.py prog.hex [--trace FILE] [--verbose] [--max-steps N]
"""
import argparse
import sys

MEM_WORDS = 4096
RESULT_ADDR = 0x100
MASK = 0xFFFF_FFFF


def sext(value, bits):
    """Sign-extend the low `bits` bits of value to a Python int."""
    value &= (1 << bits) - 1
    return value - (1 << bits) if value >> (bits - 1) else value


def signed(v):
    return sext(v, 32)


def load_hex(path):
    words = []
    for line in open(path):
        line = line.split("//")[0].strip()
        if line:
            words.append(int(line, 16))
    if len(words) > MEM_WORDS:
        sys.exit(f"{path}: {len(words)} words does not fit in {MEM_WORDS}")
    return words


class Iss:
    def __init__(self, words):
        self.imem = words + [None] * (MEM_WORDS - len(words))   # None = never loaded
        self.dmem = bytearray(MEM_WORDS * 4)
        for i, w in enumerate(words):
            self.dmem[4 * i:4 * i + 4] = w.to_bytes(4, "little")
        self.x = [0] * 32
        self.pc = 0

    # ---- data memory: byte addressed, wraps like the RTL ------------------
    def read(self, addr, size):
        a = addr % (MEM_WORDS * 4)
        return int.from_bytes(self.dmem[a:a + size], "little")

    def write(self, addr, size, value):
        a = addr % (MEM_WORDS * 4)
        self.dmem[a:a + size] = (value & ((1 << (8 * size)) - 1)).to_bytes(size, "little")

    def step(self):
        """Execute one instruction. Returns (trace line, stop reason or None)."""
        pc = self.pc
        inst = self.imem[(pc >> 2) % MEM_WORDS]
        if inst is None:
            return f"{pc:08x} xxxxxxxx", f"FAIL illegal instruction xxxxxxxx at pc {pc:08x}"

        opcode = inst & 0x7F
        rd = (inst >> 7) & 0x1F
        funct3 = (inst >> 12) & 0x7
        rs1 = (inst >> 15) & 0x1F
        rs2 = (inst >> 20) & 0x1F
        funct7 = inst >> 25

        imm_i = sext(inst >> 20, 12)
        imm_s = sext(((inst >> 25) << 5) | ((inst >> 7) & 0x1F), 12)
        imm_b = sext((((inst >> 31) & 1) << 12) | (((inst >> 7) & 1) << 11)
                     | (((inst >> 25) & 0x3F) << 5) | (((inst >> 8) & 0xF) << 1), 13)
        imm_u = inst & 0xFFFF_F000
        imm_j = sext((((inst >> 31) & 1) << 20) | (((inst >> 12) & 0xFF) << 12)
                     | (((inst >> 20) & 1) << 11) | (((inst >> 21) & 0x3FF) << 1), 21)

        a, b = self.x[rs1], self.x[rs2]
        next_pc = (pc + 4) & MASK
        wb = None            # value written to rd
        store = None         # (addr, size, value)
        stop = None

        if opcode == 0x33:                                   # R-type
            if funct7 not in (0x00, 0x20) or (funct7 == 0x20 and funct3 not in (0, 5)):
                stop = "illegal"
            else:
                wb = self.alu(funct3, funct7 == 0x20, a, b)
        elif opcode == 0x13:                                 # I-type ALU
            alt = funct3 == 5 and (inst >> 30) & 1           # srai; else bit 30 is imm
            wb = self.alu(funct3, alt, a, imm_i & MASK)
        elif opcode == 0x03:                                 # loads
            addr = (a + imm_i) & MASK
            if funct3 == 0:   wb = sext(self.read(addr, 1), 8)
            elif funct3 == 1: wb = sext(self.read(addr, 2), 16)
            elif funct3 == 2: wb = self.read(addr, 4)
            elif funct3 == 4: wb = self.read(addr, 1)
            elif funct3 == 5: wb = self.read(addr, 2)
            else: stop = "illegal"
        elif opcode == 0x23:                                 # stores
            if funct3 > 2:
                stop = "illegal"
            else:
                store = ((a + imm_s) & MASK, 1 << funct3, b)
        elif opcode == 0x63:                                 # branches
            taken = {0: a == b, 1: a != b,
                     4: signed(a) < signed(b), 5: signed(a) >= signed(b),
                     6: a < b, 7: a >= b}.get(funct3)
            if taken is None:
                stop = "illegal"
            elif taken:
                next_pc = (pc + imm_b) & MASK
        elif opcode == 0x6F:                                 # jal
            wb = pc + 4
            next_pc = (pc + imm_j) & MASK
        elif opcode == 0x67:                                 # jalr
            wb = pc + 4
            next_pc = (a + imm_i) & MASK & ~1
        elif opcode == 0x37:                                 # lui
            wb = imm_u
        elif opcode == 0x17:                                 # auipc
            wb = pc + imm_u
        elif opcode == 0x0F:                                 # fence: nop
            pass
        elif opcode == 0x73 and funct3 == 0:                 # ecall / ebreak
            stop = "halt"
        else:
            stop = "illegal"

        if stop == "illegal":
            return f"{pc:08x} {inst:08x}", f"FAIL illegal instruction {inst:08x} at pc {pc:08x}"

        line = f"{pc:08x} {inst:08x}"
        if wb is not None and rd != 0:
            self.x[rd] = wb & MASK
            line += f" x{rd}={self.x[rd]:08x}"
        if store:
            addr, size, value = store
            line += f" mem[{addr:08x}]={value & ((1 << 8 * size) - 1):0{2 * size}x}"
            if addr == RESULT_ADDR:
                stop = verdict(value)
            self.write(addr, size, value)

        if stop == "halt":
            stop = verdict(self.x[3])
        else:
            self.pc = next_pc
        return line, stop

    @staticmethod
    def alu(funct3, alt, a, b):
        sh = b & 0x1F
        if funct3 == 0: return (a - b) if alt else (a + b)
        if funct3 == 1: return a << sh
        if funct3 == 2: return int(signed(a) < signed(b))
        if funct3 == 3: return int(a < b)
        if funct3 == 4: return a ^ b
        if funct3 == 5: return (signed(a) >> sh) if alt else (a >> sh)
        if funct3 == 6: return a | b
        return a & b


def verdict(code):
    code &= MASK
    return "PASS" if code == 1 else f"FAIL test #{code >> 1} (result = {code:08x})"


def main():
    p = argparse.ArgumentParser(description="RV32I reference model")
    p.add_argument("hex")
    p.add_argument("--trace", help="write the trace to this file")
    p.add_argument("--verbose", action="store_true", help="print the trace")
    p.add_argument("--max-steps", type=int, default=100000)
    args = p.parse_args()

    iss = Iss(load_hex(args.hex))
    out = open(args.trace, "w") if args.trace else None
    result = None
    for _ in range(args.max_steps):
        line, result = iss.step()
        if args.verbose:
            print(line)
        if out:
            out.write(line + "\n")
        if result:
            break
    else:
        result = f"FAIL timeout after {args.max_steps} steps (pc {iss.pc:08x})"
    if out:
        out.close()
    print(result)


if __name__ == "__main__":
    main()
