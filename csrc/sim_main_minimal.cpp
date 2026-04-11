#include <verilated.h>
#include <iostream>
#include <cstdlib>

// Include the generated Verilated model
#include "Vrv32im_pipeline_minimal.h"

// DPI-C functions from NEMU
extern "C" {
    long load_image(const char *img_file);
    void difftest_step(long pc);
}

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <binary_file>" << std::endl;
        return 1;
    }

    const char* binary_file = argv[1];
    
    // Load the binary image
    long entry = load_image(binary_file);
    if (entry < 0) {
        std::cerr << "Failed to load image: " << binary_file << std::endl;
        return 1;
    }

    std::cout << "Starting minimal RV32IM pipeline CPU simulation..." << std::endl;
    
    // Create the CPU instance
    Vrv32im_pipeline_minimal* cpu = new Vrv32im_pipeline_minimal;
    
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
    int max_cycles = 10;
    for (int cycle = 0; cycle < max_cycles; ++cycle) {
        // Clock low phase
        cpu->clk = 0;
        cpu->eval();
        
        // Clock high phase
        cpu->clk = 1;
        cpu->eval();
        
        std::cout << "Cycle " << cycle << " completed." << std::endl;
    }
    
    std::cout << "Simulation completed after " << max_cycles << " cycles." << std::endl;
    
    // Cleanup
    delete cpu;
    
    return 0;
}