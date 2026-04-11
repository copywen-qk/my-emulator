// RV32IM Pipeline CPU with Y86-64 style registers
// pIcode, pCnd, pValM, pValC, pValP naming convention

module rv32im_pipeline_y86(
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
  
  // Pipeline registers (Y86-64 style)
  reg [31:0] if_id_pc;
  reg [31:0] if_id_inst;
  
  reg [31:0] id_ex_pc;
  reg [6:0]  id_ex_pIcode;
  reg [4:0]  id_ex_rd;
  reg [31:0] id_ex_valA;
  reg [31:0] id_ex_valB;
  reg [31:0] id_ex_pValC;
  reg [2:0]  id_ex_funct3;
  
  reg [31:0] ex_mem_pc;
  reg [6:0]  ex_mem_pIcode;
  reg [31:0] ex_mem_aluout;
  reg [31:0] ex_mem_valB;
  reg [4:0]  ex_mem_rd;
  reg        ex_mem_pCnd;
  reg        ex_mem_memread;
  reg        ex_mem_memwrite;
  reg [2:0]  ex_mem_funct3;
  reg        ex_mem_regwrite;
  reg [31:0] ex_mem_pValP;
  
  reg [31:0] mem_wb_pc;
  reg [6:0]  mem_wb_pIcode;
  reg [31:0] mem_wb_pValM;
  reg [31:0] mem_wb_aluout;
  reg [4:0]  mem_wb_rd;
  reg        mem_wb_regwrite;
  reg        mem_wb_memtoreg;
  
  // ==================== STAGE 1: INSTRUCTION FETCH ====================
  wire [31:0] inst = (pc >= 32'h80000000) ? paddr_read(pc, 4) : 32'h0;
  
  // PC update logic
  reg [31:0] next_pc;
  always @(*) begin
    // Default: PC + 4
    next_pc = pc + 4;
    
    // Handle branches from EX stage
    if (id_ex_pIcode == 7'b0000101 && pCnd) begin  // Branch taken
      next_pc = id_ex_pc + id_ex_pValC;
    end
    // Handle JAL from EX stage
    else if (id_ex_pIcode == 7'b0000011) begin  // JAL
      next_pc = id_ex_pc + id_ex_pValC;
    end
    // Handle JALR from EX stage
    else if (id_ex_pIcode == 7'b0000100) begin  // JALR
      next_pc = id_ex_valA + id_ex_pValC;
      next_pc[0] = 1'b0;  // Clear LSB for alignment
    end
  end
  
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
  wire [2:0]  funct3 = if_id_inst[14:12];
  
  wire [31:0] rs1_val = (rs1 != 0) ? rf[rs1] : 32'h0;
  wire [31:0] rs2_val = (rs2 != 0) ? rf[rs2] : 32'h0;
  
  // Immediate generation
  wire [31:0] imm_i = {{20{if_id_inst[31]}}, if_id_inst[31:20]};
  
  // Map to Y86-64 style pIcode
  reg [6:0] pIcode;
  always @(*) begin
    case (opcode)
      7'b0110111: pIcode = 7'b0000001; // LUI
      7'b0010111: pIcode = 7'b0000010; // AUIPC
      7'b1101111: pIcode = 7'b0000011; // JAL
      7'b1100111: pIcode = 7'b0000100; // JALR
      7'b1100011: pIcode = 7'b0000101; // Branch
      7'b0000011: pIcode = 7'b0000110; // Load
      7'b0100011: pIcode = 7'b0000111; // Store
      7'b0010011: pIcode = 7'b0001000; // OP-IMM
      7'b0110011: pIcode = 7'b0001001; // OP
      default:    pIcode = 7'b0000000; // NOP
    endcase
  end
  
  // Debug: show instruction
  always @(*) begin
    $display("[DEBUG] if_id_inst=0x%08h, opcode=0x%02h, pIcode=0x%02h", if_id_inst, opcode, pIcode);
  end
  
  // Select pValC
  reg [31:0] pValC;
  always @(*) begin
    case (opcode)
      7'b0010011, 7'b0000011, 7'b1100111: pValC = imm_i;
      default: pValC = 32'h0;
    endcase
  end
  
  // pValP calculation
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
      id_ex_funct3 <= 3'h0;
    end else begin
      id_ex_pc <= if_id_pc;
      id_ex_pIcode <= pIcode;
      id_ex_rd <= rd;
      id_ex_valA <= rs1_val;
      id_ex_valB <= rs2_val;
      id_ex_pValC <= pValC;
      id_ex_funct3 <= funct3;
    end
  end
  
  // ==================== STAGE 3: EXECUTE ====================
  wire [31:0] alu_a = id_ex_valA;
  wire [31:0] alu_b = (id_ex_pIcode == 7'b0001000 ||  // OP-IMM
                       id_ex_pIcode == 7'b0000110 ||  // Load
                       id_ex_pIcode == 7'b0000100 ||  // JALR
                       id_ex_pIcode == 7'b0000111) ?  // Store
                      id_ex_pValC : id_ex_valB;
  
  reg [31:0] alu_result;
  reg        pCnd;
  
  always @(*) begin
    alu_result = 32'h0;
    pCnd = 1'b0;
    
    if (id_ex_pIcode == 7'b0001000 || id_ex_pIcode == 7'b0001001) begin
      case (id_ex_funct3)
        3'b000: alu_result = alu_a + alu_b;
        default: alu_result = alu_a + alu_b;
      endcase
    end else if (id_ex_pIcode == 7'b0000101) begin
      case (id_ex_funct3)
        3'b000: pCnd = (id_ex_valA == id_ex_valB);
        default: pCnd = 1'b0;
      endcase
    end else if (id_ex_pIcode == 7'b0000001) begin
      alu_result = id_ex_pValC;
    end else if (id_ex_pIcode == 7'b0000010) begin
      alu_result = id_ex_pc + id_ex_pValC;
    end else if (id_ex_pIcode == 7'b0000011 || id_ex_pIcode == 7'b0000100) begin
      alu_result = id_ex_pc + 4;
    end else if (id_ex_pIcode == 7'b0000110 || id_ex_pIcode == 7'b0000111) begin
      alu_result = id_ex_valA + id_ex_pValC;
    end
  end
  
  wire ex_memread  = (id_ex_pIcode == 7'b0000110);
  wire ex_memwrite = (id_ex_pIcode == 7'b0000111);
  wire ex_regwrite = (id_ex_pIcode == 7'b0000001 || id_ex_pIcode == 7'b0000010 ||
                     id_ex_pIcode == 7'b0000011 || id_ex_pIcode == 7'b0000100 ||
                     id_ex_pIcode == 7'b0001000 || id_ex_pIcode == 7'b0001001 ||
                     id_ex_pIcode == 7'b0000110);
  
  // EX/MEM pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ex_mem_pc <= 32'h0;
      ex_mem_pIcode <= 7'h0;
      ex_mem_aluout <= 32'h0;
      ex_mem_valB <= 32'h0;
      ex_mem_rd <= 5'h0;
      ex_mem_pCnd <= 1'b0;
      ex_mem_memread <= 1'b0;
      ex_mem_memwrite <= 1'b0;
      ex_mem_funct3 <= 3'h0;
      ex_mem_regwrite <= 1'b0;
      ex_mem_pValP <= 32'h0;
    end else begin
      ex_mem_pc <= id_ex_pc;
      ex_mem_pIcode <= id_ex_pIcode;
      ex_mem_aluout <= alu_result;
      ex_mem_valB <= id_ex_valB;
      ex_mem_rd <= id_ex_rd;
      ex_mem_pCnd <= pCnd;
      ex_mem_memread <= ex_memread;
      ex_mem_memwrite <= ex_memwrite;
      ex_mem_funct3 <= id_ex_funct3;
      ex_mem_regwrite <= ex_regwrite;
      ex_mem_pValP <= pValP;
    end
  end
  
  // ==================== STAGE 4: MEMORY ACCESS ====================
  reg [31:0] mem_read_result;
  always @(*) begin
    mem_read_result = 32'h0;
    if (ex_mem_memread) begin
      mem_read_result = paddr_read(ex_mem_aluout, 4);
    end
  end
  
  always @(*) begin
    if (ex_mem_memwrite) begin
      case (ex_mem_funct3)
        3'b010: paddr_write(ex_mem_aluout, 4, ex_mem_valB);
        default: paddr_write(ex_mem_aluout, 4, ex_mem_valB);
      endcase
    end
  end
  
  reg [31:0] pValM;
  always @(*) begin
    if (ex_mem_memread) begin
      case (ex_mem_funct3)
        3'b010: pValM = mem_read_result;
        default: pValM = mem_read_result;
      endcase
    end else begin
      pValM = 32'h0;
    end
  end
  
  // MEM/WB pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mem_wb_pc <= 32'h0;
      mem_wb_pIcode <= 7'h0;
      mem_wb_pValM <= 32'h0;
      mem_wb_aluout <= 32'h0;
      mem_wb_rd <= 5'h0;
      mem_wb_regwrite <= 1'b0;
      mem_wb_memtoreg <= 1'b0;
    end else begin
      mem_wb_pc <= ex_mem_pc;
      mem_wb_pIcode <= ex_mem_pIcode;
      mem_wb_pValM <= pValM;
      mem_wb_aluout <= ex_mem_aluout;
      mem_wb_rd <= ex_mem_rd;
      mem_wb_regwrite <= ex_mem_regwrite;
      mem_wb_memtoreg <= ex_mem_memread;
    end
  end
  
  // ==================== STAGE 5: WRITE BACK ====================
  wire [31:0] wb_data = mem_wb_memtoreg ? mem_wb_pValM : mem_wb_aluout;
  
  integer i;
  
  // Initialize
  initial begin
    for (i = 0; i < 32; i = i + 1) rf[i] = 32'h0;
    pc = 32'h80000000;  // Initialize PC
    if_id_pc = 32'h80000000;
    if_id_inst = 32'h0;
    id_ex_pc = 32'h0;
    id_ex_pIcode = 7'h0;
    id_ex_rd = 5'h0;
    id_ex_valA = 32'h0;
    id_ex_valB = 32'h0;
    id_ex_pValC = 32'h0;
    id_ex_funct3 = 3'h0;
    ex_mem_pc = 32'h0;
    ex_mem_pIcode = 7'h0;
    ex_mem_aluout = 32'h0;
    ex_mem_valB = 32'h0;
    ex_mem_rd = 5'h0;
    ex_mem_pCnd = 1'b0;
    ex_mem_memread = 1'b0;
    ex_mem_memwrite = 1'b0;
    ex_mem_funct3 = 3'h0;
    ex_mem_regwrite = 1'b0;
    ex_mem_pValP = 32'h0;
    mem_wb_pc = 32'h0;
    mem_wb_pIcode = 7'h0;
    mem_wb_pValM = 32'h0;
    mem_wb_aluout = 32'h0;
    mem_wb_rd = 5'h0;
    mem_wb_regwrite = 1'b0;
    mem_wb_memtoreg = 1'b0;
  end
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < 32; i = i + 1) rf[i] <= 32'h0;
    end else if (mem_wb_regwrite && mem_wb_rd != 0) begin
      rf[mem_wb_rd] <= wb_data;
      $display("[Y86-PIPELINE-WB] Write x%0d = 0x%08h (PC=0x%08h)", 
               mem_wb_rd, wb_data, mem_wb_pc);
    end
  end
  
  // ==================== DEBUG OUTPUT ====================
  always @(posedge clk) begin
    // Remove rst_n check to avoid SYNCASYNCNET warning
    $display("=== Y86 PIPELINE CYCLE ===");
    $display("[IF] PC=0x%08h, Inst=0x%08h", pc, inst);
    $display("[ID] PC=0x%08h, pIcode=0x%02h, rd=x%0d, pValC=0x%08h, pValP=0x%08h", 
             if_id_pc, pIcode, rd, pValC, pValP);
    $display("[EX] PC=0x%08h, ALU=0x%08h, rd=x%0d, pCnd=%b", 
             id_ex_pc, alu_result, id_ex_rd, pCnd);
    $display("[MEM] PC=0x%08h, Addr=0x%08h, rd=x%0d, pValM=0x%08h", 
             ex_mem_pc, ex_mem_aluout, ex_mem_rd, pValM);
    $display("[WB] PC=0x%08h, Data=0x%08h, rd=x%0d", 
             mem_wb_pc, wb_data, mem_wb_rd);
    $display("");
    
    // Diff-test
    difftest_step(pc);
  end
  
  // Use the signals to avoid warnings
  always @(*) begin
    // Use ex_mem_pCnd, ex_mem_pValP, mem_wb_pIcode to avoid warnings
    if (ex_mem_pCnd) begin
      // This is just to use the signal
    end
    if (ex_mem_pValP != 0) begin
      // This is just to use the signal
    end
    if (mem_wb_pIcode != 0) begin
      // This is just to use the signal
    end
  end

endmodule
