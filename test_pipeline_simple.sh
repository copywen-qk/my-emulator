#!/bin/bash
cd ~/Desktop/nemu-rv32
echo "Creating simple pipeline test..."
cat > simple_pipeline_test.v << 'EOF'
module simple_pipeline_test(
  input clk,
  input rst_n
);
  
  reg [31:0] pc;
  reg [31:0] if_id_pc;
  reg [31:0] if_id_inst;
  
  wire [31:0] next_pc = pc + 4;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pc <= 32'h80000000;
      if_id_pc <= 32'h0;
      if_id_inst <= 32'h0;
    end else begin
      // Update pipeline registers
      if_id_pc <= pc;
      if_id_inst <= pc;  // Just use PC as instruction for testing
      pc <= next_pc;
    end
  end
  
  always @(posedge clk) begin
    $display("Cycle: PC=0x%08h, if_id_pc=0x%08h, if_id_inst=0x%08h", 
             pc, if_id_pc, if_id_inst);
  end
  
endmodule
EOF

echo "Testing simple pipeline..."
verilator --cc --exe --build -j 0 -Wall simple_pipeline_test.v csrc/sim_main_minimal.cpp
echo "Test completed."