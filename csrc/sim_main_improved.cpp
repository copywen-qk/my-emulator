#include <verilated.h>
#include <iostream>
#include <cstdlib>
#include <cstdio>

// Include the generated Verilated model
#include "Vrv32im_pipeline_improved.h"

// DPI-C functions from NEMU
extern "C" {
    long load_image(const char *img_file);
    void init_device();
    void device_update();
    
    // Memory access functions (defined in NEMU)
    int paddr_read(int addr, int len);
    void paddr_write(int addr, int len, int data);
    
    // Diff-test function (defined in dpi.c)
    void difftest_step(int dut_pc);
}

int main(int argc, char** argv) {
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);
    
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <image.bin>" << std::endl;
        return 1;
    }

    // Initialize NEMU device and load image
    init_device();
    if (load_image(argv[1]) < 0) {
        std::cerr << "Failed to load image: " << argv[1] << std::endl;
        return 1;
    }

    std::cout << "Starting RV32IM Improved Pipeline CPU simulation..." << std::endl;
    std::cout << "Test image: " << argv[1] << std::endl;
    
    // Create the CPU instance
    Vrv32im_pipeline_improved* cpu = new Vrv32im_pipeline_improved;
    
    // Reset the CPU
    std::cout << "Resetting CPU..." << std::endl;
    cpu->rst_n = 0;
    cpu->clk = 0;
    cpu->eval();
    cpu->clk = 1;
    cpu->eval();
    cpu->clk = 0;
    cpu->eval();
    
    // Release reset
    cpu->rst_n = 1;
    std::cout << "CPU reset released, starting simulation..." << std::endl;
    
    // Simulation loop
    int max_cycles = 100000;
    int instruction_count = 0;
    
    for (int cycle = 0; cycle < max_cycles; ++cycle) {
        // Toggle clock
        cpu->clk = !cpu->clk;
        cpu->eval();
        
        // Count instructions (on rising edge)
        if (cpu->clk == 1) {
            instruction_count++;
            
            // Print progress every 1000 cycles
            if (cycle % 1000 == 0) {
                std::cout << "Cycle: " << cycle << ", Instructions: " << instruction_count << std::endl;
            }
        }
        
        // Update device (SDL, etc.) every 1024 cycles
        if (cycle % 1024 == 0) {
            device_update();
        }
        
        // Check for simulation end conditions
        if (Verilated::gotFinish()) {
            std::cout << "Simulation finished by Verilated::gotFinish()" << std::endl;
            break;
        }
    }
    
    std::cout << "\nSimulation completed after " << max_cycles << " cycles" << std::endl;
    std::cout << "Estimated instructions executed: " << instruction_count << std::endl;
    std::cout << "Approximate CPI: " << (max_cycles / (float)(instruction_count + 1)) << std::endl;
    
    // Cleanup
    delete cpu;
    return 0;
}