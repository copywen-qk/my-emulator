#!/bin/bash
cd ~/Desktop/nemu-rv32
echo "Testing Y86-style pipeline CPU..."
echo "Running minimal_test.bin..."
./obj_dir_y86/Vrv32im_pipeline_y86 tests/minimal_test.bin 2>&1 | head -200