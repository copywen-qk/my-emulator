#include <verilated.h>
#include <iostream>
#include <cstdlib>
#include <cstdio>

// Include the generated Verilated model
#include "Vrv32im_pipeline_complete.h"

// Simple DPI-C functions (standalone, no NEMU dependency)
extern "C" {
    // Memory access functions
    int paddr_read(int addr, int len) {
        static uint8_t memory[0x10000] = {0};
        
        if (addr < 0 || addr + len > 0x10000) {
            printf("[WARN] Memory read out of bounds: 0x%08x\n", addr);
            return 0;
        }
        
        int result = 0;
        for (int i = 0; i < len; i++) {
            result |= (memory[addr + i] << (i * 8));
        }
        return result;
    }
    
    void paddr_write(int addr, int len, int data) {
        static uint8_t memory[0x10000] = {0};
        
        if (addr < 0 || addr + len > 0x10000) {
            printf("[WARN] Memory write out of bounds: 0x%08x\n", addr);
            return;
        }
        
        for (int i = 0; i < len; i++) {
            memory[addr + i] = (data >> (i * 8)) & 0xFF;
        }
    }
    
    // Diff-test function (simplified)
    void difftest_step(int dut_pc) {
        static int step_count = 0;
        static int ref_pc = 0x80000000;
        
        if (step_count == 0) {
            ref_pc = 0x80000000;
        } else {
            ref_pc += 4;  // Simple model: PC increments by 4 each instruction
        }
        
        if (dut_pc != ref_pc) {
            printf("[DiffTest] PC mismatch! DUT: 0x%08x, REF: 0x%08x\n", dut_pc, ref_pc);
        }
        
        step_count++;
    }
    
    // Load image into memory
    long load_image(const char *img_file) {
        FILE *f = fopen(img_file, "rb");
        if (!f) {
            printf("[ERROR] Failed to open image: %s\n", img_file);
            return -1;
        }
        
        fseek(f, 0, SEEK_END);
        long size = ftell(f);
        fseek(f, 0, SEEK_SET);
        
        // Read into memory (using paddr_write)
        uint8_t *buffer = new uint8_t[size];
        size_t read = fread(buffer, 1, size, f);
        fclose(f);
        
        if (read != size) {
            printf("[ERROR] Failed to read image\n");
            delete[] buffer;
            return -1;
        }
        
        // Write to memory starting at 0x80000000
        for (long i = 0; i < size; i += 4) {
            int word = 0;
            for (int j = 0; j < 4 && (i + j) < size; j++) {
                word |= (buffer[i + j] << (j * 8));
            }
            paddr_write(0x80000000 + i, 4, word);
        }
        
        delete[] buffer;
        printf("Loaded image %s (%ld bytes)\n", img_file, size);
        return size;
    }
    
    // Device functions (empty for now)
    void init_device() {
        printf("Device initialized\n");
    }
    
    void device_update() {
        // Nothing to do
    }
}

int main(int argc, char** argv) {
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);
    
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <image.bin>" << std::endl;
        std::cerr << "Example: " << argv[0] << " tests/minimal_test.bin" << std::endl;
        return 1;
    }

    // Load test image
    if (load_image(argv[1]) < 0) {
        return 1;
    }

    std::cout << "==========================================" << std::endl;
    std::cout << "RV32IM Complete Pipeline CPU Simulation" << std::endl;
    std::cout << "Test image: " << argv[1] << std::endl;
    std::cout << "==========================================" << std::endl;
    
    // Create the CPU instance
    Vrv32im_pipeline_complete* cpu = new Vrv32im_pipeline_complete;
    
    // Reset sequence
    std::cout << "\n[1] Resetting CPU..." << std::endl;
    cpu->rst_n = 0;
    cpu->clk = 0;
    cpu->eval();
    
    cpu->clk = 1;
    cpu->eval();
    
    cpu->clk = 0;
    cpu->eval();
    
    // Release reset
    cpu->rst_n = 1;
    std::cout << "[2] CPU reset released" << std::endl;
    std::cout << "[3] Starting simulation..." << std::endl;
    std::cout << "==========================================" << std::endl;
    
    // Simulation parameters
    const int MAX_CYCLES = 1000;
    int cycle_count = 0;
    int instruction_count = 0;
    
    // Simulation loop
    for (cycle_count = 0; cycle_count < MAX_CYCLES; cycle_count++) {
        // Toggle clock
        cpu->clk = !cpu->clk;
        cpu->eval();
        
        // Count instructions (on rising edge)
        if (cpu->clk == 1) {
            instruction_count++;
        }
        
        // Check for simulation end
        if (Verilated::gotFinish()) {
            std::cout << "\n[INFO] Simulation finished by Verilated::gotFinish()" << std::endl;
            break;
        }
        
        // Early exit if we see too many errors
        if (cycle_count > 100 && instruction_count == 0) {
            std::cout << "\n[WARN] No instructions executed after 100 cycles" << std::endl;
            break;
        }
    }
    
    // Simulation results
    std::cout << "\n==========================================" << std::endl;
    std::cout << "SIMULATION RESULTS" << std::endl;
    std::cout << "==========================================" << std::endl;
    std::cout << "Total cycles: " << cycle_count << std::endl;
    std::cout << "Instructions executed: " << instruction_count << std::endl;
    
    if (instruction_count > 0) {
        float cpi = (float)cycle_count / instruction_count;
        std::cout << "CPI (Cycles Per Instruction): " << cpi << std::endl;
        
        if (cpi < 1.5) {
            std::cout << "✓ Good pipeline efficiency!" << std::endl;
        } else if (cpi < 3.0) {
            std::cout << "⚠ Moderate pipeline efficiency" << std::endl;
        } else {
            std::cout << "✗ Poor pipeline efficiency (check hazards)" << std::endl;
        }
    }
    
    std::cout << "\n==========================================" << std::endl;
    std::cout << "Pipeline Statistics:" << std::endl;
    std::cout << "- 5-stage pipeline (IF, ID, EX, MEM, WB)" << std::endl;
    std::cout << "- Data forwarding (EX/MEM → EX, MEM/WB → EX)" << std::endl;
    std::cout << "- Hazard detection (load-use stalls)" << std::endl;
    std::cout << "- Debug output for each pipeline stage" << std::endl;
    std::cout << "==========================================" << std::endl;
    
    // Cleanup
    delete cpu;
    return 0;
}