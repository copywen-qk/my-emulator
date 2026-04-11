#include <verilated.h>
#include <iostream>
#include <cstdlib>

// Include the generated Verilated model
#include "Vrv32im_pipeline_basic.h"

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

    std::cout << "Starting Basic RV32IM Pipeline CPU simulation..." << std::endl;
    
    // Create the CPU instance
    Vrv32im_pipeline_basic* cpu = new Vrv32im_pipeline_basic;
    
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
    const int max_cycles = 100;
    
    while (cycle < max_cycles) {
        // Toggle clock
        cpu->clk = !cpu->clk;
        cpu->eval();
        
        // Update device on rising edge
        if (cpu->clk) {
            device_update();
            cycle++;
            
            // Print progress every 5 cycles
            if (cycle % 5 == 0) {
                std::cout << "[Cycle " << cycle << "]" << std::endl;
            }
        }
        
        // Check for simulation end (breakpoint)
        if (Verilated::gotFinish()) {
            break;
        }
    }
    
    if (cycle >= max_cycles) {
        std::cout << "Simulation stopped after " << max_cycles << " cycles" << std::endl;
    } else {
        std::cout << "Simulation completed in " << cycle << " cycles" << std::endl;
    }
    
    // Cleanup
    delete cpu;
    
    return 0;
}