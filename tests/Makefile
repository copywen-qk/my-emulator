CROSS_COMPILE = riscv64-unknown-elf-
CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump

CFLAGS = -march=rv32im -mabi=ilp32 -nostdlib -O2

all: dummy.bin dummy.txt vga_test.bin flappy.bin simple_test.bin minimal_test.bin pipeline_test.bin pipeline_y86_test.bin simple_pipeline_test.bin forwarding_test.bin pipeline_simple_flow.bin

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

flappy.elf: flappy.c link.ld
	$(CC) $(CFLAGS) -T link.ld flappy.c -o flappy.elf

flappy.bin: flappy.elf
	$(OBJCOPY) -S -O binary flappy.elf flappy.bin

simple_test.elf: simple_test.c link.ld
	$(CC) $(CFLAGS) -T link.ld simple_test.c -o simple_test.elf

simple_test.bin: simple_test.elf
	$(OBJCOPY) -S -O binary simple_test.elf simple_test.bin

minimal_test.elf: minimal_test.c link.ld
	$(CC) $(CFLAGS) -T link.ld minimal_test.c -o minimal_test.elf

minimal_test.bin: minimal_test.elf
	$(OBJCOPY) -S -O binary minimal_test.elf minimal_test.bin

pipeline_test.elf: pipeline_test.c link.ld
	$(CC) $(CFLAGS) -T link.ld pipeline_test.c -o pipeline_test.elf

pipeline_test.bin: pipeline_test.elf
	$(OBJCOPY) -S -O binary pipeline_test.elf pipeline_test.bin

pipeline_y86_test.elf: pipeline_y86_test.c link.ld
	$(CC) $(CFLAGS) -T link.ld pipeline_y86_test.c -o pipeline_y86_test.elf

pipeline_y86_test.bin: pipeline_y86_test.elf
	$(OBJCOPY) -S -O binary pipeline_y86_test.elf pipeline_y86_test.bin

simple_pipeline_test.elf: simple_pipeline_test.c link.ld
	$(CC) $(CFLAGS) -T link.ld simple_pipeline_test.c -o simple_pipeline_test.elf

simple_pipeline_test.bin: simple_pipeline_test.elf
	$(OBJCOPY) -S -O binary simple_pipeline_test.elf simple_pipeline_test.bin

forwarding_test.elf: forwarding_test.c link.ld
	$(CC) $(CFLAGS) -T link.ld forwarding_test.c -o forwarding_test.elf

forwarding_test.bin: forwarding_test.elf
	$(OBJCOPY) -S -O binary forwarding_test.elf forwarding_test.bin

pipeline_simple_flow.elf: pipeline_simple_flow.c link.ld
	$(CC) $(CFLAGS) -T link.ld pipeline_simple_flow.c -o pipeline_simple_flow.elf

pipeline_simple_flow.bin: pipeline_simple_flow.elf
	$(OBJCOPY) -S -O binary pipeline_simple_flow.elf pipeline_simple_flow.bin

clean:
	rm -f *.elf *.bin *.txt

.PHONY: all clean
