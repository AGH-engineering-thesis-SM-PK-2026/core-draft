#!/bin/sh

echo build boot.o
riscv-none-elf-as -march=rv32i -mabi=ilp32 -c -o out/boot.o src/boot.s
echo build $2
riscv-none-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding -O0 -g -T link.ld -o $2 out/boot.o $1
echo done