#include <verilated.h>
#include <iostream>
#include <cstdlib>

// Include the generated Verilated model
#include "Vrv32im_pipeline_corrected.h"

// Simple memory functions for testing
extern "C" {
    long load_image(const char *img_file) {
        FILE *f = fopen(img_file, "rb");
        if (!f) {
            std::cerr << "Failed to open image: " << img_file << std::endl;
            return -1;
        }
        
        fseek(f, 0, SEEK_END);
        long size = ftell(f);
        fseek(f, 0, SEEK_SET);
        
        // Simple memory array
        static uint8_t memory[1024 * 1024];
        fread(memory, 1, size, f);
        fclose(f);
        
        std::cout << "Loaded image " << img_file << " (" << size << " bytes)" << std::endl;
        return size;
    }
    
    void init_device() {
        // Nothing to initialize for simple test
    }
    
    void device_update() {
        // Nothing to update
    }
    
    int paddr_read(int addr, int len) {
        // Simple memory for testing
        static uint8_t memory[1024 * 1024];
        
        if (addr + len > sizeof(memory)) {
            return 0;
        }
        
        int result = 0;
        for (int i = 0; i < len; i++) {
            result |= (memory[addr + i] << (i * 8));
        }
        
        return result;
    }
    
    void paddr_write(int addr, int len, int data) {
        // Simple memory for testing
        static uint8_t memory[1024 * 1024];
        
        if (addr + len > sizeof(memory)) {
            return;
        }
        
        for (int i = 0; i < len; i++) {
            memory[addr + i] = (data >> (i * 8)) & 0xFF;
        }
    }
    
    void difftest_step(int dut_pc) {
        // Simple diff-test: just print PC changes
        static int last_pc = 0;
        if (dut_pc != last_pc) {
            // std::cout << "[DiffTest] PC = 0x" << std::hex << dut_pc << std::dec << std::endl;
            last_pc = dut_pc;
        }
    }
}

int main(int argc, char** argv) {
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);
    
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <image.bin>" << std::endl;
        return 1;
    }

    // Load image
    if (load_image(argv[1]) < 0) {
        return 1;
    }

    std::cout << "Starting Corrected RV32IM Pipeline CPU simulation..." << std::endl;
    
    // Create the CPU instance
    Vrv32im_pipeline_corrected* cpu = new Vrv32im_pipeline_corrected;
    
    // Reset the CPU
    cpu->rst_n = 0;
    cpu->clk = 0;
    cpu->eval();
    cpu->clk = 1;
    cpu->eval();
    cpu->clk = 0;
    cpu->eval();
    
    // Release reset
    cpu->rst_n = 1;
    
    // Simulation loop
    int cycle = 0;
    const int max_cycles = 50;
    
    while (cycle < max_cycles) {
        // Toggle clock
        cpu->clk = !cpu->clk;
        cpu->eval();
        
        // Update on rising edge
        if (cpu->clk) {
            device_update();
            cycle++;
            
            // Print progress
            if (cycle % 10 == 0) {
                std::cout << "[Cycle " << cycle << "]" << std::endl;
            }
        }
        
        // Check for simulation end
        if (Verilated::gotFinish()) {
            break;
        }
    }
    
    std::cout << "Simulation completed in " << cycle << " cycles" << std::endl;
    
    // Cleanup
    delete cpu;
    
    return 0;
}
