// Complete RV32IM Pipeline CPU with forwarding and hazard detection

module rv32im_pipeline_complete(
  input clk,
  input rst_n
);

  // ==================== DPI-C INTERFACE ====================
  import "DPI-C" context function int paddr_read(input int addr, input int len);
  import "DPI-C" context function void paddr_write(input int addr, input int len, input int data);
  import "DPI-C" context function void difftest_step(input int dut_pc);

  // ==================== GLOBAL STATE ====================
  reg [31:0] pc;                    // Program counter
  reg [31:0] rf [31:0];             // Register file (32 registers)
  
  // ==================== PIPELINE REGISTERS ====================
  
  // IF/ID stage
  reg [31:0] if_id_pc;
  reg [31:0] if_id_inst;
  reg        if_id_valid;
  
  // ID/EX stage
  reg [31:0] id_ex_pc;
  reg [31:0] id_ex_inst;
  reg [4:0]  id_ex_rd;
  reg [4:0]  id_ex_rs1;
  reg [4:0]  id_ex_rs2;
  reg [31:0] id_ex_rs1_val;
  reg [31:0] id_ex_rs2_val;
  reg [31:0] id_ex_imm;
  reg        id_ex_regwrite;
  reg        id_ex_memtoreg;
  reg        id_ex_memread;
  reg        id_ex_memwrite;
  reg [2:0]  id_ex_funct3;
  reg [6:0]  id_ex_opcode;
  reg        id_ex_valid;
  
  // EX/MEM stage
  reg [31:0] ex_mem_pc;
  reg [31:0] ex_mem_aluout;
  reg [31:0] ex_mem_rs2_val;
  reg [4:0]  ex_mem_rd;
  reg        ex_mem_regwrite;
  reg        ex_mem_memtoreg;
  reg        ex_mem_memread;
  reg        ex_mem_memwrite;
  reg [2:0]  ex_mem_funct3;
  reg        ex_mem_valid;
  
  // MEM/WB stage
  reg [31:0] mem_wb_pc;
  reg [31:0] mem_wb_aluout;
  reg [31:0] mem_wb_memdata;
  reg [4:0]  mem_wb_rd;
  reg        mem_wb_regwrite;
  reg        mem_wb_memtoreg;
  reg        mem_wb_valid;
  
  // ==================== HAZARD DETECTION ====================
  wire load_use_hazard = id_ex_memread && 
                        ((id_ex_rd == if_id_inst[19:15]) || 
                         (id_ex_rd == if_id_inst[24:20]));
  
  wire stall = load_use_hazard;
  wire flush = 1'b0;  // For branch misprediction (not implemented yet)
  
  // ==================== FORWARDING LOGIC ====================
  wire [1:0] forward_a, forward_b;
  
  // Forwarding from EX/MEM stage
  assign forward_a[0] = (ex_mem_regwrite && ex_mem_valid && 
                        (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs1));
  
  assign forward_b[0] = (ex_mem_regwrite && ex_mem_valid && 
                        (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs2));
  
  // Forwarding from MEM/WB stage
  assign forward_a[1] = (mem_wb_regwrite && mem_wb_valid && 
                        (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rs1) &&
                        !(ex_mem_regwrite && ex_mem_valid && (ex_mem_rd == id_ex_rs1)));
  
  assign forward_b[1] = (mem_wb_regwrite && mem_wb_valid && 
                        (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rs2) &&
                        !(ex_mem_regwrite && ex_mem_valid && (ex_mem_rd == id_ex_rs2)));
  
  // Forwarded values
  wire [31:0] forward_a_val = (forward_a[0]) ? ex_mem_aluout :
                             (forward_a[1]) ? (mem_wb_memtoreg ? mem_wb_memdata : mem_wb_aluout) :
                             id_ex_rs1_val;
  
  wire [31:0] forward_b_val = (forward_b[0]) ? ex_mem_aluout :
                             (forward_b[1]) ? (mem_wb_memtoreg ? mem_wb_memdata : mem_wb_aluout) :
                             id_ex_rs2_val;
  
  // ==================== STAGE 1: INSTRUCTION FETCH ====================
  wire [31:0] inst = paddr_read(pc, 4);
  wire [31:0] next_pc = pc + 4;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pc <= 32'h80000000;
      if_id_pc <= 32'h80000000;
      if_id_inst <= 32'h0;
      if_id_valid <= 1'b0;
    end else if (stall) begin
      // Stall: keep IF/ID unchanged, don't fetch new instruction
      if_id_pc <= if_id_pc;
      if_id_inst <= if_id_inst;
      if_id_valid <= if_id_valid;
      pc <= pc;  // Don't increment PC
    end else if (flush) begin
      // Flush: insert bubble
      if_id_pc <= 32'h0;
      if_id_inst <= 32'h0;
      if_id_valid <= 1'b0;
      pc <= next_pc;  // Use branch target (not implemented yet)
    end else begin
      // Normal operation
      if_id_pc <= pc;
      if_id_inst <= inst;
      if_id_valid <= 1'b1;
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
  
  // Register file read (with forwarding bypass)
  wire [31:0] rs1_val_raw = (rs1 != 0) ? rf[rs1] : 32'h0;
  wire [31:0] rs2_val_raw = (rs2 != 0) ? rf[rs2] : 32'h0;
  
  // Check for forwarding from EX/MEM and MEM/WB to ID stage
  wire rs1_forward_ex = (ex_mem_regwrite && ex_mem_valid && ex_mem_rd == rs1);
  wire rs2_forward_ex = (ex_mem_regwrite && ex_mem_valid && ex_mem_rd == rs2);
  wire rs1_forward_mem = (mem_wb_regwrite && mem_wb_valid && mem_wb_rd == rs1);
  wire rs2_forward_mem = (mem_wb_regwrite && mem_wb_valid && mem_wb_rd == rs2);
  
  wire [31:0] rs1_val = rs1_forward_ex ? ex_mem_aluout :
                       rs1_forward_mem ? (mem_wb_memtoreg ? mem_wb_memdata : mem_wb_aluout) :
                       rs1_val_raw;
  
  wire [31:0] rs2_val = rs2_forward_ex ? ex_mem_aluout :
                       rs2_forward_mem ? (mem_wb_memtoreg ? mem_wb_memdata : mem_wb_aluout) :
                       rs2_val_raw;
  
  // Immediate generation
  wire [31:0] imm_i = {{20{if_id_inst[31]}}, if_id_inst[31:20]};
  wire [31:0] imm_s = {{20{if_id_inst[31]}}, if_id_inst[31:25], if_id_inst[11:7]};
  wire [31:0] imm_b = {{19{if_id_inst[31]}}, if_id_inst[31], if_id_inst[7], 
                       if_id_inst[30:25], if_id_inst[11:8], 1'b0};
  wire [31:0] imm_u = {if_id_inst[31:12], 12'b0};
  wire [31:0] imm_j = {{11{if_id_inst[31]}}, if_id_inst[31], if_id_inst[19:12], 
                       if_id_inst[20], if_id_inst[30:21], 1'b0};
  
  // Control unit
  reg regwrite, memtoreg, memread, memwrite, alusrc;
  reg [1:0] aluop;
  reg [31:0] imm;
  
  // Simple control logic
  always @(*) begin
    case (opcode)
      7'b0110111: begin  // LUI
        regwrite = 1'b1; memtoreg = 1'b0; memread = 1'b0; memwrite = 1'b0;
        alusrc = 1'b1; aluop = 2'b00; imm = imm_u;
      end
      7'b0010111: begin  // AUIPC
        regwrite = 1'b1; memtoreg = 1'b0; memread = 1'b0; memwrite = 1'b0;
        alusrc = 1'b1; aluop = 2'b00; imm = imm_u;
      end
      7'b0010011: begin  // OP-IMM
        regwrite = 1'b1; memtoreg = 1'b0; memread = 1'b0; memwrite = 1'b0;
        alusrc = 1'b1; aluop = 2'b10; imm = imm_i;
      end
      7'b0110011: begin  // OP
        regwrite = 1'b1; memtoreg = 1'b0; memread = 1'b0; memwrite = 1'b0;
        alusrc = 1'b0; aluop = 2'b10; imm = 32'h0;
      end
      7'b0000011: begin  // Load
        regwrite = 1'b1; memtoreg = 1'b1; memread = 1'b1; memwrite = 1'b0;
        alusrc = 1'b1; aluop = 2'b00; imm = imm_i;
      end
      7'b0100011: begin  // Store
        regwrite = 1'b0; memtoreg = 1'b0; memread = 1'b0; memwrite = 1'b1;
        alusrc = 1'b1; aluop = 2'b00; imm = imm_s;
      end
      default: begin
        regwrite = 1'b0; memtoreg = 1'b0; memread = 1'b0; memwrite = 1'b0;
        alusrc = 1'b0; aluop = 2'b00; imm = 32'h0;
      end
    endcase
  end
  
  // ID/EX pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id_ex_pc <= 32'h0;
      id_ex_inst <= 32'h0;
      id_ex_rd <= 5'h0;
      id_ex_rs1 <= 5'h0;
      id_ex_rs2 <= 5'h0;
      id_ex_rs1_val <= 32'h0;
      id_ex_rs2_val <= 32'h0;
      id_ex_imm <= 32'h0;
      id_ex_regwrite <= 1'b0;
      id_ex_memtoreg <= 1'b0;
      id_ex_memread <= 1'b0;
      id_ex_memwrite <= 1'b0;
      id_ex_funct3 <= 3'h0;
      id_ex_opcode <= 7'h0;
      id_ex_valid <= 1'b0;
    end else if (stall) begin
      // Insert bubble
      id_ex_pc <= 32'h0;
      id_ex_inst <= 32'h0;
      id_ex_rd <= 5'h0;
      id_ex_rs1 <= 5'h0;
      id_ex_rs2 <= 5'h0;
      id_ex_rs1_val <= 32'h0;
      id_ex_rs2_val <= 32'h0;
      id_ex_imm <= 32'h0;
      id_ex_regwrite <= 1'b0;
      id_ex_memtoreg <= 1'b0;
      id_ex_memread <= 1'b0;
      id_ex_memwrite <= 1'b0;
      id_ex_funct3 <= 3'h0;
      id_ex_opcode <= 7'h0;
      id_ex_valid <= 1'b0;
    end else begin
      id_ex_pc <= if_id_pc;
      id_ex_inst <= if_id_inst;
      id_ex_rd <= rd;
      id_ex_rs1 <= rs1;
      id_ex_rs2 <= rs2;
      id_ex_rs1_val <= rs1_val;
      id_ex_rs2_val <= rs2_val;
      id_ex_imm <= imm;
      id_ex_regwrite <= regwrite;
      id_ex_memtoreg <= memtoreg;
      id_ex_memread <= memread;
      id_ex_memwrite <= memwrite;
      id_ex_funct3 <= funct3;
      id_ex_opcode <= opcode;
      id_ex_valid <= if_id_valid;
    end
  end
  
  // ==================== STAGE 3: EXECUTE ====================
  wire [31:0] alu_src_a = forward_a_val;
  wire [31:0] alu_src_b = id_ex_imm;  // For now, always use immediate
  
  reg [31:0] alu_result;
  
  always @(*) begin
    case (id_ex_funct3)
      3'b000: alu_result = alu_src_a + alu_src_b;  // ADD/ADDI
      3'b001: alu_result = alu_src_a << alu_src_b[4:0];  // SLL/SLLI
      3'b010: alu_result = ($signed(alu_src_a) < $signed(alu_src_b)) ? 32'h1 : 32'h0;  // SLT/SLTI
      3'b011: alu_result = (alu_src_a < alu_src_b) ? 32'h1 : 32'h0;  // SLTU/SLTIU
      3'b100: alu_result = alu_src_a ^ alu_src_b;  // XOR/XORI
      3'b101: alu_result = alu_src_a >> alu_src_b[4:0];  // SRL/SRLI, SRA/SRAI
      3'b110: alu_result = alu_src_a | alu_src_b;  // OR/ORI
      3'b111: alu_result = alu_src_a & alu_src_b;  // AND/ANDI
      default: alu_result = 32'h0;
    endcase
  end
  
  // EX/MEM pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ex_mem_pc <= 32'h0;
      ex_mem_aluout <= 32'h0;
      ex_mem_rs2_val <= 32'h0;
      ex_mem_rd <= 5'h0;
      ex_mem_regwrite <= 1'b0;
      ex_mem_memtoreg <= 1'b0;
      ex_mem_memread <= 1'b0;
      ex_mem_memwrite <= 1'b0;
      ex_mem_funct3 <= 3'h0;
      ex_mem_valid <= 1'b0;
    end else begin
      ex_mem_pc <= id_ex_pc;
      ex_mem_aluout <= alu_result;
      ex_mem_rs2_val <= forward_b_val;
      ex_mem_rd <= id_ex_rd;
      ex_mem_regwrite <= id_ex_regwrite;
      ex_mem_memtoreg <= id_ex_memtoreg;
      ex_mem_memread <= id_ex_memread;
      ex_mem_memwrite <= id_ex_memwrite;
      ex_mem_funct3 <= id_ex_funct3;
      ex_mem_valid <= id_ex_valid;
    end
  end
  
  // ==================== STAGE 4: MEMORY ACCESS ====================
  wire [31:0] mem_read_data = paddr_read(ex_mem_aluout, 4);
  
  // Memory write
  always @(*) begin
    if (ex_mem_memwrite && ex_mem_valid) begin
      paddr_write(ex_mem_aluout, 4, ex_mem_rs2_val);
    end
  end
  
  // MEM/WB pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mem_wb_pc <= 32'h0;
      mem_wb_aluout <= 32'h0;
      mem_wb_memdata <= 32'h0;
      mem_wb_rd <= 5'h0;
      mem_wb_regwrite <= 1'b0;
      mem_wb_memtoreg <= 1'b0;
      mem_wb_valid <= 1'b0;
    end else begin
      mem_wb_pc <= ex_mem_pc;
      mem_wb_aluout <= ex_mem_aluout;
      mem_wb_memdata <= mem_read_data;
      mem_wb_rd <= ex_mem_rd;
      mem_wb_regwrite <= ex_mem_regwrite;
      mem_wb_memtoreg <= ex_mem_memtoreg;
      mem_wb_valid <= ex_mem_valid;
    end
  end
  
  // ==================== STAGE 5: WRITE BACK ====================
  wire [31:0] wb_data = mem_wb_memtoreg ? mem_wb_memdata : mem_wb_aluout;
  
  always @(posedge clk) begin
    if (mem_wb_regwrite && mem_wb_valid && (mem_wb_rd != 0)) begin
      rf[mem_wb_rd] <= wb_data;
      $display("[WB] Write x%d = 0x%08x", mem_wb_rd, wb_data);
    end
    
    // Diff-test step
    if (mem_wb_valid) begin
      difftest_step(mem_wb_pc);
    end
  end
  
  // ==================== DEBUG OUTPUT ====================
  always @(posedge clk) begin
    if (rst_n) begin
      $display("=== CYCLE %0d ===", $time);
      $display("[IF] PC=0x%08x, Inst=0x%08x", pc, inst);
      if (if_id_valid) begin
        $display("[ID] PC=0x%08x, Opcode=0x%02x, rs1=x%d, rs2=x%d, rd=x%d", 
                 if_id_pc, opcode, rs1, rs2, rd);
      end
      if (id_ex_valid) begin
        $display("[EX] PC=0x%08x, ALU=0x%08x, rd=x%d", 
                 id_ex_pc, alu_result, id_ex_rd);
      end
      if (ex_mem_valid) begin
        $display("[MEM] PC=0x%08x, Addr=0x%08x, Data=0x%08x, rd=x%d", 
                 ex_mem_pc, ex_mem_aluout, mem_read_data, ex_mem_rd);
      end
      if (mem_wb_valid) begin
        $display("[WB] PC=0x%08x, Data=0x%08x, rd=x%d", 
                 mem_wb_pc, wb_data, mem_wb_rd);
      end
      $display("");
    end
  end
  
  // ==================== INITIALIZATION ====================
  integer i;
  initial begin
    // Initialize register file
    for (i = 0; i < 32; i = i + 1) begin
      rf[i] = 32'h0;
    end
    
    // Initialize pipeline registers
    if_id_pc = 32'h80000000;
    if_id_inst = 32'h0;
    if_id_valid = 1'b0;
    
    id_ex_pc = 32'h0;
    id_ex_inst = 32'h0;
    id_ex_rd = 5'h0;
    id_ex_rs1_val = 32'h0;
    id_ex_rs2_val = 32'h0;
    id_ex_imm = 32'h0;
    id_ex_regwrite = 1'b0;
    id_ex_memtoreg = 1'b0;
    id_ex_valid = 1'b0;
    
    ex_mem_pc = 32'h0;
    ex_mem_aluout = 32'h0;
    ex_mem_rd = 5'h0;
    ex_mem_regwrite = 1'b0;
    ex_mem_memtoreg = 1'b0;
    ex_mem_valid = 1'b0;
    
    mem_wb_pc = 32'h0;
    mem_wb_aluout = 32'h0;
    mem_wb_memdata = 32'h0;
    mem_wb_rd = 5'h0;
    mem_wb_regwrite = 1'b0;
    mem_wb_memtoreg = 1'b0;
    mem_wb_valid = 1'b0;
    
    $display("RV32IM Pipeline CPU initialized");
  end
  
endmodule