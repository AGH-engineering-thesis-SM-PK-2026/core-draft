.global _start
.text

_start:
	/* set reg. li */
    li a1, 0xaa
    /* set reg. lui + addiw */
    li a1, 0xffff
    /* set reg. addiw + slli */
	li a1, 0xffffffff
	/* add/sub/neg to same reg. */
    li a1, 0x40 /* a1 <- 64 */
    addi a1, a1, 0x40 /* a1 <- 128 */
    add a1, a1, a1  /* a1 <- 256 */
    sub a1, a1, a1  /* a1 <- 128 */
    neg a1, a1      /* a1 <- -128 */
    add a1, a1, a1  /* a1 <- 0 */
	/* and/or/not/xor */
	li a2, 0xaa /* a2 <- 0b10101010 */
	li a3, 0x55 /* a2 <- 0b01010101 */
    and a4, a2, a3 /* a4 <- 0b00000000 */
    or a5, a2, a3 /* a5 <- 0b11111111 */
    xor a6, a2, a2 /* a4 <- 0b00000000 */
    xor a7, a2, a3 /* a5 <- 0b11111111 */
    andi a2, a2, 0x0f /* a2 <- 0b00001010 */
    ori a3, a3, 0x0f /* a3 <- 0b01011111 */
    xori a2, a2, 0xf0 /* a2 <- 0b11111010 */
    xori a3, a3, 0x0f /* a3 <- 0b01010000 */
    not a3, a3 /* a3 <- 0b10100000 */
    /* sll/srl/sra */
    li a1, 16
    li a2, 0x80ffffff
    sll a3, a2, a1 /* a3 <- 0xffff0000 */
    srl a4, a2, a1 /* a4 <- 0x000080ff */
    sra a5, a2, a1 /* a5 <- 0xffff80ff */
    li a2, 0x00008000
    slli a3, a2, 8 /* a3 <- 0x00800000 */
    srli a4, a2, 8 /* a4 <- 0x00000080 */
    srai a5, a2, 8 /* a5 <- 0x00000080 */
    li a2, 0xffffffff
    slli a3, a2, 31 /* a3 <- 0x00000001 */
    srli a4, a2, 31 /* a4 <- 0x80000000 */
    srai a5, a2, 31 /* a5 <- 0xffffffff */
    li a6, 42       /* a6 <- 0b00101010 */
    li a7, -42      /* a7 <- 0b1111..111111010110 */
	srli a2, a6, 2  /* a2 <- 0b1010 */
	srai a3, a6, 2  /* a3 <- 0b1010 */
	srli a4, a7, 2  /* a4 <- 0b00111111111111111111111111110101 */
	srai a5, a7, 2  /* a5 <- 0b1111..11110101 */
end:
	j end