.global _start
.text

mysub:
	/* a0, a1 - function args */
    sub a0, a0, a1 /* to return */
    jalr zero, ra, 0 /* return: ra = pc + 4 at call site */

_start:
	li a0, 1
    li a1, 2
    call mysub
    jal ra, mysub /* same as call */
end:
	j end
	