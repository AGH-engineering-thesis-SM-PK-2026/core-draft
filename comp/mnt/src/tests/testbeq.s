.global _start
.text

_start:
	li a1, 1 /* counter */
    li a2, 9 /* target */
loop:
    beq a1, a2, end /* 8 iters */
    addi a2, a2, 1
    j loop
end:
	j end
