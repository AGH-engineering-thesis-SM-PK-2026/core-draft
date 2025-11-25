.global _start
.text

_start:
	li a1, 1 /* counter */
    li a2, 1 /* target */
loop:
    bne a1, a2, end /* one iter */
    addi a2, a2, 1
    j loop
end:
	j end
