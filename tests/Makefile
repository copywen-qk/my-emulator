CROSS_COMPILE = riscv64-unknown-elf-
CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump

CFLAGS = -march=rv32im -mabi=ilp32 -nostdlib -O2

all: dummy.bin dummy.txt vga_test.bin

dummy.elf: dummy.S link.ld
	$(CC) $(CFLAGS) -T link.ld dummy.S -o dummy.elf

dummy.bin: dummy.elf
	$(OBJCOPY) -S -O binary dummy.elf dummy.bin

dummy.txt: dummy.elf
	$(OBJDUMP) -d dummy.elf > dummy.txt

vga_test.elf: vga_test.c link.ld
	$(CC) $(CFLAGS) -T link.ld vga_test.c -o vga_test.elf

vga_test.bin: vga_test.elf
	$(OBJCOPY) -S -O binary vga_test.elf vga_test.bin

clean:
	rm -f *.elf *.bin *.txt

.PHONY: all clean
