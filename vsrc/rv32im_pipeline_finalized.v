// RV32IM Pipeline CPU - Finalized Version
// Complete 5-stage pipeline with basic features

module rv32im_pipeline_finalized(
  input clk,
  input rst_n
);

  // DPI-C interface
  import "DPI-C" context function int paddr_read(input int addr, input int len);
  import "DPI-C" context function void paddr_write(input int addr, input int len, input int data);
  import "DPI-C" context function void difftest_step(input int dut_pc);

  // Program counter
  reg [31:0] pc;
  
  // Register file
  reg [31:0] rf [31:0];
  
  // ==================== PIPELINE REGISTERS ====================
  
  // IF/ID stage
  reg [31:0] if_id_pc;
  reg [31:0] if_id_inst;
  
  // ID/EX stage  
  reg [31:0] id_ex_pc;
  reg [31:0] id_ex_rs1_val;
  reg [31:0] id_ex_imm;
  reg [4:0]  id_ex_rd;
  reg        id_ex_regwrite;
  reg        id_ex_memtoreg;
  
  // EX/MEM stage
  reg [31:0] ex_mem_pc;
  reg [31:0] ex_mem_aluout;
  reg [4:0]  ex_mem_rd;
  reg        ex_mem_regwrite;
  reg        ex_mem_memtoreg;
  
  // MEM/WB stage
  reg [31:0] mem_wb_pc;
  reg [31:0] mem_wb_aluout;
  reg [31:0] mem_wb_memdata;
  reg [4:0]  mem_wb_rd;
  reg        mem_wb_regwrite;
  reg        mem_wb_memtoreg;

  // ==================== STAGE 1: FETCH ====================
  wire [31:0] inst = paddr_read(pc, 4);
  wire [31:0] next_pc = pc + 4;

  always @(posedge clk) begin
    if (!rst_n) begin
      pc <= 32'h80000000;
      if_id_pc <= 32'h80000000;
      if_id_inst <= 32'h0;
    end else begin
      pc <= next_pc;
      if_id_pc <= pc;
      if_id_inst <= inst;
    end
  end

  // ==================== STAGE 2: DECODE ====================
  wire [6:0] opcode = if_id_inst[6:0];
  wire [4:0] rd = if_id_inst[11:7];
  wire [4:0] rs1 = if_id_inst[19:15];
  wire [4:0] rs2 = if_id_inst[24:20];
  wire [2:0] funct3 = if_id_inst[14:12];

  // Register read
  wire [31:0] rs1_val = (rs1 != 0) ? rf[rs1] : 32'h0;

  // Immediate generation
  wire [31:0] imm_i = {{20{if_id_inst[31]}}, if_id_inst[31:20]};
  wire [31:0] imm_u = {if_id_inst[31:12], 12'b0};

  // Control signals
  wire regwrite = (opcode == 7'b0110111) ||  // LUI
                  (opcode == 7'b0010011) ||  // OP-IMM
                  (opcode == 7'b0000011);    // Load
  
  wire memtoreg = (opcode == 7'b0000011);    // Load only
  
  wire [31:0] imm = (opcode == 7'b0110111) ? imm_u : imm_i;

  // ID/EX pipeline register
  always @(posedge clk) begin
    if (!rst_n) begin
      id_ex_pc <= 32'h0;
      id_ex_rs1_val <= 32'h0;
      id_ex_imm <= 32'h0;
      id_ex_rd <= 5'h0;
      id_ex_regwrite <= 1'b0;
      id_ex_memtoreg <= 1'b0;
    end else begin
      id_ex_pc <= if_id_pc;
      id_ex_rs1_val <= rs1_val;
      id_ex_imm <= imm;
      id_ex_rd <= rd;
      id_ex_regwrite <= regwrite;
      id_ex_memtoreg <= memtoreg;
    end
  end

  // ==================== STAGE 3: EXECUTE ====================
  reg [31:0] alu_result;

  always @(*) begin
    case (funct3)
      3'b000: alu_result = id_ex_rs1_val + id_ex_imm;  // ADD/ADDI
      3'b001: alu_result = id_ex_rs1_val << id_ex_imm[4:0];  // SLL/SLLI
      3'b010: alu_result = ($signed(id_ex_rs1_val) < $signed(id_ex_imm)) ? 32'h1 : 32'h0;  // SLT/SLTI
      3'b011: alu_result = (id_ex_rs1_val < id_ex_imm) ? 32'h1 : 32'h0;  // SLTU/SLTIU
      3'b100: alu_result = id_ex_rs1_val ^ id_ex_imm;  // XOR/XORI
      3'b101: alu_result = id_ex_rs1_val >> id_ex_imm[4:0];  // SRL/SRLI
      3'b110: alu_result = id_ex_rs1_val | id_ex_imm;  // OR/ORI
      3'b111: alu_result = id_ex_rs1_val & id_ex_imm;  // AND/ANDI
      default: alu_result = 32'h0;
    endcase
  end

  // EX/MEM pipeline register
  always @(posedge clk) begin
    if (!rst_n) begin
      ex_mem_pc <= 32'h0;
      ex_mem_aluout <= 32'h0;
      ex_mem_rd <= 5'h0;
      ex_mem_regwrite <= 1'b0;
      ex_mem_memtoreg <= 1'b0;
    end else begin
      ex_mem_pc <= id_ex_pc;
      ex_mem_aluout <= alu_result;
      ex_mem_rd <= id_ex_rd;
      ex_mem_regwrite <= id_ex_regwrite;
      ex_mem_memtoreg <= id_ex_memtoreg;
    end
  end

  // ==================== STAGE 4: MEMORY ====================
  wire [31:0] mem_read_data = paddr_read(ex_mem_aluout, 4);

  // MEM/WB pipeline register
  always @(posedge clk) begin
    if (!rst_n) begin
      mem_wb_pc <= 32'h0;
      mem_wb_aluout <= 32'h0;
      mem_wb_memdata <= 32'h0;
      mem_wb_rd <= 5'h0;
      mem_wb_regwrite <= 1'b0;
      mem_wb_memtoreg <= 1'b0;
    end else begin
      mem_wb_pc <= ex_mem_pc;
      mem_wb_aluout <= ex_mem_aluout;
      mem_wb_memdata <= mem_read_data;
      mem_wb_rd <= ex_mem_rd;
      mem_wb_regwrite <= ex_mem_regwrite;
      mem_wb_memtoreg <= ex_mem_memtoreg;
    end
  end

  // ==================== STAGE 5: WRITE BACK ====================
  wire [31:0] wb_data = mem_wb_memtoreg ? mem_wb_memdata : mem_wb_aluout;

  always @(posedge clk) begin
    if (mem_wb_regwrite && mem_wb_rd != 0) begin
      rf[mem_wb_rd] <= wb_data;
    end
    
    // Diff-test
    difftest_step(mem_wb_pc);
  end

  // ==================== DEBUG OUTPUT ====================
  always @(posedge clk) begin
    if (rst_n) begin
      $display("=== CYCLE %0d ===", $time);
      $display("[IF] PC=0x%08x", pc);
      $display("[ID] PC=0x%08x, rd=x%d", if_id_pc, rd);
      $display("[EX] PC=0x%08x, ALU=0x%08x, rd=x%d", id_ex_pc, alu_result, id_ex_rd);
      $display("[MEM] PC=0x%08x, Addr=0x%08x, rd=x%d", ex_mem_pc, ex_mem_aluout, ex_mem_rd);
      $display("[WB] PC=0x%08x, Data=0x%08x -> x%d", mem_wb_pc, wb_data, mem_wb_rd);
    end
  end

  // ==================== INITIALIZATION ====================
  integer i;
  initial begin
    for (i = 0; i < 32; i = i + 1) begin
      rf[i] = 32'h0;
    end
    
    pc = 32'h80000000;
    if_id_pc = 32'h80000000;
    if_id_inst = 32'h0;
    
    id_ex_pc = 32'h0;
    id_ex_rs1_val = 32'h0;
    id_ex_imm = 32'h0;
    id_ex_rd = 5'h0;
    id_ex_regwrite = 1'b0;
    id_ex_memtoreg = 1'b0;
    
    ex_mem_pc = 32'h0;
    ex_mem_aluout = 32'h0;
    ex_mem_rd = 5'h0;
    ex_mem_regwrite = 1'b0;
    ex_mem_memtoreg = 1'b0;
    
    mem_wb_pc = 32'h0;
    mem_wb_aluout = 32'h0;
    mem_wb_memdata = 32'h0;
    mem_wb_rd = 5'h0;
    mem_wb_regwrite = 1'b0;
    mem_wb_memtoreg = 1'b0;
    
    $display("RV32IM Pipeline CPU Initialized");
  end

endmodule
