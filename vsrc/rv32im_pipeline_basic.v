// Basic RV32IM Pipeline CPU - Fixed version
// This version fixes the pipeline register timing issues

module rv32im_pipeline_basic(
  input clk,
  input rst_n
);

  // DPI-C interface
  import "DPI-C" context function int paddr_read(input int addr, input int len);
  import "DPI-C" context function void paddr_write(input int addr, input int len, input int data);
  import "DPI-C" context function void difftest_step(input int dut_pc);

  // ==================== GLOBAL STATE ====================
  reg [31:0] pc;              // Program counter
  reg [31:0] rf [31:0];       // Register file
  
  // ==================== PIPELINE REGISTERS ====================
  
  // IF/ID stage registers
  reg [31:0] if_id_pc;
  reg [31:0] if_id_inst;
  
  // ID/EX stage registers
  reg [31:0] id_ex_pc;
  reg [31:0] id_ex_inst;
  reg [4:0]  id_ex_rd;
  reg [31:0] id_ex_rs1_val;
  reg [31:0] id_ex_rs2_val;
  reg [31:0] id_ex_imm;
  reg        id_ex_regwrite;
  reg        id_ex_memtoreg;
  
  // EX/MEM stage registers
  reg [31:0] ex_mem_pc;
  reg [31:0] ex_mem_alu_result;
  reg [4:0]  ex_mem_rd;
  reg        ex_mem_regwrite;
  reg        ex_mem_memtoreg;
  reg [31:0] ex_mem_rs2_val;  // For store instructions
  
  // MEM/WB stage registers
  reg [31:0] mem_wb_pc;
  reg [31:0] mem_wb_data;
  reg [4:0]  mem_wb_rd;
  reg        mem_wb_regwrite;
  reg        mem_wb_memtoreg;
  
  // ==================== STAGE 1: INSTRUCTION FETCH ====================
  wire [31:0] next_pc = pc + 4;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pc <= 32'h80000000;
      if_id_pc <= 32'h80000000;
      if_id_inst <= 32'h0;
    end else begin
      // Read instruction from memory and update pipeline registers
      if_id_pc <= pc;
      if_id_inst <= paddr_read(pc, 4);
      pc <= next_pc;
    end
  end
  
  // ==================== STAGE 2: INSTRUCTION DECODE ====================
  wire [6:0]  opcode = if_id_inst[6:0];
  wire [4:0]  rd     = if_id_inst[11:7];
  wire [4:0]  rs1    = if_id_inst[19:15];
  wire [4:0]  rs2    = if_id_inst[24:20];
  wire [2:0]  funct3 = if_id_inst[14:12];
  
  // Register file read
  wire [31:0] rs1_val = (rs1 != 0) ? rf[rs1] : 32'h0;
  wire [31:0] rs2_val = (rs2 != 0) ? rf[rs2] : 32'h0;
  
  // Immediate generation
  wire [31:0] imm_i = {{20{if_id_inst[31]}}, if_id_inst[31:20]};
  wire [31:0] imm_s = {{20{if_id_inst[31]}}, if_id_inst[31:25], if_id_inst[11:7]};
  wire [31:0] imm_u = {if_id_inst[31:12], 12'b0};
  
  // Control signal generation
  reg regwrite, memtoreg;
  reg [31:0] imm;
  
  always @(*) begin
    case (opcode)
      7'b0110111: begin  // LUI
        regwrite = 1'b1;
        memtoreg = 1'b0;
        imm = imm_u;
      end
      7'b0010111: begin  // AUIPC
        regwrite = 1'b1;
        memtoreg = 1'b0;
        imm = imm_u;
      end
      7'b0010011: begin  // OP-IMM (ADDI, etc.)
        regwrite = 1'b1;
        memtoreg = 1'b0;
        imm = imm_i;
      end
      7'b0110011: begin  // OP (ADD, etc.)
        regwrite = 1'b1;
        memtoreg = 1'b0;
        imm = 32'h0;
      end
      7'b0000011: begin  // Load
        regwrite = 1'b1;
        memtoreg = 1'b1;
        imm = imm_i;
      end
      7'b0100011: begin  // Store
        regwrite = 1'b0;
        memtoreg = 1'b0;
        imm = imm_s;
      end
      default: begin
        regwrite = 1'b0;
        memtoreg = 1'b0;
        imm = 32'h0;
      end
    endcase
  end
  
  // ID/EX pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id_ex_pc <= 32'h0;
      id_ex_inst <= 32'h0;
      id_ex_rd <= 5'h0;
      id_ex_rs1_val <= 32'h0;
      id_ex_rs2_val <= 32'h0;
      id_ex_imm <= 32'h0;
      id_ex_regwrite <= 1'b0;
      id_ex_memtoreg <= 1'b0;
    end else begin
      id_ex_pc <= if_id_pc;
      id_ex_inst <= if_id_inst;
      id_ex_rd <= rd;
      id_ex_rs1_val <= rs1_val;
      id_ex_rs2_val <= rs2_val;
      id_ex_imm <= imm;
      id_ex_regwrite <= regwrite;
      id_ex_memtoreg <= memtoreg;
    end
  end
  
  // ==================== STAGE 3: EXECUTE ====================
  wire [6:0]  ex_opcode = id_ex_inst[6:0];
  wire [2:0]  ex_funct3 = id_ex_inst[14:12];
  
  // ALU inputs
  wire [31:0] alu_a = id_ex_rs1_val;
  wire [31:0] alu_b = (ex_opcode == 7'b0010011 || ex_opcode == 7'b0000011 || 
                      ex_opcode == 7'b0100011) ? id_ex_imm : id_ex_rs2_val;
  
  // ALU operation
  reg [31:0] alu_result;
  
  always @(*) begin
    case (ex_funct3)
      3'b000: alu_result = alu_a + alu_b;  // ADD/ADDI
      3'b001: alu_result = alu_a << alu_b[4:0];  // SLL/SLLI
      3'b010: alu_result = ($signed(alu_a) < $signed(alu_b)) ? 32'h1 : 32'h0;  // SLT/SLTI
      3'b011: alu_result = (alu_a < alu_b) ? 32'h1 : 32'h0;  // SLTU/SLTIU
      3'b100: alu_result = alu_a ^ alu_b;  // XOR/XORI
      3'b101: alu_result = alu_a >> alu_b[4:0];  // SRL/SRLI (logical right shift)
      3'b110: alu_result = alu_a | alu_b;  // OR/ORI
      3'b111: alu_result = alu_a & alu_b;  // AND/ANDI
      default: alu_result = 32'h0;
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
      ex_mem_rs2_val <= 32'h0;
    end else begin
      ex_mem_pc <= id_ex_pc;
      ex_mem_alu_result <= alu_result;
      ex_mem_rd <= id_ex_rd;
      ex_mem_regwrite <= id_ex_regwrite;
      ex_mem_memtoreg <= id_ex_memtoreg;
      ex_mem_rs2_val <= id_ex_rs2_val;
    end
  end
  
  // ==================== STAGE 4: MEMORY ACCESS ====================
  // Memory access
  wire [31:0] mem_data;
  
  always @(*) begin
    if (ex_mem_memtoreg) begin
      // Load operation - handled by DPI-C in paddr_read
    end else if (ex_opcode == 7'b0100011) begin
      // Store operation
      paddr_write(ex_mem_alu_result, 4, ex_mem_rs2_val);
    end
  end
  
  // Memory read (for load instructions)
  assign mem_data = ex_mem_memtoreg ? paddr_read(ex_mem_alu_result, 4) : 32'h0;
  
  // MEM/WB pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mem_wb_pc <= 32'h0;
      mem_wb_data <= 32'h0;
      mem_wb_rd <= 5'h0;
      mem_wb_regwrite <= 1'b0;
      mem_wb_memtoreg <= 1'b0;
    end else begin
      mem_wb_pc <= ex_mem_pc;
      mem_wb_data <= ex_mem_memtoreg ? mem_data : ex_mem_alu_result;
      mem_wb_rd <= ex_mem_rd;
      mem_wb_regwrite <= ex_mem_regwrite;
      mem_wb_memtoreg <= ex_mem_memtoreg;
    end
  end
  
  // ==================== STAGE 5: WRITE BACK ====================
  // Register write back
  always @(posedge clk) begin
    if (mem_wb_regwrite && (mem_wb_rd != 0)) begin
      rf[mem_wb_rd] <= mem_wb_data;
    end
  end
  
  // Diff-test interface
  always @(posedge clk) begin
    difftest_step(pc);
  end
  
  // Debug output
  integer cycle_count = 0;
  
  always @(posedge clk) begin
    if (rst_n) begin
      cycle_count <= cycle_count + 1;
      if (cycle_count < 20) begin
        $display("[CYCLE %0d] PC=%h, IF:inst=%h, ID:rd=%h, EX:alu=%h, MEM:data=%h, WB:rd=%h data=%h",
                 cycle_count, pc, if_id_inst, rd, alu_result, mem_data, mem_wb_rd, mem_wb_data);
      end
    end
  end
  
  initial begin
    $display("[PIPELINE] Basic RV32IM Pipeline CPU initialized");
  end
  
endmodule