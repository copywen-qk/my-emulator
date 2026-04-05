CROSS_COMPILE = riscv64-unknown-elf-
CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump

CFLAGS = -march=rv32i -mabi=ilp32 -nostdlib

all: dummy.bin dummy.txt

dummy.elf: dummy.S link.ld
	$(CC) $(CFLAGS) -T link.ld dummy.S -o dummy.elf

dummy.bin: dummy.elf
	$(OBJCOPY) -S -O binary dummy.elf dummy.bin

dummy.txt: dummy.elf
	$(OBJDUMP) -d dummy.elf > dummy.txt

clean:
	rm -f dummy.elf dummy.bin dummy.txt

.PHONY: all clean
