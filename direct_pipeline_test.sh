#!/bin/bash
cd ~/Desktop/nemu-rv32

echo "=== Direct Pipeline Test ==="
echo "Testing the working pipeline implementation"

# Step 1: Create a very simple test
echo ""
echo "1. Creating ultra-simple test..."
cat > simple_pipe_test.c << 'EOF'
// Ultra simple pipeline test
void _start() {
    // Just a few instructions to test pipeline flow
    asm volatile("li x1, 0x123");  // x1 = 0x123
    asm volatile("li x2, 0x456");  // x2 = 0x456
    asm volatile("add x3, x1, x2"); // x3 = 0x579
    asm volatile("ebreak");         // Halt
}
EOF

# Compile
riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -nostdlib -O2 -T tests/link.ld simple_pipe_test.c -o simple_pipe_test.elf
riscv64-unknown-elf-objcopy -S -O binary simple_pipe_test.elf simple_pipe_test.bin

echo "Test compiled: $(wc -c < simple_pipe_test.bin) bytes"

# Step 2: Create a minimal pipeline that should work
echo ""
echo "2. Creating minimal pipeline Verilog..."
cat > minimal_pipeline.v << 'EOF'
// Minimal pipeline that should work
module minimal_pipeline(
  input clk,
  input rst_n
);

  // Simple memory
  reg [31:0] memory [0:255];
  reg [31:0] pc;
  reg [31:0] rf [31:0];
  
  // Pipeline registers
  reg [31:0] if_id_pc;
  reg [31:0] if_id_inst;
  
  reg [31:0] id_ex_pc;
  reg [31:0] id_ex_inst;
  reg [4:0]  id_ex_rd;
  reg [31:0] id_ex_rs1_val;
  reg [31:0] id_ex_rs2_val;
  reg [31:0] id_ex_imm;
  
  reg [31:0] ex_mem_pc;
  reg [31:0] ex_mem_result;
  reg [4:0]  ex_mem_rd;
  
  reg [31:0] mem_wb_pc;
  reg [31:0] mem_wb_result;
  reg [4:0]  mem_wb_rd;
  
  // Initialize memory with test program
  integer i;
  initial begin
    // Initialize memory with NOPs
    for (i = 0; i < 256; i = i + 1) begin
      memory[i] = 32'h00000013; // NOP
    end
    
    // Load test program at address 0x80000000
    // li x1, 0x123 = addi x1, x0, 0x123
    memory[0] = 32'h12300093;
    // li x2, 0x456 = addi x2, x0, 0x456  
    memory[1] = 32'h45600113;
    // add x3, x1, x2
    memory[2] = 32'h002081b3;
    // ebreak
    memory[3] = 32'h00100073;
    
    $display("[MINIMAL] Memory initialized with test program");
  end
  
  // ==================== PIPELINE ====================
  
  // IF: Instruction Fetch
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pc <= 32'h80000000;
      if_id_pc <= 32'h80000000;
      if_id_inst <= 32'h00000013; // NOP
    end else begin
      // Read instruction (simple array access)
      if_id_pc <= pc;
      if_id_inst <= memory[pc[31:2]]; // Convert byte address to word index
      pc <= pc + 4;
    end
  end
  
  // ID: Instruction Decode
  wire [6:0]  opcode = if_id_inst[6:0];
  wire [4:0]  rd     = if_id_inst[11:7];
  wire [4:0]  rs1    = if_id_inst[19:15];
  wire [4:0]  rs2    = if_id_inst[24:20];
  
  wire [31:0] rs1_val = (rs1 != 0) ? rf[rs1] : 32'h0;
  wire [31:0] rs2_val = (rs2 != 0) ? rf[rs2] : 32'h0;
  wire [31:0] imm_i = {{20{if_id_inst[31]}}, if_id_inst[31:20]};
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id_ex_pc <= 32'h0;
      id_ex_inst <= 32'h00000013;
      id_ex_rd <= 5'h0;
      id_ex_rs1_val <= 32'h0;
      id_ex_rs2_val <= 32'h0;
      id_ex_imm <= 32'h0;
    end else begin
      id_ex_pc <= if_id_pc;
      id_ex_inst <= if_id_inst;
      id_ex_rd <= rd;
      id_ex_rs1_val <= rs1_val;
      id_ex_rs2_val <= rs2_val;
      id_ex_imm <= imm_i;
    end
  end
  
  // EX: Execute
  wire [31:0] alu_result = id_ex_rs1_val + id_ex_imm; // For ADDI
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ex_mem_pc <= 32'h0;
      ex_mem_result <= 32'h0;
      ex_mem_rd <= 5'h0;
    end else begin
      ex_mem_pc <= id_ex_pc;
      ex_mem_result <= alu_result;
      ex_mem_rd <= id_ex_rd;
    end
  end
  
  // MEM: Memory (just pass through)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mem_wb_pc <= 32'h0;
      mem_wb_result <= 32'h0;
      mem_wb_rd <= 5'h0;
    end else begin
      mem_wb_pc <= ex_mem_pc;
      mem_wb_result <= ex_mem_result;
      mem_wb_rd <= ex_mem_rd;
    end
  end
  
  // WB: Write Back
  always @(posedge clk) begin
    if (rst_n && mem_wb_rd != 0) begin
      rf[mem_wb_rd] <= mem_wb_result;
      $display("[WB] Write x%0d = %h at PC %h", mem_wb_rd, mem_wb_result, mem_wb_pc);
    end
  end
  
  // Debug output
  integer cycle = 0;
  always @(posedge clk) begin
    if (rst_n) begin
      cycle <= cycle + 1;
      if (cycle < 20) begin
        $display("[CYCLE %0d] PC=%h, IF=%h, ID=rd%0d, EX=rd%0d=%h, MEM=rd%0d, WB=rd%0d",
                 cycle, pc, if_id_inst, rd, id_ex_rd, alu_result, ex_mem_rd, mem_wb_rd);
      end
      if (cycle == 15) begin
        $display("[TEST] Register values after pipeline:");
        $display("  x1 = %h", rf[1]);
        $display("  x2 = %h", rf[2]);
        $display("  x3 = %h", rf[3]);
      end
    end
  end
  
  initial begin
    $display("[MINIMAL] Pipeline test starting");
  end
  
endmodule
EOF

# Step 3: Create testbench
echo ""
echo "3. Creating testbench..."
cat > testbench.v << 'EOF'
module testbench;
  reg clk = 0;
  reg rst_n = 0;
  
  // Clock generation
  always #5 clk = ~clk;
  
  // Instantiate pipeline
  minimal_pipeline dut(.clk(clk), .rst_n(rst_n));
  
  // Test sequence
  initial begin
    $dumpfile("pipeline.vcd");
    $dumpvars(0, testbench);
    
    $display("=== Pipeline Testbench ===");
    
    // Hold reset for 3 cycles
    #10;
    rst_n = 1;
    $display("[TB] Reset released at time %0t", $time);
    
    // Run for 50 cycles
    #500;
    
    $display("=== Test Complete ===");
    $display("Final register values:");
    $display("  x1 = %h", dut.rf[1]);
    $display("  x2 = %h", dut.rf[2]);
    $display("  x3 = %h", dut.rf[3]);
    
    // Check results
    if (dut.rf[1] === 32'h123 && dut.rf[2] === 32'h456 && dut.rf[3] === 32'h579) begin
      $display("[PASS] All tests passed!");
    end else begin
      $display("[FAIL] Test failed");
      $display("  Expected: x1=123, x2=456, x3=579");
      $display("  Got: x1=%h, x2=%h, x3=%h", dut.rf[1], dut.rf[2], dut.rf[3]);
    end
    
    $finish;
  end
endmodule
EOF

# Step 4: Run simulation
echo ""
echo "4. Running simulation with Icarus Verilog..."
if command -v iverilog >/dev/null 2>&1; then
    iverilog -o pipeline_test minimal_pipeline.v testbench.v 2>&1 | grep -v "warning"
    if [ -f pipeline_test ]; then
        vvp pipeline_test
    else
        echo "Compilation failed"
    fi
else
    echo "Icarus Verilog not found. Install with: sudo apt install iverilog"
    echo ""
    echo "To run manually:"
    echo "  iverilog -o pipeline_test minimal_pipeline.v testbench.v"
    echo "  vvp pipeline_test"
fi

# Cleanup
rm -f simple_pipe_test.c simple_pipe_test.elf simple_pipe_test.bin
rm -f minimal_pipeline.v testbench.v pipeline_test pipeline.vcd 2>/dev/null

echo ""
echo "=== Direct Pipeline Implementation Complete ==="
echo "This test demonstrates:"
echo "1. Basic 5-stage pipeline structure"
echo "2. Pipeline register timing"
echo "3. Instruction flow through stages"
echo "4. Register write-back"
echo ""
echo "Next steps:"
echo "1. Add more instruction types"
echo "2. Implement data forwarding"
echo "3. Add hazard detection"
echo "4. Integrate with NEMU memory system"