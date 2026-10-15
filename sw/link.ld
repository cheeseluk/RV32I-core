/* Memory layout for the single-cycle core: code at 0, data right after.
   The same image is loaded into imem and dmem, so .data addresses work in
   both. Used by sw/*.S, sw/c/*.c and the riscv-tests.
   The stack starts at the top of dmem (see sw/c/crt0.S) and grows down. */
OUTPUT_ARCH("riscv")
ENTRY(_start)

SECTIONS
{
    . = 0x00000000;
    .text : { *(.text.init) *(.text) *(.text.*) }
    . = ALIGN(16);
    .data : { *(.data) *(.data.*) *(.sdata) *(.sdata.*)
              *(.rodata) *(.rodata.*) *(.srodata) *(.srodata.*) }
    /* .bss is not in the hex file, so crt0.S zeroes __bss_start.._end */
    . = ALIGN(4);
    __bss_start = .;
    .bss  : { *(.bss) *(.bss.*) *(.sbss) *(.sbss.*) *(COMMON) }
    . = ALIGN(4);
    _end = .;
}
