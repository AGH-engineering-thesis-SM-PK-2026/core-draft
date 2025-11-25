.global _start
.text

/* store word/load word */

_start:
	li s0, 0x1000 /* data mem start */
	li t3, 0xaaaaaaaa
    li t4, 0x55555555
    
    sw t3, 4(s0)
    sw t4, 8(s0)
    
    lw a0, 4(s0) /* a0 <- t3 */
    lw a1, 8(s0) /* a1 <- t4 */
end:
	j end