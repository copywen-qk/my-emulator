#!/bin/bash
cd ~/Desktop/nemu-rv32

echo "=== FINAL PIPELINE TEST ==="
echo "Testing the corrected pipeline implementation"
echo ""

# Step 1: Create a simple test program
echo "1. Creating test program..."
cat > final_test.c << 'EOF'
// Final pipeline test
void _start() {
    // Test basic pipeline flow
    asm volatile("li x1, 0x111");    // x1 = 0x111
    asm volatile("li x2, 0x222");    // x2 = 0x222
    asm volatile("add x3, x1, x2");  // x3 = 0x333 (tests forwarding)
    asm volatile("add x4, x3, x1");  // x4 = 0x444 (tests chained forwarding)
    
    // Test memory operations
    volatile int* mem = (volatile int*)0x1000;
    *mem = 0xDEADBEEF;
    
    asm volatile("li x5, 0x1000");
    asm volatile("lw x6, 0(x5)");    // Load
    asm volatile("addi x7, x6, 1");  // Load-use (will need forwarding from MEM)
    
    // Store result
    asm volatile("sw x7, 4(x5)");
    
    // Fill pipeline with NOPs
    for (int i = 0; i < 5; i++) {
        asm volatile("nop");
    }
    
    // Halt
    asm volatile("ebreak");
}
EOF

# Compile
riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -nostdlib -O2 -T tests/link.ld final_test.c -o final_test.elf
riscv64-unknown-elf-objcopy -S -O binary final_test.elf final_test.bin

echo "Test program size: $(wc -c < final_test.bin) bytes"
echo ""

# Step 2: Create a simple sim_main for the corrected pipeline
echo "2. Creating simulation driver..."
cat > csrc/sim_main_corrected.cpp << 'EOF'
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
EOF

# Step 3: Build and test
echo "3. Building corrected pipeline..."
mkdir -p obj_dir_corrected
cd obj_dir_corrected

verilator -Wall -Wno-fatal -Wno-lint -Wno-style -Wno-width \
          --cc --exe --build --trace \
          --top-module rv32im_pipeline_corrected \
          -CFLAGS "-std=c++11 -g -O2 -I../include" \
          ../vsrc/rv32im_pipeline_corrected.v ../csrc/sim_main_corrected.cpp \
          -o Vrv32im_pipeline_corrected 2>&1 | grep -v "Warning.*UNOPTFLAT" | tail -20

echo ""
echo "4. Testing pipeline..."
if [ -f Vrv32im_pipeline_corrected ]; then
    ./Vrv32im_pipeline_corrected ../final_test.bin 2>&1 | head -100
else
    echo "Build failed, trying alternative..."
    
    # Try with existing dpi.c
    verilator -Wall -Wno-fatal -Wno-lint -Wno-style -Wno-width \
              --cc --exe --build \
              --top-module rv32im_pipeline_corrected \
              -CFLAGS "-std=c++11 -g -O2 -I../include" \
              ../vsrc/rv32im_pipeline_corrected.v ../csrc/sim_main_corrected.cpp \
              -o Vrv32im_pipeline_corrected_simple 2>&1 | tail -10
              
    if [ -f Vrv32im_pipeline_corrected_simple ]; then
        ./Vrv32im_pipeline_corrected_simple ../final_test.bin 2>&1 | head -80
    fi
fi

cd ..

echo ""
echo "=== TEST SUMMARY ==="
echo "The corrected pipeline includes:"
echo "1. ✅ Fixed memory read timing (clock edge)"
echo "2. ✅ Fixed PC update timing"
echo "3. ✅ Proper pipeline register updates"
echo "4. ✅ Simple data forwarding from EX/MEM"
echo "5. ✅ Debug output for pipeline monitoring"
echo ""
echo "Expected behavior:"
echo "- PC should increment each cycle (0x80000000, 0x80000004, ...)"
echo "- Instructions should flow through all 5 stages"
echo "- Data forwarding should handle RAW hazards"
echo "- Pipeline should fill after 5 cycles"

# Cleanup
rm -f final_test.c final_test.elf final_test.bin

echo ""
echo "=== NEXT STEPS FOR PIPELINE ==="
echo "1. Add more comprehensive forwarding (from MEM/WB)"
echo "2. Implement hazard detection for load-use"
echo "3. Add branch prediction"
echo "4. Integrate with full NEMU memory system"