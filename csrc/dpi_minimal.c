// Minimal DPI implementation for pipeline testing
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MEM_SIZE (1024 * 1024) // 1MB memory
static unsigned char memory[MEM_SIZE];

long load_image(const char *img_file) {
    FILE *fp = fopen(img_file, "rb");
    if (!fp) {
        fprintf(stderr, "Failed to open image file: %s\n", img_file);
        return -1;
    }
    
    fseek(fp, 0, SEEK_END);
    long size = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    
    if (size > MEM_SIZE) {
        fprintf(stderr, "Image too large: %ld bytes (max: %d)\n", size, MEM_SIZE);
        fclose(fp);
        return -1;
    }
    
    size_t read = fread(memory, 1, size, fp);
    fclose(fp);
    
    if (read != size) {
        fprintf(stderr, "Failed to read entire image\n");
        return -1;
    }
    
    printf("Loaded image: %s (%ld bytes)\n", img_file, size);
    return size;
}

int paddr_read(int addr, int len) {
    if (addr < 0 || addr + len > MEM_SIZE) {
        fprintf(stderr, "Memory read out of bounds: addr=0x%x, len=%d\n", addr, len);
        return 0;
    }
    
    int value = 0;
    for (int i = 0; i < len; i++) {
        value |= (memory[addr + i] << (i * 8));
    }
    return value;
}

void paddr_write(int addr, int len, int data) {
    if (addr < 0 || addr + len > MEM_SIZE) {
        fprintf(stderr, "Memory write out of bounds: addr=0x%x, len=%d\n", addr, len);
        return;
    }
    
    for (int i = 0; i < len; i++) {
        memory[addr + i] = (data >> (i * 8)) & 0xFF;
    }
}

void init_device() {
    memset(memory, 0, MEM_SIZE);
    printf("Device initialized (memory: %d bytes)\n", MEM_SIZE);
}

void device_update() {
    // Nothing to update in minimal implementation
}

void difftest_step(int dut_pc) {
    // Minimal diff-test: just print PC
    static int step = 0;
    printf("Step %d: PC = 0x%08x\n", step++, dut_pc);
}