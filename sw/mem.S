# Step 7.5: byte and halfword loads and stores (plus lw/sw).
#include "check.h"

    .globl _start
_start:
    li   x10, 0x400          # scratch area in dmem, away from 0x100

    # sw / lw
    li   x5, 0x12345678
    sw   x5, 0(x10)
    lw   x6, 0(x10);    CHECK x6, 0x12345678

    # loads from each byte lane, signed and unsigned
    li   x5, 0x80F17F82
    sw   x5, 4(x10)
    lb   x6, 4(x10);    CHECK x6, 0xFFFFFF82
    lb   x6, 5(x10);    CHECK x6, 0x7F
    lb   x6, 6(x10);    CHECK x6, 0xFFFFFFF1
    lb   x6, 7(x10);    CHECK x6, 0xFFFFFF80
    lbu  x6, 4(x10);    CHECK x6, 0x82
    lbu  x6, 7(x10);    CHECK x6, 0x80
    lh   x6, 4(x10);    CHECK x6, 0x7F82
    lh   x6, 6(x10);    CHECK x6, 0xFFFF80F1
    lhu  x6, 4(x10);    CHECK x6, 0x7F82
    lhu  x6, 6(x10);    CHECK x6, 0x80F1

    # sb only changes its own byte
    sw   x0, 8(x10)
    li   x5, 0x123456AA
    sb   x5, 9(x10)
    lw   x6, 8(x10);    CHECK x6, 0x0000AA00
    li   x5, 0xBB
    sb   x5, 11(x10)
    lw   x6, 8(x10);    CHECK x6, 0xBB00AA00
    sb   x5, 8(x10)
    lw   x6, 8(x10);    CHECK x6, 0xBB00AABB

    # sh only changes its own half
    li   x5, -1
    sw   x5, 12(x10)
    li   x5, 0x55551234
    sh   x5, 14(x10)
    lw   x6, 12(x10);   CHECK x6, 0x1234FFFF
    sh   x0, 12(x10)
    lw   x6, 12(x10);   CHECK x6, 0x12340000

    # negative offsets
    addi x11, x10, 20
    li   x5, 0xCAFEF00D
    sw   x5, -4(x11)
    lw   x6, 16(x10);   CHECK x6, 0xCAFEF00D
    lh   x6, -2(x11);   CHECK x6, 0xFFFFCAFE

    # a load into x0 changes nothing
    lw   x0, 0(x10);    CHECK x0, 0

    jal  x0, pass
    RESULT
