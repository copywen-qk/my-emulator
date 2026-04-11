#include <verilated.h>
#include <iostream>
#include <cstdlib>
#include <cstdio>

// Include the generated Verilated model
#include "Vrv32im_pipeline_forwarding.h"

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

// Simple debug output
void debug_print(const char* format, ...) {
    static char buffer[256];
    va_list args;
    va_start(args, format);
    vsnprintf(buffer, sizeof(buffer), format, args);
    va_end(args);
    
    // Print to console
    std::cout << buffer << std::flush;
    
    // Also send to UART (address 0x10000000)
    volatile char *uart = (volatile char *)0x10000000;
    for (int i = 0; buffer[i] != '\0'; i++) {
        *uart = buffer[i];
    }
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

    debug_print("Starting RV32IM Pipeline CPU with Forwarding simulation...\n");
    debug_print("Test image: %s\n", argv[1]);
    
    // Create the CPU instance
    Vrv32im_pipeline_forwarding* cpu = new Vrv32im_pipeline_forwarding;
    
    // Reset the CPU
    debug_print("Resetting CPU...\n");
    cpu->rst_n = 0;
    cpu->clk = 0;
    cpu->eval();
    cpu->clk = 1;
    cpu->eval();
    cpu->clk = 0;
    cpu->eval();
    
    // Release reset
    cpu->rst_n = 1;
    debug_print("CPU reset released, starting simulation...\n");
    
    // Simulation loop
    int max_cycles = 100000;
    int instruction_count = 0;
    
    for (int cycle = 0; cycle < max_cycles; ++cycle) {
        // Toggle clock
        cpu->clk = !cpu->clk;
        cpu->eval();
        
        // Count instructions (on rising edge)
        if (cpu->clk == 1) {
            // We could add instruction counting logic here
            instruction_count++;
            
            // Print progress every 1000 cycles
            if (cycle % 1000 == 0) {
                debug_print("Cycle: %d, Instructions: %d\n", cycle, instruction_count);
            }
        }
        
        // Update device (SDL, etc.) every 1024 cycles
        if (cycle % 1024 == 0) {
            device_update();
        }
        
        // Check for simulation end conditions
        if (Verilated::gotFinish()) {
            debug_print("Simulation finished by Verilated::gotFinish()\n");
            break;
        }
        
        // Check for ebreak instruction (simulation halt)
        // This would require monitoring the CPU signals
    }
    
    debug_print("\nSimulation completed after %d cycles\n", max_cycles);
    debug_print("Estimated instructions executed: %d\n", instruction_count);
    debug_print("Approximate CPI: %.2f\n", max_cycles / (float)(instruction_count + 1));
    
    // Cleanup
    delete cpu;
    return 0;
}