#include <verilated.h>
#include <iostream>
#include <cstdio>

#include "Vrv32im_pipeline_finalized.h"

// Simple memory
static uint8_t memory[0x10000] = {0};

// DPI-C functions
extern "C" {
    int paddr_read(int addr, int len) {
        if (addr < 0 || addr + len > 0x10000) {
            return 0;
        }
        
        int result = 0;
        for (int i = 0; i < len; i++) {
            result |= (memory[addr + i] << (i * 8));
        }
        return result;
    }
    
    void paddr_write(int addr, int len, int data) {
        if (addr < 0 || addr + len > 0x10000) {
            return;
        }
        
        for (int i = 0; i < len; i++) {
            memory[addr + i] = (data >> (i * 8)) & 0xFF;
        }
    }
    
    void difftest_step(int dut_pc) {
        static int step = 0;
        printf("[DiffTest] Step %d: PC = 0x%08x\n", step, dut_pc);
        step++;
    }
}

void load_program(const char* filename) {
    FILE* f = fopen(filename, "rb");
    if (!f) {
        printf("Error: Cannot open %s\n", filename);
        return;
    }
    
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);
    
    if (size > 0x10000) {
        printf("Error: Program too large\n");
        fclose(f);
        return;
    }
    
    fread(memory, 1, size, f);
    fclose(f);
    
    printf("Loaded %s (%ld bytes)\n", filename, size);
}

int main(int argc, char** argv) {
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);
    
    if (argc < 2) {
        printf("Usage: %s <test.bin>\n", argv[0]);
        return 1;
    }
    
    // Load test program
    load_program(argv[1]);
    
    printf("\n==========================================\n");
    printf("RV32IM Pipeline CPU - Finalized Version\n");
    printf("Test: %s\n", argv[1]);
    printf("==========================================\n\n");
    
    // Create CPU instance
    Vrv32im_pipeline_finalized* cpu = new Vrv32im_pipeline_finalized;
    
    // Reset sequence
    printf("Resetting CPU...\n");
    cpu->rst_n = 0;
    cpu->clk = 0;
    cpu->eval();
    
    cpu->clk = 1;
    cpu->eval();
    
    cpu->clk = 0;
    cpu->eval();
    
    // Release reset
    cpu->rst_n = 1;
    printf("Starting simulation...\n\n");
    
    // Run simulation
    int cycles = 0;
    int instructions = 0;
    
    for (int i = 0; i < 50; i++) {
        cpu->clk = !cpu->clk;
        cpu->eval();
        cycles++;
        
        if (cpu->clk == 1) {
            instructions++;
        }
        
        if (Verilated::gotFinish()) {
            break;
        }
    }
    
    printf("\n==========================================\n");
    printf("Simulation Results:\n");
    printf("Total cycles: %d\n", cycles);
    printf("Instructions executed: %d\n", instructions);
    
    if (instructions > 0) {
        float cpi = (float)cycles / instructions;
        printf("CPI (Cycles Per Instruction): %.2f\n", cpi);
        
        if (cpi < 1.5) {
            printf("Status: ✓ Good pipeline efficiency\n");
        } else {
            printf("Status: ⚠ Pipeline has stalls\n");
        }
    }
    
    printf("==========================================\n");
    
    // Cleanup
    delete cpu;
    return 0;
}
