// Simple DPI-C implementation for pipeline testing
#include <stdio.h>
#include <stdint.h>

// Simple memory for testing
static uint8_t memory[1024 * 1024]; // 1MB memory

// Initialize memory
void init_memory() {
    // Initialize memory to 0
    for (int i = 0; i < sizeof(memory); i++) {
        memory[i] = 0;
    }
}

// Load image into memory
long load_image(const char *img_file) {
    FILE *f = fopen(img_file, "rb");
    if (!f) {
        fprintf(stderr, "Failed to open image: %s\n", img_file);
        return -1;
    }
    
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);
    
    if (size > sizeof(memory)) {
        fprintf(stderr, "Image too large: %ld bytes\n", size);
        fclose(f);
        return -1;
    }
    
    fread(memory, 1, size, f);
    fclose(f);
    
    printf("Loaded image %s (%ld bytes)\n", img_file, size);
    return size;
}

// Simple memory read
int paddr_read(int addr, int len) {
    if (addr + len > sizeof(memory)) {
        fprintf(stderr, "Memory read out of bounds: 0x%x, len=%d\n", addr, len);
        return 0;
    }
    
    int result = 0;
    for (int i = 0; i < len; i++) {
        result |= (memory[addr + i] << (i * 8));
    }
    
    return result;
}

// Simple memory write
void paddr_write(int addr, int len, int data) {
    if (addr + len > sizeof(memory)) {
        fprintf(stderr, "Memory write out of bounds: 0x%x, len=%d\n", addr, len);
        return;
    }
    
    for (int i = 0; i < len; i++) {
        memory[addr + i] = (data >> (i * 8)) & 0xFF;
    }
}

// Dummy device functions
void init_device() {
    init_memory();
}

void device_update() {
    // Nothing to do for simple test
}

// Simple diff-test (just prints PC)
void difftest_step(int dut_pc) {
    static int last_pc = 0;
    if (dut_pc != last_pc) {
        // printf("[DiffTest] PC = 0x%08x\n", dut_pc);
        last_pc = dut_pc;
    }
}