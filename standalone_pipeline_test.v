// Standalone Pipeline Test
// This is a complete, self-contained pipeline test

module standalone_pipeline_test;

  // ==================== MINIMAL PIPELINE MODULE ====================
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
      memory[0] = 32'h12300093;  // PC=0x80000000
      // li x2, 0x456 = addi x2, x0, 0x456  
      memory[1] = 32'h45600113;  // PC=0x80000004
      // add x3, x1, x2
      memory[2] = 32'h002081b3;  // PC=0x80000008
      // ebreak
      memory[3] = 32'h00100073;  // PC=0x8000000C
      
      $display("[PIPELINE] Memory initialized with test program");
      $display("[PIPELINE] Instructions:");
      $display("  0x80000000: %h (addi x1, x0, 0x123)", memory[0]);
      $display("  0x80000004: %h (addi x2, x0, 0x456)", memory[1]);
      $display("  0x80000008: %h (add x3, x1, x2)", memory[2]);
      $display("  0x8000000C: %h (ebreak)", memory[3]);
    end
    
    // ==================== PIPELINE STAGES ====================
    
    // IF: Instruction Fetch
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        pc <= 32'h80000000;
        if_id_pc <= 32'h80000000;
        if_id_inst <= 32'h00000013; // NOP
      end else begin
        // Read instruction (simple array access)
        // Convert byte address to word index: pc[31:2]
        if_id_pc <= pc;
        if_id_inst <= memory[pc[31:2]];
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
    
    // ID/EX pipeline register
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
    // Simple ALU: for ADDI and ADD
    wire [31:0] alu_result;
    assign alu_result = (id_ex_inst[6:0] == 7'b0110011) ?  // ADD
                       id_ex_rs1_val + id_ex_rs2_val :
                       id_ex_rs1_val + id_ex_imm;         // ADDI
    
    // EX/MEM pipeline register
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
    
    // MEM: Memory (just pass through for now)
    // MEM/WB pipeline register
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
      end
    end
    
    // Debug output
    integer cycle = 0;
    always @(posedge clk) begin
      if (rst_n) begin
        cycle <= cycle + 1;
        if (cycle < 15) begin
          $display("[CYCLE %0d]", cycle);
          $display("  PC=%h, IF=%h", pc, if_id_inst);
          $display("  ID: pc=%h, inst=%h, rd=x%0d", if_id_pc, if_id_inst, rd);
          $display("  EX: pc=%h, inst=%h, rd=x%0d, result=%h", 
                   id_ex_pc, id_ex_inst, id_ex_rd, alu_result);
          $display("  MEM: pc=%h, rd=x%0d, result=%h", 
                   ex_mem_pc, ex_mem_rd, ex_mem_result);
          $display("  WB: pc=%h, rd=x%0d, result=%h", 
                   mem_wb_pc, mem_wb_rd, mem_wb_result);
          $display("");
        end
      end
    end
    
    initial begin
      $display("[PIPELINE] Minimal pipeline initialized");
    end
    
  endmodule
  
  // ==================== TESTBENCH ====================
  reg clk = 0;
  reg rst_n = 0;
  
  // Clock generation (10ns period)
  always #5 clk = ~clk;
  
  // Instantiate pipeline
  minimal_pipeline dut(.clk(clk), .rst_n(rst_n));
  
  // Test sequence
  initial begin
    $display("=== STANDALONE PIPELINE TEST ===");
    $display("Testing basic 5-stage pipeline");
    $display("");
    
    // Hold reset for 3 cycles
    #10;
    rst_n = 1;
    $display("[TEST] Reset released");
    $display("");
    
    // Run for 20 cycles
    #200;
    
    $display("=== TEST RESULTS ===");
    $display("Final register values:");
    $display("  x1 = %h (expected: 00000123)", dut.rf[1]);
    $display("  x2 = %h (expected: 00000456)", dut.rf[2]);
    $display("  x3 = %h (expected: 00000579)", dut.rf[3]);
    $display("");
    
    // Check results
    if (dut.rf[1] === 32'h123 && 
        dut.rf[2] === 32'h456 && 
        dut.rf[3] === 32'h579) begin
      $display("[SUCCESS] All pipeline tests passed!");
      $display("[SUCCESS] Pipeline is working correctly.");
    end else begin
      $display("[FAILURE] Pipeline test failed");
      $display("  Expected: x1=00000123, x2=00000456, x3=00000579");
    end
    
    $display("");
    $display("=== PIPELINE ANALYSIS ===");
    $display("Cycle analysis:");
    $display("  Cycle 1-3: Pipeline filling (NOPs in pipeline)");
    $display("  Cycle 4: First instruction (addi x1) reaches WB");
    $display("  Cycle 5: Second instruction (addi x2) reaches WB");
    $display("  Cycle 6: Third instruction (add x3) reaches WB");
    $display("  Cycle 7+: Pipeline full, instructions complete every cycle");
    
    $finish;
  end
  
  // Monitor for pipeline hazards
  always @(posedge clk) begin
    if (rst_n) begin
      // Check for RAW hazards
      if (dut.if_id_inst[19:15] == dut.id_ex_rd && dut.id_ex_rd != 0) begin
        $display("[HAZARD] RAW hazard detected: rs1=x%0d depends on EX stage rd=x%0d",
                 dut.if_id_inst[19:15], dut.id_ex_rd);
      end
      if (dut.if_id_inst[24:20] == dut.id_ex_rd && dut.id_ex_rd != 0) begin
        $display("[HAZARD] RAW hazard detected: rs2=x%0d depends on EX stage rd=x%0d",
                 dut.if_id_inst[24:20], dut.id_ex_rd);
      end
    end
  end
  
endmodule