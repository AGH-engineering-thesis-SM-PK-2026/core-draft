#!/bin/sh

riscv-none-elf-as -march=rv32i -mabi=ilp32 "$@"