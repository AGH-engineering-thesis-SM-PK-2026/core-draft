FROM alpine:latest@sha256:a8560b36e8b8210634f77d9f7f9efd7ffa463e380b75e2e74aff4511df3ef88c

RUN apk add --no-cache bash nano binutils-riscv-none-elf gcc-riscv-none-elf 

RUN adduser -D dev
USER dev
WORKDIR /home/dev

RUN echo 'alias rvas=/home/dev/riscv/misc/as.sh' > .bashrc
RUN echo 'alias rvcc=/home/dev/riscv/misc/cc.sh' >> .bashrc
RUN echo 'alias rvdump=/home/dev/riscv/misc/dump.sh' >> .bashrc


CMD [ "bash" ]