#!/bin/bash
cd ~/Desktop/nemu-rv32

echo "=== Quick Test of Fixed Pipeline ==="

# First, let's check what's working
echo "1. Checking existing builds..."
if [ -f obj_dir/Vrv32im_cpu ]; then
    echo "   Single-cycle CPU: ✅ Available"
    echo "   Testing single-cycle CPU with minimal test..."
    ./obj_dir/Vrv32im_cpu tests/minimal_test.bin 2>&1 | grep -i "loaded\|starting\|cycle\|pc" | head -10
else
    echo "   Single-cycle CPU: ❌ Not found"
fi

echo ""
echo "2. Analyzing pipeline issues..."
echo "   Problem: PC not incrementing in pipeline versions"
echo "   Possible causes:"
echo "   - Memory read timing (DPI-C paddr_read in combinational logic)"
echo "   - Pipeline register update timing"
echo "   - Reset signal handling"

echo ""
echo "3. Creating minimal test to debug..."
cat > debug_test.c << 'EOF'
// Minimal debug test
void _start() {
    // Just a few instructions to test pipeline flow
    asm volatile("lui x1, 0x10000");   // x1 = 0x10000000
    asm volatile("addi x2, x1, 0x123"); // x2 = 0x10000123
    asm volatile("add x3, x1, x2");    // x3 = 0x20000123
    asm volatile("ebreak");            // Halt
}
EOF

# Compile debug test
echo "   Compiling debug test..."
riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -nostdlib -O2 -T tests/link.ld debug_test.c -o debug_test.elf
riscv64-unknown-elf-objcopy -S -O binary debug_test.elf debug_test.bin

echo ""
echo "4. Testing with existing pipeline (minimal)..."
if [ -f obj_dir_minimal/Vrv32im_pipeline_minimal ]; then
    echo "   Running minimal pipeline with debug test..."
    timeout 5 ./obj_dir_minimal/Vrv32im_pipeline_minimal debug_test.bin 2>&1 | head -30
else
    echo "   Minimal pipeline not available"
fi

echo ""
echo "5. Direct Verilog simulation test..."
echo "   Creating a simple testbench to verify pipeline logic..."
cat > test_pipeline_tb.v << 'EOF'
module test_pipeline_tb;
    reg clk = 0;
    reg rst_n = 0;
    
    // Clock generation
    always #5 clk = ~clk;
    
    // Test sequence
    initial begin
        $display("=== Pipeline Test Bench ===");
        
        // Release reset after 3 cycles
        #15 rst_n = 1;
        
        // Run for 20 cycles
        #200;
        
        $display("=== Test Complete ===");
        $finish;
    end
    
    // Monitor
    always @(posedge clk) begin
        if (rst_n) begin
            $display("[TB] Clock edge at time %0t", $time);
        end
    end
endmodule
EOF

echo "   Testbench created. You can run with:"
echo "   iverilog -o test_pipeline_tb test_pipeline_tb.v"
echo "   vvp test_pipeline_tb"

echo ""
echo "=== Next Steps ==="
echo "1. Fix memory read timing in pipeline"
echo "2. Ensure PC increments correctly"
echo "3. Add pipeline hazard detection"
echo "4. Implement data forwarding"

# Cleanup
rm -f debug_test.c debug_test.elf debug_test.bin test_pipeline_tb.v