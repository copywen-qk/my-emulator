#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include "cpu.h"
#include "memory.h"
#include "device.h"

CPU_state cpu = {.pc = MEM_BASE, .state = NEMU_STOP}; // Reset vector

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

void nemu_step() {
  uint32_t instr = paddr_read(cpu.pc, 4);
  uint32_t opcode = OPCODE(instr);
  uint32_t rd = RD(instr);
  uint32_t rs1 = RS1(instr);
  uint32_t rs2 = RS2(instr);
  uint32_t next_pc = cpu.pc + 4;

  fprintf(stderr, "[Fetch]   PC = 0x%08x, Instr = 0x%08x\n", cpu.pc, instr);
  
  switch (opcode) {
    case 0x03: { // Load
      int32_t imm = sext(IMM_I(instr), 12);
      uint32_t funct3 = FUNC3(instr);
      uint32_t addr = cpu.gpr[rs1] + imm;
      switch (funct3) {
        case 0: cpu.gpr[rd] = (word_t)sext(paddr_read(addr, 1), 8); break;  // LB
        case 1: cpu.gpr[rd] = (word_t)sext(paddr_read(addr, 2), 16); break; // LH
        case 2: cpu.gpr[rd] = paddr_read(addr, 4); break;           // LW
        case 4: cpu.gpr[rd] = paddr_read(addr, 1); break;           // LBU
        case 5: cpu.gpr[rd] = paddr_read(addr, 2); break;           // LHU
        default: fprintf(stderr, "[Execute] Unknown Load funct3: %d\n", funct3);
      }
      break;
    }
    case 0x13: { // OP-IMM
      int32_t imm = sext(IMM_I(instr), 12);
      uint32_t funct3 = FUNC3(instr);
      uint32_t shamt = SHAMT(instr);
      switch (funct3) {
        case 0: cpu.gpr[rd] = cpu.gpr[rs1] + imm; break; // ADDI
        case 4: cpu.gpr[rd] = cpu.gpr[rs1] ^ imm; break; // XORI
        case 6: cpu.gpr[rd] = cpu.gpr[rs1] | imm; break; // ORI
        case 7: cpu.gpr[rd] = cpu.gpr[rs1] & imm; break; // ANDI
        case 1: cpu.gpr[rd] = cpu.gpr[rs1] << shamt; break; // SLLI
        case 5:
          if (BITS(instr, 31, 30) == 0) cpu.gpr[rd] = cpu.gpr[rs1] >> shamt; // SRLI
          else cpu.gpr[rd] = (word_t)((int32_t)cpu.gpr[rs1] >> shamt); // SRAI
          break;
        default: fprintf(stderr, "[Execute] Unknown OP-IMM funct3: %d\n", funct3);
      }
      break;
    }
    case 0x17: { // AUIPC
      uint32_t u_imm = IMM_U(instr);
      cpu.gpr[rd] = cpu.pc + u_imm;
      fprintf(stderr, "[Execute] AUIPC x%d (%s), 0x%08x -> x%d = 0x%08x\n", rd, regs[rd], u_imm, rd, cpu.gpr[rd]);
      break;
    }
    case 0x33: { // OP (R-Type)
      uint32_t funct3 = FUNC3(instr);
      uint32_t funct7 = FUNC7(instr);
      if (funct7 == 1) { // RV32M Extension
        switch (funct3) {
          case 0: cpu.gpr[rd] = cpu.gpr[rs1] * cpu.gpr[rs2]; break; // MUL
          case 1: cpu.gpr[rd] = (word_t)(((int64_t)(int32_t)cpu.gpr[rs1] * (int64_t)(int32_t)cpu.gpr[rs2]) >> 32); break; // MULH
          case 2: cpu.gpr[rd] = (word_t)(((int64_t)(int32_t)cpu.gpr[rs1] * (uint64_t)cpu.gpr[rs2]) >> 32); break; // MULHSU
          case 3: cpu.gpr[rd] = (word_t)(((uint64_t)cpu.gpr[rs1] * (uint64_t)cpu.gpr[rs2]) >> 32); break; // MULHU
          case 4: cpu.gpr[rd] = (cpu.gpr[rs2] == 0) ? 0xFFFFFFFFU : (word_t)((int32_t)cpu.gpr[rs1] / (int32_t)cpu.gpr[rs2]); break; // DIV
          case 5: cpu.gpr[rd] = (cpu.gpr[rs2] == 0) ? 0xFFFFFFFFU : cpu.gpr[rs1] / cpu.gpr[rs2]; break; // DIVU
          case 6: cpu.gpr[rd] = (cpu.gpr[rs2] == 0) ? cpu.gpr[rs1] : (word_t)((int32_t)cpu.gpr[rs1] % (int32_t)cpu.gpr[rs2]); break; // REM
          case 7: cpu.gpr[rd] = (cpu.gpr[rs2] == 0) ? cpu.gpr[rs1] : cpu.gpr[rs1] % cpu.gpr[rs2]; break; // REMU
        }
      } else { // Standard R-Type
        switch (funct3) {
          case 0:
            if (funct7 == 0) cpu.gpr[rd] = cpu.gpr[rs1] + cpu.gpr[rs2]; // ADD
            else cpu.gpr[rd] = cpu.gpr[rs1] - cpu.gpr[rs2]; // SUB
            break;
          case 1: cpu.gpr[rd] = cpu.gpr[rs1] << (cpu.gpr[rs2] & 0x1f); break; // SLL
          case 2: cpu.gpr[rd] = ((int32_t)cpu.gpr[rs1] < (int32_t)cpu.gpr[rs2]) ? 1 : 0; break; // SLT
          case 3: cpu.gpr[rd] = (cpu.gpr[rs1] < cpu.gpr[rs2]) ? 1 : 0; break; // SLTU
          case 4: cpu.gpr[rd] = cpu.gpr[rs1] ^ cpu.gpr[rs2]; break; // XOR
          case 5:
            if (funct7 == 0) cpu.gpr[rd] = cpu.gpr[rs1] >> (cpu.gpr[rs2] & 0x1f); // SRL
            else cpu.gpr[rd] = (word_t)((int32_t)cpu.gpr[rs1] >> (cpu.gpr[rs2] & 0x1f)); // SRA
            break;
          case 6: cpu.gpr[rd] = cpu.gpr[rs1] | cpu.gpr[rs2]; break; // OR
          case 7: cpu.gpr[rd] = cpu.gpr[rs1] & cpu.gpr[rs2]; break; // AND
        }
      }
      break;
    }
    case 0x37: // LUI
      cpu.gpr[rd] = IMM_U(instr);
      fprintf(stderr, "[Execute] LUI x%d (%s), 0x%08x\n", rd, regs[rd], cpu.gpr[rd]);
      break;
    case 0x23: { // Store
      uint32_t funct3 = FUNC3(instr);
      int32_t s_imm = sext(IMM_S(instr), 12);
      uint32_t addr = cpu.gpr[rs1] + (word_t)s_imm;
      switch (funct3) {
        case 0: paddr_write(addr, 1, cpu.gpr[rs2]); break; // SB
        case 1: paddr_write(addr, 2, cpu.gpr[rs2]); break; // SH
        case 2: paddr_write(addr, 4, cpu.gpr[rs2]); break; // SW
        default: fprintf(stderr, "[Execute] Unknown Store funct3: %d\n", funct3);
      }
      break;
    }
    case 0x67: { // JALR
      int32_t i_imm = sext(IMM_I(instr), 12);
      uint32_t temp_ret = cpu.pc + 4;
      next_pc = (cpu.gpr[rs1] + (word_t)i_imm) & ~1U;
      cpu.gpr[rd] = temp_ret;
      fprintf(stderr, "[Execute] JALR x%d (%s), x%d (%s), %d -> next_pc = 0x%08x\n", rd, regs[rd], rs1, regs[rs1], i_imm, next_pc);
      break;
    }
    case 0x6f: { // JAL
      int32_t j_imm = sext(IMM_J(instr), 21);
      cpu.gpr[rd] = cpu.pc + 4;
      next_pc = cpu.pc + (word_t)j_imm;
      fprintf(stderr, "[Execute] JAL x%d (%s), offset %d -> next_pc = 0x%08x\n", rd, regs[rd], j_imm, next_pc);
      break;
    }
    case 0x63: { // Branch
      uint32_t funct3 = FUNC3(instr);
      int32_t b_imm = sext(IMM_B(instr), 13);
      bool taken = false;
      switch (funct3) {
        case 0: taken = (cpu.gpr[rs1] == cpu.gpr[rs2]); break; // BEQ
        case 1: taken = (cpu.gpr[rs1] != cpu.gpr[rs2]); break; // BNE
        case 4: taken = ((int32_t)cpu.gpr[rs1] < (int32_t)cpu.gpr[rs2]); break;  // BLT
        case 5: taken = ((int32_t)cpu.gpr[rs1] >= (int32_t)cpu.gpr[rs2]); break; // BGE
        case 6: taken = (cpu.gpr[rs1] < cpu.gpr[rs2]); break;  // BLTU
        case 7: taken = (cpu.gpr[rs1] >= cpu.gpr[rs2]); break; // BGEU
      }
      if (taken) next_pc = cpu.pc + (word_t)b_imm;
      break;
    }
    case 0x73: { // SYSTEM
      int csr_no = IMM_I(instr);
      uint32_t funct3 = FUNC3(instr);
      if (funct3 == 0) {
        // Privileged instructions (ECALL/EBREAK/MRET)
        switch (csr_no) {
          case 0x000: // ECALL
            cpu.mepc = cpu.pc;
            cpu.mcause = 11; // Machine environment call
            next_pc = cpu.mtvec;
            fprintf(stderr, "[Trap]    ECALL at PC = 0x%08x, jump to mtvec = 0x%08x\n", cpu.pc, next_pc);
            break;
          case 0x001: // EBREAK
            cpu.mepc = cpu.pc;
            cpu.mcause = 3;  // Breakpoint
            next_pc = cpu.mtvec;
            fprintf(stderr, "[Trap]    EBREAK at PC = 0x%08x, jump to mtvec = 0x%08x\n", cpu.pc, next_pc);
            break;
          case 0x302: // MRET
            next_pc = cpu.mepc;
            fprintf(stderr, "[Trap]    MRET from PC = 0x%08x, return to mepc = 0x%08x\n", cpu.pc, next_pc);
            break;
          default:
            fprintf(stderr, "[Execute] Unknown privileged instruction: 0x%03x\n", csr_no);
        }
      } else {
        word_t t = csr_read(csr_no);
        word_t zimm = rs1;
        switch (funct3) {
          case 1: csr_write(csr_no, cpu.gpr[rs1]); break; // CSRRW
          case 2: if (rs1 != 0) csr_write(csr_no, t | cpu.gpr[rs1]); break; // CSRRS
          case 3: if (rs1 != 0) csr_write(csr_no, t & ~cpu.gpr[rs1]); break; // CSRRC
          case 5: csr_write(csr_no, zimm); break; // CSRRWI
          case 6: if (zimm != 0) csr_write(csr_no, t | zimm); break; // CSRRSI
          case 7: if (zimm != 0) csr_write(csr_no, t & ~zimm); break; // CSRRCI
        }
        if (rd != 0) cpu.gpr[rd] = t;
      }
      break;
    }
    default:
      fprintf(stderr, "[Execute] Unknown opcode: 0x%02x\n", opcode);
      cpu.state = NEMU_STOP;
  }
  
  if (rd == 0) cpu.gpr[0] = 0;
  cpu.pc = next_pc;
}

uint32_t nemu_get_reg(int id) {
  if (id >= 0 && id < 32) return cpu.gpr[id];
  if (id == 32) return cpu.pc;
  return 0;
}

void difftest_step(uint32_t dut_pc) {
  if (dut_pc != cpu.pc) {
    fprintf(stderr, "[DiffTest] PC mismatch! DUT: 0x%08x, REF: 0x%08x\n", dut_pc, cpu.pc);
    exit(1);
  }
  nemu_step();
}

word_t csr_read(int csr_no) {
  switch (csr_no) {
    case CSR_MSTATUS: return cpu.mstatus;
    case CSR_MTVEC:   return cpu.mtvec;
    case CSR_MEPC:    return cpu.mepc;
    case CSR_MCAUSE:  return cpu.mcause;
    default: return 0;
  }
}

void csr_write(int csr_no, word_t val) {
  switch (csr_no) {
    case CSR_MSTATUS: cpu.mstatus = val; break;
    case CSR_MTVEC:   cpu.mtvec = val; break;
    case CSR_MEPC:    cpu.mepc = val; break;
    case CSR_MCAUSE:  cpu.mcause = val; break;
  }
}

void cpu_exec(uint32_t n) {
  cpu.state = NEMU_RUNNING;
  for (uint32_t i = 0; i < n; i++) {
    nemu_step();
    if (i % 1024 == 0) device_update();
    if (cpu.state != NEMU_RUNNING) break;
  }
}

#ifndef CONFIG_VERILATOR
int main(int argc, char *argv[]) {
  char buf[128];
  init_device();
  cpu.gpr[2] = MEM_BASE + MEM_SIZE;
  if (argc > 1) {
    load_image(argv[1]);
  } else {
    load_image(NULL);
  }
  fprintf(stderr, "Welcome to NEMU-RV32! Type 'q' to quit, 'c' to execute, 'info r' to inspect.\n");

  while (true) {
    fprintf(stderr, "\033[32m[Guest Output]:\033[0m ");
    fflush(stdout); 
    // This is just a visual hint; real output happens in paddr_write
    fprintf(stderr, "\n(nemu) ");
    if (fgets(buf, sizeof(buf), stdin) == NULL) break;

    char *token = strtok(buf, " \n");
    if (token == NULL) continue;

    if (strcmp(token, "q") == 0) {
      break;
    } else if (strcmp(token, "c") == 0) {
      cpu_exec(-1);
    } else if (strcmp(token, "info") == 0) {
      char *arg = strtok(NULL, " \n");
      if (arg != NULL && strcmp(arg, "r") == 0) {
        for (int i = 0; i < 32; i++) {
          fprintf(stderr, "%-4s (%-3s): 0x%08x (%d)\n", 
                 (char[]){'x', (i/10)+'0', (i%10)+'0', '\0'}, regs[i], cpu.gpr[i], cpu.gpr[i]);
        }
        fprintf(stderr, "%-10s: 0x%08x (%d)\n", "pc", cpu.pc, cpu.pc);
      }
    } else {
      fprintf(stderr, "Unknown command: %s\n", token);
    }
  }

  return 0;
}
#endif
