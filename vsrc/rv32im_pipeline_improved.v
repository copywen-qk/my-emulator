// Improved RV32IM Pipeline CPU with proper control signal propagation

module rv32im_pipeline_improved(
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
  reg        if_id_valid;
  
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
  reg        id_ex_memtoreg;
  reg        id_ex_memread;
  reg        id_ex_memwrite;
  reg [2:0]  id_ex_funct3;
  reg        id_ex_valid;
  
  // EX/MEM stage registers
  reg [31:0] ex_mem_pc;
  reg [6:0]  ex_mem_opcode;
  reg [4:0]  ex_mem_rd;
  reg [31:0] ex_mem_aluout;
  reg [31:0] ex_mem_rs2_val;
  reg        ex_mem_regwrite;
  reg        ex_mem_memtoreg;
  reg        ex_mem_memread;
  reg        ex_mem_memwrite;
  reg [2:0]  ex_mem_funct3;
  reg        ex_mem_valid;
  
  // MEM/WB stage registers
  reg [31:0] mem_wb_pc;
  reg [6:0]  mem_wb_opcode;
  reg [4:0]  mem_wb_rd;
  reg [31:0] mem_wb_aluout;
  reg [31:0] mem_wb_memdata;
  reg        mem_wb_regwrite;
  reg        mem_wb_memtoreg;
  reg        mem_wb_valid;
  
  // ==================== STAGE 1: INSTRUCTION FETCH ====================
  wire [31:0] inst = paddr_read(pc, 4);
  wire [31:0] next_pc = pc + 4;
  
  // IF/ID pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      if_id_pc <= 32'h80000000;
      if_id_inst <= 32'h0;
      if_id_valid <= 1'b0;
      pc <= 32'h80000000;
    end else begin
      if_id_pc <= pc;
      if_id_inst <= inst;
      if_id_valid <= 1'b1;
      pc <= next_pc;
      
      // Debug output
      $display("[IF] PC=0x%08x, Inst=0x%08x", pc, inst);
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
  wire [31:0] imm_b = {{19{if_id_inst[31]}}, if_id_inst[31], if_id_inst[7], 
                       if_id_inst[30:25], if_id_inst[11:8], 1'b0};
  wire [31:0] imm_u = {if_id_inst[31:12], 12'b0};
  wire [31:0] imm_j = {{11{if_id_inst[31]}}, if_id_inst[31], if_id_inst[19:12], 
                       if_id_inst[20], if_id_inst[30:21], 1'b0};
  
  // Control signal generation (in ID stage)
  reg regwrite, memtoreg, memread, memwrite;
  reg [31:0] imm;
  
  always @(*) begin
    case (opcode)
      7'b0110111: begin  // LUI
        regwrite = 1'b1; memtoreg = 1'b0; memread = 1'b0; memwrite = 1'b0;
        imm = imm_u;
      end
      7'b0010111: begin  // AUIPC
        regwrite = 1'b1; memtoreg = 1'b0; memread = 1'b0; memwrite = 1'b0;
        imm = imm_u;
      end
      7'b0010011: begin  // OP-IMM (ADDI, etc.)
        regwrite = 1'b1; memtoreg = 1'b0; memread = 1'b0; memwrite = 1'b0;
        imm = imm_i;
      end
      7'b0110011: begin  // OP (ADD, etc.)
        regwrite = 1'b1; memtoreg = 1'b0; memread = 1'b0; memwrite = 1'b0;
        imm = 32'h0;
      end
      7'b0000011: begin  // Load
        regwrite = 1'b1; memtoreg = 1'b1; memread = 1'b1; memwrite = 1'b0;
        imm = imm_i;
      end
      7'b0100011: begin  // Store
        regwrite = 1'b0; memtoreg = 1'b0; memread = 1'b0; memwrite = 1'b1;
        imm = imm_s;
      end
      default: begin
        regwrite = 1'b0; memtoreg = 1'b0; memread = 1'b0; memwrite = 1'b0;
        imm = 32'h0;
      end
    endcase
  end
  
  // ID/EX pipeline register
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
      id_ex_memtoreg <= 1'b0;
      id_ex_memread <= 1'b0;
      id_ex_memwrite <= 1'b0;
      id_ex_funct3 <= 3'h0;
      id_ex_valid <= 1'b0;
    end else begin
      id_ex_pc <= if_id_pc;
      id_ex_opcode <= opcode;
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
      id_ex_valid <= if_id_valid;
      
      // Debug output
      if (if_id_valid) begin
        $display("[ID] PC=0x%08x, Opcode=0x%02x, rd=x%d, rs1=x%d, rs2=x%d", 
                 if_id_pc, opcode, rd, rs1, rs2);
      end
    end
  end
  
  // ==================== STAGE 3: EXECUTE ====================
  // ALU operation
  reg [31:0] alu_out;
  
  always @(*) begin
    case (id_ex_opcode)
      7'b0010011: begin  // OP-IMM
        case (id_ex_funct3)
          3'b000: alu_out = id_ex_rs1_val + id_ex_imm;  // ADDI
          3'b001: alu_out = id_ex_rs1_val << id_ex_imm[4:0];  // SLLI
          3'b010: alu_out = ($signed(id_ex_rs1_val) < $signed(id_ex_imm)) ? 32'h1 : 32'h0;  // SLTI
          3'b011: alu_out = (id_ex_rs1_val < id_ex_imm) ? 32'h1 : 32'h0;  // SLTIU
          3'b100: alu_out = id_ex_rs1_val ^ id_ex_imm;  // XORI
          3'b101: alu_out = id_ex_rs1_val >> id_ex_imm[4:0];  // SRLI/SRAI
          3'b110: alu_out = id_ex_rs1_val | id_ex_imm;  // ORI
          3'b111: alu_out = id_ex_rs1_val & id_ex_imm;  // ANDI
          default: alu_out = 32'h0;
        endcase
      end
      7'b0110011: begin  // OP
        case (id_ex_funct3)
          3'b000: alu_out = id_ex_rs1_val + id_ex_rs2_val;  // ADD
          3'b001: alu_out = id_ex_rs1_val << id_ex_rs2_val[4:0];  // SLL
          3'b010: alu_out = ($signed(id_ex_rs1_val) < $signed(id_ex_rs2_val)) ? 32'h1 : 32'h0;  // SLT
          3'b011: alu_out = (id_ex_rs1_val < id_ex_rs2_val) ? 32'h1 : 32'h0;  // SLTU
          3'b100: alu_out = id_ex_rs1_val ^ id_ex_rs2_val;  // XOR
          3'b101: alu_out = id_ex_rs1_val >> id_ex_rs2_val[4:0];  // SRL/SRA
          3'b110: alu_out = id_ex_rs1_val | id_ex_rs2_val;  // OR
          3'b111: alu_out = id_ex_rs1_val & id_ex_rs2_val;  // AND
          default: alu_out = 32'h0;
        endcase
      end
      7'b0000011: begin  // Load - calculate address
        alu_out = id_ex_rs1_val + id_ex_imm;
      end
      7'b0100011: begin  // Store - calculate address
        alu_out = id_ex_rs1_val + id_ex_imm;
      end
      7'b0110111: begin  // LUI
        alu_out = id_ex_imm;
      end
      7'b0010111: begin  // AUIPC
        alu_out = id_ex_pc + id_ex_imm;
      end
      default: alu_out = 32'h0;
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
      ex_mem_memtoreg <= 1'b0;
      ex_mem_memread <= 1'b0;
      ex_mem_memwrite <= 1'b0;
      ex_mem_funct3 <= 3'h0;
      ex_mem_valid <= 1'b0;
    end else begin
      ex_mem_pc <= id_ex_pc;
      ex_mem_opcode <= id_ex_opcode;
      ex_mem_rd <= id_ex_rd;
      ex_mem_aluout <= alu_out;
      ex_mem_rs2_val <= id_ex_rs2_val;
      ex_mem_regwrite <= id_ex_regwrite;
      ex_mem_memtoreg <= id_ex_memtoreg;
      ex_mem_memread <= id_ex_memread;
      ex_mem_memwrite <= id_ex_memwrite;
      ex_mem_funct3 <= id_ex_funct3;
      ex_mem_valid <= id_ex_valid;
      
      // Debug output
      if (id_ex_valid) begin
        $display("[EX] PC=0x%08x, ALU=0x%08x, rd=x%d", 
                 id_ex_pc, alu_out, id_ex_rd);
      end
    end
  end
  
  // ==================== STAGE 4: MEMORY ACCESS ====================
  reg [31:0] mem_data;
  
  always @(*) begin
    if (ex_mem_memread) begin
      // Load from memory
      mem_data = paddr_read(ex_mem_aluout, 4);
    end else if (ex_mem_memwrite) begin
      // Store to memory
      paddr_write(ex_mem_aluout, 4, ex_mem_rs2_val);
      mem_data = 32'h0;
    end else begin
      mem_data = 32'h0;
    end
  end
  
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
      mem_wb_valid <= 1'b0;
    end else begin
      mem_wb_pc <= ex_mem_pc;
      mem_wb_opcode <= ex_mem_opcode;
      mem_wb_rd <= ex_mem_rd;
      mem_wb_aluout <= ex_mem_aluout;
      mem_wb_memdata <= mem_data;
      mem_wb_regwrite <= ex_mem_regwrite;
      mem_wb_memtoreg <= ex_mem_memtoreg;
      mem_wb_valid <= ex_mem_valid;
      
      // Debug output
      if (ex_mem_valid) begin
        $display("[MEM] PC=0x%08x, Addr=0x%08x, Data=0x%08x, rd=x%d", 
                 ex_mem_pc, ex_mem_aluout, mem_data, ex_mem_rd);
      end
    end
  end
  
  // ==================== STAGE 5: WRITE BACK ====================
  wire [31:0] wb_data = mem_wb_memtoreg ? mem_wb_memdata : mem_wb_aluout;
  
  always @(posedge clk) begin
    if (mem_wb_regwrite && mem_wb_valid && (mem_wb_rd != 0)) begin
      rf[mem_wb_rd] <= wb_data;
      
      // Debug output
      $display("[WB] PC=0x%08x, Data=0x%08x -> rf[x%d]", 
               mem_wb_pc, wb_data, mem_wb_rd);
    end
    
    // Diff-test step
    if (mem_wb_valid) begin
      difftest_step(mem_wb_pc);
    end
  end
  
endmodule