.global _start
.text

_start:
	li a1, 1
forever:
	addi a1, a1, 1
	j forever