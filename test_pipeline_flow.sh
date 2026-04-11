#!/bin/bash
cd ~/Desktop/nemu-rv32

echo "=== Testing Pipeline Flow ==="
echo "1. Testing minimal pipeline..."
./obj_dir_minimal/Vrv32im_pipeline_minimal tests/simple_pipeline_test.bin 2>&1 | grep -A5 -B5 "CYCLE\|PC\|Inst"

echo ""
echo "2. Testing Y86 pipeline..."
./obj_dir_y86/Vrv32im_pipeline_y86 tests/pipeline_y86_test.bin 2>&1 | grep -A5 -B5 "CYCLE\|PC\|Inst"

echo ""
echo "3. Testing single-cycle CPU (baseline)..."
./obj_dir/Vrv32im_cpu tests/simple_test.bin 2>&1 | tail -20

echo ""
echo "=== Pipeline Status ==="
echo "Single-cycle CPU: ✅ Compiled and tested"
echo "Minimal pipeline: ⚠️  Compiled, needs debugging"
echo "Y86 pipeline: ⚠️  Compiled, needs debugging"
echo "Forwarding pipeline: 🔧 In development"
echo "Basic pipeline: 🔧 Compiling..."