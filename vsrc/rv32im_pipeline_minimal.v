// Minimal RV32IM Pipeline CPU for testing

module rv32im_pipeline_minimal(
  input clk,
  input rst_n
);

  // DPI-C interface
  import "DPI-C" context function int paddr_read(input int addr, input int len);
  import "DPI-C" context function void paddr_write(input int addr, input int len, input int data);
  import "DPI-C" context function void difftest_step(input int dut_pc);

  // Global registers
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
  reg [31:0] ex_mem_alu_result;
  reg [4:0]  ex_mem_rd;
  reg        ex_mem_regwrite;
  reg        ex_mem_memtoreg;
  
  reg [31:0] mem_wb_pc;
  reg [31:0] mem_wb_data;
  reg [4:0]  mem_wb_rd;
  reg        mem_wb_regwrite;
  
  // ==================== STAGE 1: INSTRUCTION FETCH ====================
  reg [31:0] inst_reg;
  reg [31:0] next_pc;
  
  // Read instruction from memory
  always @(*) begin
    inst_reg = paddr_read(pc, 4);
    next_pc = pc + 4;
  end
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      if_id_pc <= 32'h80000000;
      if_id_inst <= 32'h0;
      pc <= 32'h80000000;
    end else begin
      if_id_pc <= pc;
      if_id_inst <= inst_reg;
      pc <= next_pc;
    end
  end
  
  // ==================== STAGE 2: INSTRUCTION DECODE ====================
  wire [6:0]  opcode = if_id_inst[6:0];
  wire [4:0]  rd     = if_id_inst[11:7];
  wire [4:0]  rs1    = if_id_inst[19:15];
  wire [4:0]  rs2    = if_id_inst[24:20];
  wire [2:0]  funct3 = if_id_inst[14:12];
  
  wire [31:0] rs1_val = (rs1 != 0) ? rf[rs1] : 32'h0;
  wire [31:0] rs2_val = (rs2 != 0) ? rf[rs2] : 32'h0;
  
  // Immediate generation
  wire [31:0] imm_i = {{20{if_id_inst[31]}}, if_id_inst[31:20]};
  
  // ID/EX pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id_ex_pc <= 32'h0;
      id_ex_inst <= 32'h0;
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
  
  // ==================== STAGE 3: EXECUTE ====================
  wire [6:0]  ex_opcode = id_ex_inst[6:0];
  wire [2:0]  ex_funct3 = id_ex_inst[14:12];
  
  reg [31:0] alu_result;
  reg        regwrite;
  reg        memtoreg;
  
  always @(*) begin
    alu_result = 32'h0;
    regwrite = 1'b0;
    memtoreg = 1'b0;
    
    case (ex_opcode)
      7'b0110111: begin // LUI
        alu_result = id_ex_imm;
        regwrite = 1'b1;
      end
      7'b0010011: begin // OP-IMM
        case (ex_funct3)
          3'b000: alu_result = id_ex_rs1_val + id_ex_imm; // ADDI
          default: alu_result = id_ex_rs1_val + id_ex_imm;
        endcase
        regwrite = 1'b1;
      end
      7'b0110011: begin // OP
        case (ex_funct3)
          3'b000: alu_result = id_ex_rs1_val + id_ex_rs2_val; // ADD
          default: alu_result = id_ex_rs1_val + id_ex_rs2_val;
        endcase
        regwrite = 1'b1;
      end
      default: begin
        // NOP or other instructions
      end
    endcase
  end
  
  // EX/MEM pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ex_mem_pc <= 32'h0;
      ex_mem_alu_result <= 32'h0;
      ex_mem_rd <= 5'h0;
      ex_mem_regwrite <= 1'b0;
      ex_mem_memtoreg <= 1'b0;
    end else begin
      ex_mem_pc <= id_ex_pc;
      ex_mem_alu_result <= alu_result;
      ex_mem_rd <= id_ex_rd;
      ex_mem_regwrite <= regwrite;
      ex_mem_memtoreg <= memtoreg;
    end
  end
  
  // ==================== STAGE 4: MEMORY ACCESS ====================
  // For now, just pass through
  wire [31:0] mem_data = ex_mem_alu_result;
  
  // MEM/WB pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mem_wb_pc <= 32'h0;
      mem_wb_data <= 32'h0;
      mem_wb_rd <= 5'h0;
      mem_wb_regwrite <= 1'b0;
    end else begin
      mem_wb_pc <= ex_mem_pc;
      mem_wb_data <= mem_data;
      mem_wb_rd <= ex_mem_rd;
      mem_wb_regwrite <= ex_mem_regwrite;
    end
  end
  
  // ==================== STAGE 5: WRITE BACK ====================
  integer i;
  
  // Initialize
  initial begin
    for (i = 0; i < 32; i = i + 1) rf[i] = 32'h0;
    pc = 32'h80000000;
    if_id_pc = 32'h80000000;
    if_id_inst = 32'h0;
    id_ex_pc = 32'h0;
    id_ex_inst = 32'h0;
    id_ex_rd = 5'h0;
    id_ex_rs1_val = 32'h0;
    id_ex_rs2_val = 32'h0;
    id_ex_imm = 32'h0;
    ex_mem_pc = 32'h0;
    ex_mem_alu_result = 32'h0;
    ex_mem_rd = 5'h0;
    ex_mem_regwrite = 1'b0;
    ex_mem_memtoreg = 1'b0;
    mem_wb_pc = 32'h0;
    mem_wb_data = 32'h0;
    mem_wb_rd = 5'h0;
    mem_wb_regwrite = 1'b0;
  end
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < 32; i = i + 1) rf[i] <= 32'h0;
    end else if (mem_wb_regwrite && mem_wb_rd != 0) begin
      rf[mem_wb_rd] <= mem_wb_data;
      $display("[PIPELINE-WB] Write x%0d = 0x%08h (PC=0x%08h)", 
               mem_wb_rd, mem_wb_data, mem_wb_pc);
    end
  end
  
  // ==================== DEBUG OUTPUT ====================
  always @(posedge clk) begin
    // Display values from previous cycle
    $display("=== PIPELINE CYCLE (after posedge) ===");
    $display("[IF] PC=0x%08h, Inst=0x%08h", pc, inst_reg);
    $display("[ID] PC=0x%08h, Inst=0x%08h, rd=x%0d", 
             if_id_pc, if_id_inst, rd);
    $display("[EX] PC=0x%08h, ALU=0x%08h, rd=x%0d", 
             id_ex_pc, alu_result, id_ex_rd);
    $display("[MEM] PC=0x%08h, Data=0x%08h, rd=x%0d", 
             ex_mem_pc, mem_data, ex_mem_rd);
    $display("[WB] PC=0x%08h, Data=0x%08h, rd=x%0d", 
             mem_wb_pc, mem_wb_data, mem_wb_rd);
    $display("");
    
    // Diff-test
    difftest_step(pc);
  end
  
  // Display values before clock edge
  always @(negedge clk) begin
    $display("=== PIPELINE CYCLE (before negedge) ===");
    $display("[IF] PC=0x%08h, Inst=0x%08h", pc, inst_reg);
    $display("[ID] PC=0x%08h, Inst=0x%08h, rd=x%0d", 
             if_id_pc, if_id_inst, rd);
    $display("");
  end

  // Use unused signals to avoid warnings
  always @(*) begin
    if (id_ex_inst != 0) begin
      // Use the signal
    end
    if (ex_mem_memtoreg) begin
      // Use the signal
    end
    if (opcode != 0) begin
      // Use the signal
    end
    if (funct3 != 0) begin
      // Use the signal
    end
  end

endmodule
