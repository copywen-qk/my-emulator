// RV32IM Pipeline CPU with Data Forwarding
// Enhanced version with hazard detection and forwarding logic

module rv32im_pipeline_forwarding(
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
  
  // ID/EX stage registers
  reg [31:0] id_ex_pc;
  reg [6:0]  id_ex_opcode;
  reg [4:0]  id_ex_rd;
  reg [4:0]  id_ex_rs1;
  reg [4:0]  id_ex_rs2;
  reg [31:0] id_ex_rs1_val;
  reg [31:0] id_ex_rs2_val;
  reg [31:0] id_ex_imm;
  reg        id_ex_regwrite;
  reg        id_ex_memread;
  reg        id_ex_memwrite;
  reg [2:0]  id_ex_funct3;
  
  // EX/MEM stage registers
  reg [31:0] ex_mem_pc;
  reg [6:0]  ex_mem_opcode;
  reg [4:0]  ex_mem_rd;
  reg [31:0] ex_mem_aluout;
  reg [31:0] ex_mem_rs2_val;
  reg        ex_mem_regwrite;
  reg        ex_mem_memread;
  reg        ex_mem_memwrite;
  reg [2:0]  ex_mem_funct3;
  
  // MEM/WB stage registers
  reg [31:0] mem_wb_pc;
  reg [6:0]  mem_wb_opcode;
  reg [4:0]  mem_wb_rd;
  reg [31:0] mem_wb_aluout;
  reg [31:0] mem_wb_memdata;
  reg        mem_wb_regwrite;
  reg        mem_wb_memtoreg;
  
  // ==================== GLOBAL STATE ====================
  reg [31:0] pc;              // Program counter
  reg [31:0] rf [31:0];       // Register file
  
  // ==================== HAZARD DETECTION ====================
  wire load_use_hazard = id_ex_memread && 
                        ((id_ex_rd == if_id_inst[19:15]) || 
                         (id_ex_rd == if_id_inst[24:20]));
  
  wire stall_if = load_use_hazard;
  wire stall_id = load_use_hazard;
  wire flush_id = 1'b0;  // For branch misprediction (to be implemented)
  
  // ==================== DATA FORWARDING ====================
  reg [31:0] forward_a, forward_b;
  
  // Forwarding logic for rs1
  always @(*) begin
    if (ex_mem_regwrite && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs1))
      forward_a = ex_mem_aluout;  // Forward from EX/MEM
    else if (mem_wb_regwrite && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rs1))
      forward_a = mem_wb_memtoreg ? mem_wb_memdata : mem_wb_aluout;  // Forward from MEM/WB
    else
      forward_a = id_ex_rs1_val;  // No forwarding needed
  end
  
  // Forwarding logic for rs2
  always @(*) begin
    if (ex_mem_regwrite && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs2))
      forward_b = ex_mem_aluout;  // Forward from EX/MEM
    else if (mem_wb_regwrite && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rs2))
      forward_b = mem_wb_memtoreg ? mem_wb_memdata : mem_wb_aluout;  // Forward from MEM/WB
    else
      forward_b = id_ex_rs2_val;  // No forwarding needed
  end
  
  // ==================== STAGE 1: INSTRUCTION FETCH ====================
  wire [31:0] inst = paddr_read(pc, 4);
  wire [31:0] next_pc = pc + 4;
  
  // IF/ID pipeline register with stall support
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      if_id_pc <= 32'h80000000;
      if_id_inst <= 32'h0;
      pc <= 32'h80000000;
    end else if (stall_if) begin
      // Stall: keep current values
      if_id_pc <= if_id_pc;
      if_id_inst <= if_id_inst;
      pc <= pc;  // Don't advance PC
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
  wire [2:0]  funct3 = if_id_inst[14:12];
  wire [6:0]  funct7 = if_id_inst[31:25];
  
  // Register file read with forwarding for ID stage
  wire [31:0] rs1_val_raw = (rs1 != 0) ? rf[rs1] : 32'h0;
  wire [31:0] rs2_val_raw = (rs2 != 0) ? rf[rs2] : 32'h0;
  
  // Immediate generation
  wire [31:0] imm_i = {{20{if_id_inst[31]}}, if_id_inst[31:20]};
  wire [31:0] imm_s = {{20{if_id_inst[31]}}, if_id_inst[31:25], if_id_inst[11:7]};
  wire [31:0] imm_b = {{19{if_id_inst[31]}}, if_id_inst[31], if_id_inst[7], 
                       if_id_inst[30:25], if_id_inst[11:8], 1'b0};
  wire [31:0] imm_u = {if_id_inst[31:12], 12'b0};
  wire [31:0] imm_j = {{11{if_id_inst[31]}}, if_id_inst[31], if_id_inst[19:12], 
                       if_id_inst[20], if_id_inst[30:21], 1'b0};
  
  // Control signal generation
  reg regwrite, memread, memwrite, memtoreg;
  reg [31:0] imm;
  
  always @(*) begin
    case (opcode)
      7'b0110111: begin  // LUI
        regwrite = 1'b1; memread = 1'b0; memwrite = 1'b0; memtoreg = 1'b0;
        imm = imm_u;
      end
      7'b0010111: begin  // AUIPC
        regwrite = 1'b1; memread = 1'b0; memwrite = 1'b0; memtoreg = 1'b0;
        imm = imm_u;
      end
      7'b0010011: begin  // OP-IMM (ADDI, etc.)
        regwrite = 1'b1; memread = 1'b0; memwrite = 1'b0; memtoreg = 1'b0;
        imm = imm_i;
      end
      7'b0110011: begin  // OP (ADD, etc.)
        regwrite = 1'b1; memread = 1'b0; memwrite = 1'b0; memtoreg = 1'b0;
        imm = 32'h0;
      end
      7'b0000011: begin  // Load
        regwrite = 1'b1; memread = 1'b1; memwrite = 1'b0; memtoreg = 1'b1;
        imm = imm_i;
      end
      7'b0100011: begin  // Store
        regwrite = 1'b0; memread = 1'b0; memwrite = 1'b1; memtoreg = 1'b0;
        imm = imm_s;
      end
      default: begin
        regwrite = 1'b0; memread = 1'b0; memwrite = 1'b0; memtoreg = 1'b0;
        imm = 32'h0;
      end
    endcase
  end
  
  // ID/EX pipeline register with stall support
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id_ex_pc <= 32'h0;
      id_ex_opcode <= 7'h0;
      id_ex_rd <= 5'h0;
      id_ex_rs1 <= 5'h0;
      id_ex_rs2 <= 5'h0;
      id_ex_rs1_val <= 32'h0;
      id_ex_rs2_val <= 32'h0;
      id_ex_imm <= 32'h0;
      id_ex_regwrite <= 1'b0;
      id_ex_memread <= 1'b0;
      id_ex_memwrite <= 1'b0;
      id_ex_funct3 <= 3'h0;
    end else if (stall_id) begin
      // Stall: insert NOP (bubble)
      id_ex_pc <= 32'h0;
      id_ex_opcode <= 7'h0;
      id_ex_rd <= 5'h0;
      id_ex_rs1 <= 5'h0;
      id_ex_rs2 <= 5'h0;
      id_ex_rs1_val <= 32'h0;
      id_ex_rs2_val <= 32'h0;
      id_ex_imm <= 32'h0;
      id_ex_regwrite <= 1'b0;
      id_ex_memread <= 1'b0;
      id_ex_memwrite <= 1'b0;
      id_ex_funct3 <= 3'h0;
    end else begin
      id_ex_pc <= if_id_pc;
      id_ex_opcode <= opcode;
      id_ex_rd <= rd;
      id_ex_rs1 <= rs1;
      id_ex_rs2 <= rs2;
      id_ex_rs1_val <= rs1_val_raw;
      id_ex_rs2_val <= rs2_val_raw;
      id_ex_imm <= imm;
      id_ex_regwrite <= regwrite;
      id_ex_memread <= memread;
      id_ex_memwrite <= memwrite;
      id_ex_funct3 <= funct3;
    end
  end
  
  // ==================== STAGE 3: EXECUTE ====================
  // ALU inputs with forwarding
  wire [31:0] alu_a = forward_a;
  wire [31:0] alu_b = (id_ex_opcode == 7'b0010011 || id_ex_opcode == 7'b0000011 || 
                      id_ex_opcode == 7'b0100011) ? id_ex_imm : forward_b;
  
  // ALU operation
  reg [31:0] alu_result;
  
  always @(*) begin
    case (id_ex_funct3)
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
      ex_mem_opcode <= 7'h0;
      ex_mem_rd <= 5'h0;
      ex_mem_aluout <= 32'h0;
      ex_mem_rs2_val <= 32'h0;
      ex_mem_regwrite <= 1'b0;
      ex_mem_memread <= 1'b0;
      ex_mem_memwrite <= 1'b0;
      ex_mem_funct3 <= 3'h0;
    end else begin
      ex_mem_pc <= id_ex_pc;
      ex_mem_opcode <= id_ex_opcode;
      ex_mem_rd <= id_ex_rd;
      ex_mem_aluout <= alu_result;
      ex_mem_rs2_val <= forward_b;  // Use forwarded value for store
      ex_mem_regwrite <= id_ex_regwrite;
      ex_mem_memread <= id_ex_memread;
      ex_mem_memwrite <= id_ex_memwrite;
      ex_mem_funct3 <= id_ex_funct3;
    end
  end
  
  // ==================== STAGE 4: MEMORY ACCESS ====================
  // Memory access
  wire [31:0] mem_data;
  
  always @(*) begin
    if (ex_mem_memwrite) begin
      // Store operation
      paddr_write(ex_mem_aluout, 4, ex_mem_rs2_val);
    end
  end
  
  // Memory read
  assign mem_data = ex_mem_memread ? paddr_read(ex_mem_aluout, 4) : 32'h0;
  
  // MEM/WB pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mem_wb_pc <= 32'h0;
      mem_wb_opcode <= 7'h0;
      mem_wb_rd <= 5'h0;
      mem_wb_aluout <= 32'h0;
      mem_wb_memdata <= 32'h0;
      mem_wb_regwrite <= 1'b0;
      mem_wb_memtoreg <= 1'b0;
    end else begin
      mem_wb_pc <= ex_mem_pc;
      mem_wb_opcode <= ex_mem_opcode;
      mem_wb_rd <= ex_mem_rd;
      mem_wb_aluout <= ex_mem_aluout;
      mem_wb_memdata <= mem_data;
      mem_wb_regwrite <= ex_mem_regwrite;
      mem_wb_memtoreg <= ex_mem_memread;
    end
  end
  
  // ==================== STAGE 5: WRITE BACK ====================
  // Register write back
  wire [31:0] wb_data = mem_wb_memtoreg ? mem_wb_memdata : mem_wb_aluout;
  
  always @(posedge clk) begin
    if (mem_wb_regwrite && (mem_wb_rd != 0)) begin
      rf[mem_wb_rd] <= wb_data;
    end
  end
  
  // Diff-test interface
  always @(posedge clk) begin
    difftest_step(pc);
  end
  
  // Debug output (optional)
  initial begin
    $display("[PIPELINE] RV32IM Pipeline CPU with Forwarding initialized");
  end
  
endmodule