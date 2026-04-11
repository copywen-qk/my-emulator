#include <verilated.h>
#include <iostream>
#include <cstdio>

// Include the generated Verilated model
#include "Vrv32im_pipeline_working.h"

// Simple memory for testing
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
        // Simple diff-test - just print PC
        static int step = 0;
        printf("[DiffTest] Step %d: PC = 0x%08x\n", step, dut_pc);
        step++;
    }
}

// Load test program
void load_test_program(const char* filename) {
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
    load_test_program(argv[1]);
    
    printf("Starting RV32IM Pipeline CPU simulation...\n");
    
    // Create CPU instance
    Vrv32im_pipeline_working* cpu = new Vrv32im_pipeline_working;
    
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
    
    // Run for 100 cycles
    for (int cycle = 0; cycle < 100; cycle++) {
        cpu->clk = !cpu->clk;
        cpu->eval();
        
        if (Verilated::gotFinish()) {
            break;
        }
    }
    
    printf("\nSimulation completed (100 cycles)\n");
    
    // Cleanup
    delete cpu;
    return 0;
}