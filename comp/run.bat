@echo off
docker build -t riscv-comp .
docker history riscv-comp > buildlog.txt
docker run -it --rm -v %CD%/mnt:/home/dev/riscv riscv-comp