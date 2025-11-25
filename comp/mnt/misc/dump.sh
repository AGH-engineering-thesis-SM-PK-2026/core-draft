#!/bin/sh

riscv-none-elf-objdump -d $1 | grep -Eo ':\s+[0-9a-f]{8}' | cut -f 2