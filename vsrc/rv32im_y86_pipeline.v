// RV32IM Pipeline CPU with Y86-64 style registers
// Basic implementation with pIcode, pCnd, pValM, pValC, pValP

module rv32im_y86_pipeline(
  input clk,
  input rst_n
);

  // DPI-C interface
  import "DPI-C" context function int paddr_read(input int addr, input int len);
  import "DPI-C" context function void paddr_write(input int addr, input int len, input int data);
  import "DPI-C" context function void difftest_step(input int dut_pc);

  // ==================== PIPELINE REGISTERS ====================
  
  // IF/ID stage registers
  reg [31:0] if_id_pc;
  reg [31:0] if_id_inst;
  
  // ID/EX stage registers (Y86-64 style)
  reg [31:0] id_ex_pc;
  reg [6:0]  id_ex_pIcode;    // Instruction code
  reg [4:0]  id_ex_rd;        // Destination register
  reg [31:0] id_ex_valA;      // Value from rs1
  reg [31:0] id_ex_valB;      // Value from rs2
  reg [31:0] id_ex_pValC;     // Constant/Immediate value
  reg [31:0] id_ex_pValP;     // PC + 4
  
  // EX/MEM stage registers
  reg [31:0] ex_mem_pc;
  reg [6:0]  ex_mem_pIcode;
  reg [31:0] ex_mem_aluout;   // ALU result
  reg [4:0]  ex_mem_rd;
  reg        ex_mem_pCnd;     // Branch condition
  reg        ex_mem_regwrite;
  
  // MEM/WB stage registers
  reg [31:0] mem_wb_pc;
  reg [6:0]  mem_wb_pIcode;
  reg [31:0] mem_wb_pValM;    // Memory read value
  reg [31:0] mem_wb_aluout;
  reg [4:0]  mem_wb_rd;
  reg        mem_wb_regwrite;
  
  // ==================== GLOBAL STATE ====================
  reg [31:0] pc;              // Program counter
  reg [31:0] rf [31:0];       // Register file
  
  // ==================== STAGE 1: INSTRUCTION FETCH ====================
  wire [31:0] inst = paddr_read(pc, 4);
  wire [31:0] next_pc = pc + 4;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      if_id_pc <= 32'h80000000;
      if_id_inst <= 32'h0;
      pc <= 32'h80000000;
    end else begin
      if_id_pc <= pc;
      if_id_inst <= inst;
      pc <= next_pc;
    end
  end
  
  // ==================== STAGE 2: INSTRUCTION DECODE ====================
  wire [6:0]  opcode = if_id_inst[6:0];
  wire [4:0]  rd     = if_id_inst[11:7];
  wire [4:0]  rs1    = if_id_inst[19:15];
  wire [4:0]  rs2    = if_id_inst[24:20];
  
  // Register file read
  wire [31:0] rs1_val = (rs1 != 0) ? rf[rs1] : 32'h0;
  wire [31:0] rs2_val = (rs2 != 0) ? rf[rs2] : 32'h0;
  
  // Immediate generation (simplified)
  wire [31:0] imm_i = {{20{if_id_inst[31]}}, if_id_inst[31:20]};
  
  // Map RISC-V opcode to Y86 pIcode
  reg [6:0] pIcode;
  reg [31:0] pValC;
  
  always @(*) begin
    case (opcode)
      7'b0110111: begin pIcode = 7'b0000001; pValC = {if_id_inst[31:12], 12'b0}; end // LUI
      7'b0010111: begin pIcode = 7'b0000010; pValC = {if_id_inst[31:12], 12'b0}; end // AUIPC
      7'b1101111: begin pIcode = 7'b0000011; pValC = {{11{if_id_inst[31]}}, if_id_inst[31], if_id_inst[19:12], 
                       if_id_inst[20], if_id_inst[30:21], 1'b0}; end // JAL
      7'b0010011: begin pIcode = 7'b0001000; pValC = imm_i; end // OP-IMM (ADDI)
      7'b0110011: begin pIcode = 7'b0001001; pValC = 32'h0;  end // OP (ADD)
      default:    begin pIcode = 7'b0000000; pValC = 32'h0;  end // NOP
    endcase
  end
  
  // pValP calculation (PC + 4)
  wire [31:0] pValP = if_id_pc + 4;
  
  // ID/EX pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id_ex_pc <= 32'h0;
      id_ex_pIcode <= 7'h0;
      id_ex_rd <= 5'h0;
      id_ex_valA <= 32'h0;
      id_ex_valB <= 32'h0;
      id_ex_pValC <= 32'h0;
      id_ex_pValP <= 32'h0;
    end else begin
      id_ex_pc <= if_id_pc;
      id_ex_pIcode <= pIcode;
      id_ex_rd <= rd;
      id_ex_valA <= rs1_val;
      id_ex_valB <= rs2_val;
      id_ex_pValC <= pValC;
      id_ex_pValP <= pValP;
    end
  end
  
  // ==================== STAGE 3: EXECUTE ====================
  // ALU inputs
  wire [31:0] alu_a = id_ex_valA;
  wire [31:0] alu_b = (id_ex_pIcode == 7'b0001000) ? id_ex_pValC : id_ex_valB;
  
  // ALU operation
  reg [31:0] alu_result;
  reg        pCnd;  // Branch condition
  
  always @(*) begin
    alu_result = 32'h0;
    pCnd = 1'b0;
    
    case (id_ex_pIcode)
      7'b0000001: alu_result = id_ex_pValC;  // LUI
      7'b0000010: alu_result = id_ex_pc + id_ex_pValC;  // AUIPC
      7'b0000011: alu_result = id_ex_pValP;  // JAL (return address)
      7'b0001000: alu_result = alu_a + alu_b;  // ADDI
      7'b0001001: alu_result = alu_a + alu_b;  // ADD
      default: alu_result = 32'h0;
    endcase
  end
  
  // Control signals
  wire ex_regwrite = (id_ex_pIcode == 7'b0000001 || id_ex_pIcode == 7'b0000010 ||
                     id_ex_pIcode == 7'b0000011 || id_ex_pIcode == 7'b0001000 ||
                     id_ex_pIcode == 7'b0001001);
  
  // EX/MEM pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ex_mem_pc <= 32'h0;
      ex_mem_pIcode <= 7'h0;
      ex_mem_aluout <= 32'h0;
      ex_mem_rd <= 5'h0;
      ex_mem_pCnd <= 1'b0;
      ex_mem_regwrite <= 1'b0;
    end else begin
      ex_mem_pc <= id_ex_pc;
      ex_mem_pIcode <= id_ex_pIcode;
      ex_mem_aluout <= alu_result;
      ex_mem_rd <= id_ex_rd;
      ex_mem_pCnd <= pCnd;
      ex_mem_regwrite <= ex_regwrite;
    end
  end
  
  // ==================== STAGE 4: MEMORY ACCESS ====================
  // For now, just pass through (no memory access in this simple version)
  wire [31:0] pValM = 32'h0;  // No memory read in this simple version
  
  // MEM/WB pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mem_wb_pc <= 32'h0;
      mem_wb_pIcode <= 7'h0;
      mem_wb_pValM <= 32'h0;
      mem_wb_aluout <= 32'h0;
      mem_wb_rd <= 5'h0;
      mem_wb_regwrite <= 1'b0;
    end else begin
      mem_wb_pc <= ex_mem_pc;
      mem_wb_pIcode <= ex_mem_pIcode;
      mem_wb_pValM <= pValM;
      mem_wb_aluout <= ex_mem_aluout;
      mem_wb_rd <= ex_mem_rd;
      mem_wb_regwrite <= ex_mem_regwrite;
    end
  end
  
  // ==================== STAGE 5: WRITE BACK ====================
  wire [31:0] wb_data = mem_wb_aluout;  // No memory read, so always use ALU result
  
  integer i;
  
  // Initialize
  initial begin
    for (i = 0; i < 32; i = i + 1) rf[i] = 32'h0;
    pc = 32'h80000000;
    if_id_pc = 32'h80000000;
    if_id_inst = 32'h0;
    id_ex_pc = 32'h0;
    id_ex_pIcode = 7'h0;
    id_ex_rd = 5'h0;
    id_ex_valA = 32'h0;
    id_ex_valB = 32'h0;
    id_ex_pValC = 32'h0;
    id_ex_pValP = 32'h0;
    ex_mem_pc = 32'h0;
    ex_mem_pIcode = 7'h0;
    ex_mem_aluout = 32'h0;
    ex_mem_rd = 5'h0;
    ex_mem_pCnd = 1'b0;
    ex_mem_regwrite = 1'b0;
    mem_wb_pc = 32'h0;
    mem_wb_pIcode = 7'h0;
    mem_wb_pValM = 32'h0;
    mem_wb_aluout = 32'h0;
    mem_wb_rd = 5'h0;
    mem_wb_regwrite = 1'b0;
  end
  
  // Register file write
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < 32; i = i + 1) rf[i] <= 32'h0;
    end else if (mem_wb_regwrite && mem_wb_rd != 0) begin
      rf[mem_wb_rd] <= wb_data;
      $display("[Y86-WB] Write x%0d = 0x%08h (PC=0x%08h, pIcode=0x%02h)", 
               mem_wb_rd, wb_data, mem_wb_pc, mem_wb_pIcode);
    end
  end
  
  // ==================== DEBUG OUTPUT ====================
  always @(posedge clk) begin
    $display("=== Y86 PIPELINE CYCLE ===");
    $display("[IF] PC=0x%08h, Inst=0x%08h", pc, inst);
    $display("[ID] PC=0x%08h, pIcode=0x%02h, rd=x%0d, pValC=0x%08h, pValP=0x%08h", 
             if_id_pc, pIcode, rd, pValC, pValP);
    $display("[EX] PC=0x%08h, pIcode=0x%02h, ALU=0x%08h, pCnd=%b, rd=x%0d", 
             id_ex_pc, id_ex_pIcode, alu_result, pCnd, id_ex_rd);
    $display("[MEM] PC=0x%08h, pIcode=0x%02h, pValM=0x%08h, rd=x%0d", 
             ex_mem_pc, ex_mem_pIcode, pValM, ex_mem_rd);
    $display("[WB] PC=0x%08h, pIcode=0x%02h, Data=0x%08h, rd=x%0d", 
             mem_wb_pc, mem_wb_pIcode, wb_data, mem_wb_rd);
    $display("");
    
    // Diff-test
    difftest_step(pc);
  end
  
  // Use unused signals to avoid warnings
  always @(*) begin
    if (id_ex_pValP != 0) begin
      // Use the signal
    end
    if (pCnd) begin
      // Use the signal
    end
    if (ex_mem_pCnd) begin
      // Use the signal
    end
    if (mem_wb_pValM != 0) begin
      // Use the signal
    end
  end

endmodule
