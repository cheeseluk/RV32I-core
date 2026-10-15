# Board demo: the LEDs follow the switches, and the 7-segment display counts up.
# Runs forever. Addresses are nexys_top.sv's memory map.

#define IO_BASE 0x10000000
#define LED     0
#define SW      4
#define SEG     8

    .globl _start
_start:
    li   s0, IO_BASE
    li   s1, 0                  # counter
loop:
    lw   t0, SW(s0)
    sw   t0, LED(s0)
    addi s1, s1, 1
    srli t1, s1, 20             # the loop runs ~4 million times a second at 25 MHz,
    sw   t1, SEG(s0)            # so show counter / 2^20: about 4 counts a second
    j    loop
