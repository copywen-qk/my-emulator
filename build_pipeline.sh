#!/bin/bash

# Build script for RV32IM pipeline CPUs

set -e

echo "=== Building RV32IM Pipeline CPUs ==="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Verilator is installed
if ! command -v verilator &> /dev/null; then
    print_error "Verilator is not installed. Please install it first."
    exit 1
fi

print_status "Verilator version: $(verilator --version | head -1)"

# Build NEMU first
print_status "Building NEMU reference model..."
cd build && make -f ../Makefile 2>&1 | tail -5
cd ..

# List of pipeline versions to build
PIPELINE_VERSIONS=(
    "minimal:vsrc/rv32im_pipeline_minimal.v:csrc/sim_main_new.cpp"
    "y86:vsrc/rv32im_pipeline_y86.v:csrc/sim_main_new.cpp"
    "simple:vsrc/rv32im_pipeline_simple.v:csrc/sim_main_new.cpp"
    "forwarding:vsrc/rv32im_pipeline_forwarding.v:csrc/sim_main_forwarding.cpp"
    "improved:vsrc/rv32im_pipeline_improved.v:csrc/sim_main_improved.cpp"
)

# Build each version
for version_info in "${PIPELINE_VERSIONS[@]}"; do
    IFS=':' read -r name vsrc csrc <<< "$version_info"
    
    print_status "Building $name pipeline version..."
    
    # Create output directory
    OBJ_DIR="obj_dir_$name"
    mkdir -p $OBJ_DIR
    
    # Build command
    verilator -Wall -Wno-fatal -Wno-lint -Wno-style -Wno-width \
              --cc --exe --build \
              --top-module "rv32im_pipeline_$name" \
              -CFLAGS "-std=c++11 -g -O2 -I./include -I./build" \
              --Mdir $OBJ_DIR \
              $vsrc $csrc src/dpi.c \
              -o $OBJ_DIR/Vrv32im_pipeline_$name 2>&1 | tail -10
    
    # Check if build succeeded
    if [ -f "$OBJ_DIR/Vrv32im_pipeline_$name" ]; then
        print_status "  ✓ $name pipeline built successfully"
    else
        print_warning "  ⚠ $name pipeline build may have issues"
    fi
done

echo
print_status "=== Build Summary ==="
echo

# List all built executables
print_status "Available CPU executables:"
for dir in obj_dir_*; do
    if [ -d "$dir" ]; then
        name=${dir#obj_dir_}
        if [ -f "$dir/Vrv32im_pipeline_$name" ]; then
            echo "  ✓ $name: ./$dir/Vrv32im_pipeline_$name"
        fi
    fi
done

# Also list single-cycle CPU
if [ -f "obj_dir/Vrv32im_cpu" ]; then
    echo "  ✓ single-cycle: ./obj_dir/Vrv32im_cpu"
fi

echo
print_status "=== Test Commands ==="
echo "To test a pipeline version:"
echo "  ./obj_dir_<version>/Vrv32im_pipeline_<version> tests/<test>.bin"
echo
echo "Available tests:"
ls tests/*.bin | xargs -n1 basename | while read test; do
    echo "  - $test"
done

echo
print_status "Build completed!"