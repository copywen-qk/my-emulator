#!/bin/bash

# Final pipeline implementation script

set -e

echo "=== Finalizing RV32IM Pipeline Implementation ==="
echo

# Build the final pipeline version
echo "1. Building final pipeline version..."
mkdir -p obj_dir_final

verilator -Wall -Wno-fatal -Wno-lint -Wno-style -Wno-width \
          --cc --exe --build \
          --top-module rv32im_pipeline_final \
          -CFLAGS "-std=c++11 -g -O2 -I./include" \
          --Mdir obj_dir_final \
          vsrc/rv32im_pipeline_final.v csrc/sim_main_new.cpp src/dpi.c \
          -o obj_dir_final/Vrv32im_pipeline_final 2>&1 | tail -20

echo
echo "2. Testing the pipeline..."
echo

# Run tests
TESTS=(
    "minimal_test.bin:Basic minimal test"
    "simple_pipeline_test.bin:Simple pipeline test"
    "forwarding_test.bin:Forwarding test"
)

for test_info in "${TESTS[@]}"; do
    IFS=':' read -r test_file description <<< "$test_info"
    
    echo "=== Testing: $description ==="
    echo "Test file: $test_file"
    
    if [ -f "tests/$test_file" ]; then
        timeout 5 ./obj_dir_final/Vrv32im_pipeline_final "tests/$test_file" 2>&1 | \
            grep -E "(PIPELINE|Result|PASS|FAIL|Error|mismatch)" | head -20
    else
        echo "  Test file not found: tests/$test_file"
    fi
    
    echo
done

echo "3. Creating pipeline documentation..."
echo

# Create pipeline documentation
cat > PIPELINE_IMPLEMENTATION.md << 'EOF'
# RV32IM Pipeline Implementation

## Overview
This document describes the final RV32IM pipeline implementation.

## Pipeline Stages

### 1. Instruction Fetch (IF)
- Reads instruction from memory at PC
- Updates PC to PC + 4
- Passes instruction to IF/ID register

### 2. Instruction Decode (ID)
- Decodes instruction fields (opcode, rd, rs1, rs2, funct3)
- Reads register file
- Generates immediate values
- Generates control signals
- Passes data to ID/EX register

### 3. Execute (EX)
- Performs ALU operations
- Calculates memory addresses
- Passes results to EX/MEM register

### 4. Memory Access (MEM)
- Reads from or writes to memory
- Passes data to MEM/WB register

### 5. Write Back (WB)
- Writes result back to register file
- Updates CPU state

## Pipeline Registers
- IF/ID: PC, Instruction
- ID/EX: PC, Control signals, Register values, Immediate
- EX/MEM: PC, ALU result, Control signals
- MEM/WB: PC, Memory data, ALU result, Control signals

## Features Implemented
1. Basic 5-stage pipeline
2. Register file with write-back
3. ALU operations (ADD, ADDI, etc.)
4. Memory access (load/store)
5. Control signal propagation
6. Debug output for each stage

## Testing
The pipeline has been tested with:
- Minimal test program
- Simple pipeline test
- Forwarding test (basic)

## Next Steps
1. Implement data forwarding
2. Add hazard detection
3. Implement branch prediction
4. Add more ALU operations
5. Comprehensive testing

EOF

echo "Pipeline documentation created: PIPELINE_IMPLEMENTATION.md"
echo
echo "=== Pipeline Finalization Complete ==="
echo
echo "To run the final pipeline:"
echo "  ./obj_dir_final/Vrv32im_pipeline_final tests/<test_file>.bin"
echo
echo "Available test files:"
ls tests/*.bin | xargs -n1 basename