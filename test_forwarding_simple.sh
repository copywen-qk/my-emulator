#!/bin/bash

# Simple test script for pipeline forwarding

echo "=== Testing RV32IM Pipeline with Forwarding ==="
echo

# Test 1: Compile the forwarding test
echo "1. Compiling forwarding test..."
cd tests && make forwarding_test.bin && cd ..

# Test 2: Check if minimal pipeline executable exists
echo "2. Checking for existing pipeline executables..."
if [ -f "./obj_dir_minimal/Vrv32im_pipeline_minimal" ]; then
    echo "   Found minimal pipeline executable"
    EXEC="./obj_dir_minimal/Vrv32im_pipeline_minimal"
elif [ -f "./obj_dir_y86/Vrv32im_pipeline_y86" ]; then
    echo "   Found Y86 pipeline executable"
    EXEC="./obj_dir_y86/Vrv32im_pipeline_y86"
elif [ -f "./obj_dir/Vrv32im_cpu" ]; then
    echo "   Found single-cycle CPU executable"
    EXEC="./obj_dir/Vrv32im_cpu"
else
    echo "   ERROR: No CPU executable found!"
    exit 1
fi

# Test 3: Run simple test
echo "3. Running simple pipeline test..."
$EXEC tests/simple_pipeline_test.bin 2>&1 | grep -A5 -B5 "PIPELINE\|DiffTest\|Result"

# Test 4: Run minimal test
echo "4. Running minimal test..."
$EXEC tests/minimal_test.bin 2>&1 | tail -20

# Test 5: Run forwarding test (if executable supports it)
echo "5. Running forwarding test..."
$EXEC tests/forwarding_test.bin 2>&1 | grep -A2 -B2 "Test\|Result\|PASS\|FAIL"

echo
echo "=== Test Complete ==="