// Helpers shared by the sw/*.S test programs.
//
// x28 counts checks and x29 is scratch, so tests should leave them alone.
// The program ends with RESULT, which stores to 0x100 the way core_tb.sv
// expects: 1 = PASS, (n << 1) | 1 = FAIL on check #n.
//
// CHECK only uses addi, li, beq and jal, so it works on the book's subset.
// (li of a value outside -2048..2047 also needs lui.)

#define RESULT_ADDR 0x100

// Fail unless reg == val (a constant)
.macro CHECK reg, val
    addi x28, x28, 1
    li   x29, \val
    beq  \reg, x29, 101f
    jal  x0, fail
101:
.endm

// Fail unless reg == other register
.macro CHECKR reg, other
    addi x28, x28, 1
    beq  \reg, \other, 102f
    jal  x0, fail
102:
.endm

// Absolute address of a label (lui + addi, not pc-relative)
.macro ABS reg, sym
    lui  \reg, %hi(\sym)
    addi \reg, \reg, %lo(\sym)
.endm

.macro RESULT
pass:
    addi x29, x0, 1
    sw   x29, RESULT_ADDR(x0)
103: jal x0, 103b
fail:
    slli x28, x28, 1
    ori  x28, x28, 1
    sw   x28, RESULT_ADDR(x0)
104: jal x0, 104b
.endm
