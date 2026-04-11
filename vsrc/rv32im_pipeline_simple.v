module rv32im_pipeline_simple(
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
  
  // ==================== PIPELINE REGISTERS ====================
  
  // IF/ID registers
  reg [31:0] if_id_pc;
  reg [31:0] if_id_inst;
  
  // ID/EX registers (Y86-64 style)
  reg [31:0] id_ex_pc;
  reg [6:0]  id_ex_icode;    // instruction code
  reg [4:0]  id_ex_rd;       // destination register
  reg [31:0] id_ex_valA;     // value from register A
  reg [31:0] id_ex_valB;     // value from register B
  reg [31:0] id_ex_valC;     // constant value (immediate)
  reg [2:0]  id_ex_funct3;
  reg [6:0]  id_ex_funct7;
  
  // EX/MEM registers
  reg [31:0] ex_mem_pc;
  reg [6:0]  ex_mem_icode;
  reg [31:0] ex_mem_aluout;  // ALU result
  reg [31:0] ex_mem_valB;    // value for store
  reg [4:0]  ex_mem_rd;
  reg        ex_mem_cnd;     // condition code
  reg        ex_mem_memread;
  reg        ex_mem_memwrite;
  reg [2:0]  ex_mem_funct3;
  reg        ex_mem_regwrite;
  reg [31:0] ex_mem_valP;    // next PC value
  
  // MEM/WB registers
  reg [31:0] mem_wb_pc;
  reg [6:0]  mem_wb_icode;
  reg [31:0] mem_wb_valM;    // value from memory
  reg [31:0] mem_wb_aluout;
  reg [4:0]  mem_wb_rd;
  reg        mem_wb_regwrite;
  reg        mem_wb_memtoreg;
  
  // ==================== STAGE 1: INSTRUCTION FETCH ====================
  wire [31:0] inst = paddr_read(pc, 4);
  wire [31:0] next_pc = pc + 4;
  
  // IF/ID pipeline register
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
  wire [6:0]  funct7 = if_id_inst[31:25];
  
  // Register read
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
  
  // Map RISC-V opcode to Y86-64 style icode
  reg [6:0] icode;
  always @(*) begin
    case (opcode)
      7'b0110111: icode = 7'b0000001; // LUI
      7'b0010111: icode = 7'b0000010; // AUIPC
      7'b1101111: icode = 7'b0000011; // JAL
      7'b1100111: icode = 7'b0000100; // JALR
      7'b1100011: icode = 7'b0000101; // Branch
      7'b0000011: icode = 7'b0000110; // Load
      7'b0100011: icode = 7'b0000111; // Store
      7'b0010011: icode = 7'b0001000; // OP-IMM
      7'b0110011: icode = 7'b0001001; // OP
      default:    icode = 7'b0000000; // NOP
    endcase
  end
  
  // Select valC based on instruction type
  reg [31:0] valC;
  always @(*) begin
    case (opcode)
      7'b0010011, 7'b0000011, 7'b1100111: valC = imm_i; // OP-IMM, Load, JALR
      7'b0100011: valC = imm_s;                         // Store
      7'b1100011: valC = imm_b;                         // Branch
      7'b0110111, 7'b0010111: valC = imm_u;             // LUI, AUIPC
      7'b1101111: valC = imm_j;                         // JAL
      default: valC = 32'h0;
    endcase
  end
  
  // ID/EX pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id_ex_pc <= 32'h0;
      id_ex_icode <= 7'h0;
      id_ex_rd <= 5'h0;
      id_ex_valA <= 32'h0;
      id_ex_valB <= 32'h0;
      id_ex_valC <= 32'h0;
      id_ex_funct3 <= 3'h0;
      id_ex_funct7 <= 7'h0;
    end else begin
      id_ex_pc <= if_id_pc;
      id_ex_icode <= icode;
      id_ex_rd <= rd;
      id_ex_valA <= rs1_val;
      id_ex_valB <= rs2_val;
      id_ex_valC <= valC;
      id_ex_funct3 <= funct3;
      id_ex_funct7 <= funct7;
    end
  end
  
  // ==================== STAGE 3: EXECUTE ====================
  // ALU inputs
  wire [31:0] alu_a = id_ex_valA;
  wire [31:0] alu_b = (id_ex_icode == 7'b0001000 ||  // OP-IMM
                       id_ex_icode == 7'b0000110 ||  // Load
                       id_ex_icode == 7'b0000100 ||  // JALR
                       id_ex_icode == 7'b0000111) ?  // Store
                      id_ex_valC : id_ex_valB;
  
  // ALU operation
  reg [31:0] alu_result;
  reg        alu_zero;
  
  always @(*) begin
    alu_result = 32'h0;
    alu_zero = 1'b0;
    
    if (id_ex_icode == 7'b0001000 || id_ex_icode == 7'b0001001) begin
      // OP-IMM or OP
      case (id_ex_funct3)
        3'b000: alu_result = alu_a + alu_b;  // ADD/ADDI
        3'b001: alu_result = alu_a << alu_b[4:0]; // SLL/SLLI
        3'b010: alu_result = ($signed(alu_a) < $signed(alu_b)) ? 32'h1 : 32'h0;
        3'b011: alu_result = (alu_a < alu_b) ? 32'h1 : 32'h0;
        3'b100: alu_result = alu_a ^ alu_b;  // XOR/XORI
        3'b101: alu_result = (id_ex_funct7[5]) ? 
                            $signed(alu_a) >>> alu_b[4:0] : // SRA/SRAI
                            alu_a >> alu_b[4:0];           // SRL/SRLI
        3'b110: alu_result = alu_a | alu_b;  // OR/ORI
        3'b111: alu_result = alu_a & alu_b;  // AND/ANDI
      endcase
    end else if (id_ex_icode == 7'b0000101) begin
      // Branch instructions
      case (id_ex_funct3)
        3'b000: alu_zero = (id_ex_valA == id_ex_valB);  // BEQ
        3'b001: alu_zero = (id_ex_valA != id_ex_valB);  // BNE
        3'b100: alu_zero = ($signed(id_ex_valA) < $signed(id_ex_valB)); // BLT
        3'b101: alu_zero = ($signed(id_ex_valA) >= $signed(id_ex_valB)); // BGE
        3'b110: alu_zero = (id_ex_valA < id_ex_valB);   // BLTU
        3'b111: alu_zero = (id_ex_valA >= id_ex_valB);  // BGEU
      endcase
    end else if (id_ex_icode == 7'b0000001) begin
      // LUI
      alu_result = id_ex_valC;
    end else if (id_ex_icode == 7'b0000010) begin
      // AUIPC
      alu_result = id_ex_pc + id_ex_valC;
    end else if (id_ex_icode == 7'b0000011 || id_ex_icode == 7'b0000100) begin
      // JAL or JALR
      alu_result = id_ex_pc + 4;  // return address
    end else if (id_ex_icode == 7'b0000110 || id_ex_icode == 7'b0000111) begin
      // Load or Store address calculation
      alu_result = id_ex_valA + id_ex_valC;
    end
  end
  
  // Calculate valP (next PC)
  wire [31:0] valP = id_ex_pc + 4;
  
  // Control signals
  wire ex_memread  = (id_ex_icode == 7'b0000110);
  wire ex_memwrite = (id_ex_icode == 7'b0000111);
  wire ex_regwrite = (id_ex_icode == 7'b0000001 || id_ex_icode == 7'b0000010 ||
                     id_ex_icode == 7'b0000011 || id_ex_icode == 7'b0000100 ||
                     id_ex_icode == 7'b0001000 || id_ex_icode == 7'b0001001 ||
                     id_ex_icode == 7'b0000110);
  
  // EX/MEM pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ex_mem_pc <= 32'h0;
      ex_mem_icode <= 7'h0;
      ex_mem_aluout <= 32'h0;
      ex_mem_valB <= 32'h0;
      ex_mem_rd <= 5'h0;
      ex_mem_cnd <= 1'b0;
      ex_mem_memread <= 1'b0;
      ex_mem_memwrite <= 1'b0;
      ex_mem_funct3 <= 3'h0;
      ex_mem_regwrite <= 1'b0;
      ex_mem_valP <= 32'h0;
    end else begin
      ex_mem_pc <= id_ex_pc;
      ex_mem_icode <= id_ex_icode;
      ex_mem_aluout <= alu_result;
      ex_mem_valB <= id_ex_valB;
      ex_mem_rd <= id_ex_rd;
      ex_mem_cnd <= alu_zero;
      ex_mem_memread <= ex_memread;
      ex_mem_memwrite <= ex_memwrite;
      ex_mem_funct3 <= id_ex_funct3;
      ex_mem_regwrite <= ex_regwrite;
      ex_mem_valP <= valP;
    end
  end
  
  // ==================== STAGE 4: MEMORY ACCESS ====================
  // Memory read
  reg [31:0] mem_read_result;
  always @(*) begin
    mem_read_result = 32'h0;
    if (ex_mem_memread) begin
      mem_read_result = paddr_read(ex_mem_aluout, 4);
    end
  end
  
  // Memory write
  always @(*) begin
    if (ex_mem_memwrite) begin
      case (ex_mem_funct3)
        3'b000: paddr_write(ex_mem_aluout, 1, ex_mem_valB[7:0]);    // SB
        3'b001: paddr_write(ex_mem_aluout, 2, ex_mem_valB[15:0]);   // SH
        3'b010: paddr_write(ex_mem_aluout, 4, ex_mem_valB);         // SW
      endcase
    end
  end
  
  // Memory data processing for Load instructions
  reg [31:0] mem_valM;
  always @(*) begin
    if (ex_mem_memread) begin
      case (ex_mem_funct3)
        3'b000: mem_valM = {{24{mem_read_result[7]}}, mem_read_result[7:0]};   // LB
        3'b001: mem_valM = {{16{mem_read_result[15]}}, mem_read_result[15:0]}; // LH
        3'b010: mem_valM = mem_read_result;                                    // LW
        3'b100: mem_valM = {24'b0, mem_read_result[7:0]};                     // LBU
        3'b101: mem_valM = {16'b0, mem_read_result[15:0]};                    // LHU
        default: mem_valM = 32'h0;
      endcase
    end else begin
      mem_valM = 32'h0;
    end
  end
  
  // MEM/WB pipeline register
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mem_wb_pc <= 32'h0;
      mem_wb_icode <= 7'h0;
      mem_wb_valM <= 32'h0;
      mem_wb_aluout <= 32'h0;
      mem_wb_rd <= 5'h0;
      mem_wb_regwrite <= 1'b0;
      mem_wb_memtoreg <= 1'b0;
    end else begin
      mem_wb_pc <= ex_mem_pc;
      mem_wb_icode <= ex_mem_icode;
      mem_wb_valM <= mem_valM;
      mem_wb_aluout <= ex_mem_aluout;
      mem_wb_rd <= ex_mem_rd;
      mem_wb_regwrite <= ex_mem_regwrite;
      mem_wb_memtoreg <= ex_mem_memread;
    end
  end
  
  // ==================== STAGE 5: WRITE BACK ====================
  wire [31:0] wb_data = mem_wb_memtoreg ? mem_wb_valM : mem_wb_aluout;
  
  // Register write back
  integer i;
  
  initial begin
    // Initialize register file
    for (i = 0; i < 32; i = i + 1) rf[i] = 32'h0;
    
    // Initialize pipeline registers
    if_id_pc = 32'h80000000;
    if_id_inst = 32'h0;
    
    id_ex_pc = 32'h0;
    id_ex_icode = 7'h0;
    id_ex_rd = 5'h0;
    id_ex_valA = 32'h0;
    id_ex_valB = 32'h0;
    id_ex_valC = 32'h0;
    id_ex_funct3 = 3