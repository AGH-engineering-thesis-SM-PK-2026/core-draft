.extern main

.section .text.boot, "ax", @progbits
.global _start
_start:
    li sp, 0x00002000
    call main
_end:
    j _end
