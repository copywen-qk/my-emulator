#include <verilated.h>
#include <iostream>
#include <cstdlib>
#include <cstdio>

// Include the generated Verilated model
#include "Vrv32im_cpu.h"

// Minimal DPI functions
extern "C" {
    long load_image(const char *img_file);
    void init_device();
    void device_update();
    
    // Memory access functions
    int paddr_read(int addr, int len);
    void paddr_write(int addr, int len, int data);
    
    // Diff-test function
    void difftest_step(int dut_pc);
}

int main(int argc, char** argv) {
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);
    
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <image.bin>" << std::endl;
        return 1;
    }

    // Initialize device and load image
    init_device();
    if (load_image(argv[1]) < 0) {
        std::cerr << "Failed to load image: " << argv[1] << std::endl;
        return 1;
    }

    std::cout << "Starting RV32IM CPU simulation..." << std::endl;
    std::cout << "Test image: " << argv[1] << std::endl;
    
    // Create the CPU instance
    Vrv32im_cpu* cpu = new Vrv32im_cpu;
    
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
    std::cout << "CPU reset released, starting execution..." << std::endl;
    
    // Simulation loop
    int max_cycles = 1000;
    int cycle = 0;
    
    while (cycle < max_cycles) {
        // Toggle clock
        cpu->clk = !cpu->clk;
        cpu->eval();
        
        // On positive edge (clk == 1)
        if (cpu->clk) {
            // Update device (e.g., VGA, keyboard)
            device_update();
            
            cycle++;
            
            // Print progress every 100 cycles
            if (cycle % 100 == 0) {
                std::cout << "Cycle " << cycle << std::endl;
            }
        }
        
        // Check for termination
        if (Verilated::gotFinish()) {
            std::cout << "Simulation finished by Verilated::gotFinish()" << std::endl;
            break;
        }
    }
    
    std::cout << "Simulation completed after " << cycle << " cycles" << std::endl;
    
    // Cleanup
    delete cpu;
    
    return 0;
}