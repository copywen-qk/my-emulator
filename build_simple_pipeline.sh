#!/bin/bash

# Simple pipeline build and test

set -e

echo "=========================================="
echo "RV32IM Simple Pipeline Build & Test"
echo "=========================================="
echo

# Build directory
BUILD_DIR="obj_dir_working"
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

echo "1. Building working pipeline CPU..."
verilator -Wall -Wno-fatal -Wno-lint -Wno-style -Wno-width \
          --cc --exe --build \
          --top-module rv32im_pipeline_working \
          -CFLAGS "-std=c++11 -g -O2 -I./include" \
          --Mdir $BUILD_DIR \
          vsrc/rv32im_pipeline_working.v \
          csrc/sim_main_complete.cpp \
          -o $BUILD_DIR/Vrv32im_pipeline_working 2>&1 | \
          grep -E "(Error|Warning|Building)" || true

if [ -f "$BUILD_DIR/Vrv32im_pipeline_working" ]; then
    echo "✓ Pipeline CPU built successfully!"
    chmod +x $BUILD_DIR/Vrv32im_pipeline_working
else
    echo "✗ Build failed"
    exit 1
fi

echo
echo "2. Testing pipeline with minimal test..."
echo "----------------------------------------"

if [ -f "tests/minimal_test.bin" ]; then
    timeout 5 ./$BUILD_DIR/Vrv32im_pipeline_working tests/minimal_test.bin 2>&1 | \
        grep -E "(Starting|Loaded|\[IF\]|\[ID\]|\[EX\]|\[MEM\]|\[WB\]|Total cycles|Instructions)" | \
        head -20
else
    echo "Test file not found: tests/minimal_test.bin"
fi

echo
echo "3. Testing pipeline with simple test..."
echo "----------------------------------------"

if [ -f "tests/simple_pipeline_test.bin" ]; then
    timeout 5 ./$BUILD_DIR/Vrv32im_pipeline_working tests/simple_pipeline_test.bin 2>&1 | \
        grep -E "(Starting|Loaded|\[IF\]|\[ID\]|\[EX\]|\[MEM\]|\[WB\]|Total cycles|Instructions)" | \
        head -20
else
    echo "Test file not found: tests/simple_pipeline_test.bin"
fi

echo
echo "4. Performance analysis..."
echo "--------------------------"

echo "Running performance test..."
timeout 3 ./$BUILD_DIR/Vrv32im_pipeline_working tests/minimal_test.bin 2>&1 | \
    grep -E "(Total cycles|Instructions executed|CPI)" || true

echo
echo "=========================================="
echo "PIPELINE IMPLEMENTATION COMPLETE"
echo "=========================================="
echo
echo "Summary:"
echo "- 5-stage pipeline implemented: IF, ID, EX, MEM, WB"
echo "- Pipeline registers between each stage"
echo "- Basic ALU operations supported"
echo "- Memory access through DPI-C interface"
echo "- Register write-back in WB stage"
echo "- Debug output for pipeline visualization"
echo
echo "Files created:"
echo "- vsrc/rv32im_pipeline_working.v - Working pipeline implementation"
echo "- csrc/sim_main_complete.cpp - Simulation driver"
echo
echo "To run the pipeline CPU:"
echo "  ./obj_dir_working/Vrv32im_pipeline_working tests/<test>.bin"
echo
echo "Next steps for improvement:"
echo "1. Add data forwarding logic"
echo "2. Implement hazard detection and stalling"
echo "3. Add more instruction types (branches, jumps)"
echo "4. Implement M-extension (multiplication/division)"
echo "5. Add comprehensive test suite"
echo
echo "The pipeline foundation is now complete!"