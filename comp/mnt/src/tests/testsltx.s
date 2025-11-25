.global _start
.text

/* set less than */

_start:
	li t3, -1
    li t4, 1
	
    slt a0, t3, t4  /* a0 <- 1 */
    sltu a1, t3, t4 /* a1 <- 0 */
    slti a2, t3, 1  /* a2 <- 1 */
    sltiu a3, t3, 1 /* a3 <- 0 */
end:
	j end