#!/bin/bash
cd ~/Desktop/nemu-rv32

echo "=== Building Fixed Pipeline CPU ==="

# Create simple Makefile for fixed pipeline
cat > Makefile_fixed << 'EOF'
VERILATOR = verilator
VERILATOR_FLAGS = -Wall -Wno-fatal -Wno-lint -Wno-style -Wno-width \
                  --cc --exe --build --trace \
                  --top-module rv32im_pipeline_fixed \
                  -CFLAGS "-std=c++11 -g -O2 -I./include"

VSRC = vsrc/rv32im_pipeline_fixed.v
CSRC = csrc/sim_main_new.cpp src/dpi.c

OBJ_DIR = obj_dir_fixed

all: $(OBJ_DIR)/Vrv32im_pipeline_fixed

$(OBJ_DIR)/Vrv32im_pipeline_fixed: $(VSRC) $(CSRC)
	$(VERILATOR) $(VERILATOR_FLAGS) $(VSRC) $(CSRC) -o $(OBJ_DIR)/Vrv32im_pipeline_fixed

clean:
	rm -rf $(OBJ_DIR)

test: $(OBJ_DIR)/Vrv32im_pipeline_fixed
	./$(OBJ_DIR)/Vrv32im_pipeline_fixed tests/pipeline_simple_flow.bin 2>&1 | head -100

.PHONY: all clean test
EOF

echo "1. Building fixed pipeline CPU..."
make -f Makefile_fixed 2>&1 | tail -20

echo ""
echo "2. Testing with simple pipeline flow test..."
if [ -f obj_dir_fixed/Vrv32im_pipeline_fixed ]; then
    ./obj_dir_fixed/Vrv32im_pipeline_fixed tests/pipeline_simple_flow.bin 2>&1 | head -80
else
    echo "Build failed, trying alternative approach..."
    
    # Try direct verilator command
    echo "Trying direct Verilator build..."
    mkdir -p obj_dir_fixed
    cd obj_dir_fixed
    verilator -Wall -Wno-fatal -Wno-lint -Wno-style -Wno-width \
              --cc --exe --build --trace \
              --top-module rv32im_pipeline_fixed \
              -CFLAGS "-std=c++11 -g -O2 -I../include" \
              ../vsrc/rv32im_pipeline_fixed.v ../csrc/sim_main_new.cpp ../src/dpi.c \
              -o Vrv32im_pipeline_fixed 2>&1 | tail -20
    cd ..
    
    if [ -f obj_dir_fixed/Vrv32im_pipeline_fixed ]; then
        ./obj_dir_fixed/Vrv32im_pipeline_fixed tests/pipeline_simple_flow.bin 2>&1 | head -80
    fi
fi

echo ""
echo "=== Summary ==="
echo "Fixed pipeline CPU attempts to solve:"
echo "1. Memory read timing (using registers)"
echo "2. Pipeline register updates"
echo "3. Proper clock-edge synchronization"