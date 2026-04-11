#!/bin/bash
cd ~/Desktop/nemu-rv32

echo "Building working pipeline..."
mkdir -p obj_dir_working

verilator -Wall -Wno-fatal -Wno-lint -Wno-style -Wno-width \
          --cc --exe --build --trace \
          --top-module rv32im_pipeline_working \
          -CFLAGS "-std=c++11 -g -O2 -I./include" \
          vsrc/rv32im_pipeline_working.v csrc/sim_main_working.cpp src/dpi.c \
          -o obj_dir_working/Vrv32im_pipeline_working 2>&1 | tail -20

if [ -f obj_dir_working/Vrv32im_pipeline_working ]; then
    echo "Build successful!"
    echo "Testing with pipeline_direct_test..."
    ./obj_dir_working/Vrv32im_pipeline_working tests/pipeline_direct_test.bin 2>&1 | head -50
else
    echo "Build failed"
fi
