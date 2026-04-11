#!/bin/bash

# Complete pipeline implementation - standalone version

set -e

echo "=== Complete RV32IM Pipeline Implementation ==="
echo

# Create a simple test program
echo "1. Creating simple test program..."
cat > tests/pipeline_final_test.c << 'EOF'
// Simple test for final pipeline implementation
void _start() {
    // Test 1: Basic arithmetic
    int a = 10;
    int b = 20;
    int c = a + b;  // Should be 30
    
    // Test 2: Memory access
    int *ptr = (int*)0x1000;
    *ptr = c;
    
    // Test 3: Load back
    int d = *ptr;
    
    // Test 4: Loop
    int sum = 0;
    for (int i = 0; i < 5; i++) {
        sum += i;
    }
    
    // Halt
    asm volatile("ebreak");
}
EOF

# Compile the test
echo "2. Compiling test program..."
cd tests && make pipeline_final_test.bin && cd ..

# Build the final pipeline with simple DPI
echo "3. Building final pipeline CPU..."
rm -rf obj_dir_final_complete
mkdir -p obj_dir_final_complete

verilator -Wall -Wno-fatal -Wno-lint -Wno-style -Wno-width \
          --cc --exe --build \
          --top-module rv32im_pipeline_final \
          -CFLAGS "-std=c++11 -g -O2 -I./include" \
          --Mdir obj_dir_final_complete \
          vsrc/rv32im_pipeline_final.v csrc/sim_main_final.cpp src/dpi_simple.c \
          -o obj_dir_final_complete/Vrv32im_pipeline_final 2>&1 | grep -E "(Error|Warn|Building)" || true

echo
echo "4. Testing the pipeline..."
echo

if [ -f "obj_dir_final_complete/Vrv32im_pipeline_final" ]; then
    echo "✓ Pipeline executable built successfully"
    echo
    
    # Run the test
    echo "Running pipeline test..."
    timeout 3 ./obj_dir_final_complete/Vrv32im_pipeline_final tests/pipeline_final_test.bin 2>&1 | \
        grep -E "(PIPELINE|DiffTest|Starting|Simulation)" | head -20
    
    echo
    echo "Running minimal test..."
    timeout 3 ./obj_dir_final_complete/Vrv32im_pipeline_final tests/minimal_test.bin 2>&1 | \
        grep -E "(PIPELINE|DiffTest|Starting|Simulation)" | head -20
else
    echo "✗ Failed to build pipeline executable"
    echo "Trying alternative build method..."
    
    # Try building with existing single-cycle makefile
    cd obj_dir_final_complete && \
    verilator --cc --exe --build -j 0 -Wall \
        -CFLAGS "-DCONFIG_VERILATOR -I../include" \
        --top-module rv32im_pipeline_final \
        -Iinclude ../vsrc/rv32im_pipeline_final.v ../csrc/sim_main_final.cpp ../src/dpi_simple.c 2>&1 | \
        tail -10
fi

echo
echo "=== Implementation Summary ==="
echo
echo "The RV32IM pipeline implementation includes:"
echo "1. 5-stage pipeline (IF, ID, EX, MEM, WB)"
echo "2. Pipeline registers between each stage"
echo "3. Basic ALU operations (ADD, ADDI, etc.)"
echo "4. Memory access support"
echo "5. Register write-back"
echo "6. Debug output for pipeline state"
echo
echo "Files created/modified:"
echo "- vsrc/rv32im_pipeline_final.v: Final pipeline implementation"
echo "- csrc/sim_main_final.cpp: Simulation main program"
echo "- src/dpi_simple.c: Simplified DPI interface"
echo "- tests/pipeline_final_test.c: Test program"
echo
echo "To continue development:"
echo "1. Add data forwarding logic"
echo "2. Implement hazard detection"
echo "3. Add more ALU operations"
echo "4. Implement branch instructions"
echo "5. Add comprehensive testing"
echo
echo "=== Complete ==="