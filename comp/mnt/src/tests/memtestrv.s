.global _start
.text

/* MemTestRV */
.equ MEMSTA, 0x1000
.equ MEMEND, 0x2000

/* alternate between 2 patterns */
patterna:
    /* args: a0, a1 - patterns to test (alternate between them) */
    /* rets: a0 - 1 if ok, 0 bad mem; a1 - address of bad cell */
	li t3, MEMSTA /* data mem start */
    li t4, MEMEND /* data mem end */

/* write pattern */
_patterna_wloop:
    beq t3, t4, _patterna_rloop
    sw a0, 0(t3)
    sw a1, 4(t3)
    addi t3, t3, 8 /* next pair of cells */
    j _patterna_wloop

	li t3, MEMSTA

/* read pattern */
_patterna_rloop:
    beq t3, t4, _patterna_ok
    lw t5, 0(t3)
    lw t6, 4(t3)
    bne t5, a0, _patterna_bad0 /* on pattern mismatch */
    bne t6, a1, _patterna_bad1
    addi t3, t3, 8 /* next pair of cells */
    j _patterna_wloop

_patterna_bad0:
    li a0, 0
    addi a1, t3, 0 
    ret

_patterna_bad1:
    li a0, 0
    addi a1, t3, 4
    ret

_patterna_ok:
    li a0, 1
    li a1, 0
    ret

_start:
	li a0, 0xaaaaaaaa
    li a1, 0x55555555
    
    call patterna
end:
	j end