#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include "cpu.h"
#include "memory.h"

CPU_state cpu = {.pc = MEM_BASE, .state = NEMU_STOP}; // Reset vector

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

void cpu_exec(uint32_t n) {
  cpu.state = NEMU_RUNNING;
  for (uint32_t i = 0; i < n; i++) {
    uint32_t instr = paddr_read(cpu.pc, 4);
    uint32_t opcode = OPCODE(instr);
    uint32_t rd = RD(instr);
    uint32_t rs1 = RS1(instr);
    int32_t imm = sext(IMM_I(instr), 12);

    printf("[Fetch]   PC = 0x%08x, Instr = 0x%08x\n", cpu.pc, instr);
    
    switch (opcode) {
      case 0x13: // OP-IMM
        if (rd != 0) {
          cpu.gpr[rd] = cpu.gpr[rs1] + imm;
        }
        printf("[Execute] ADDI x%d (%s), x%d (%s), %d -> x%d = %d\n", 
               rd, regs[rd], rs1, regs[rs1], imm, rd, cpu.gpr[rd]);
        break;
      case 0x73: // SYSTEM
        if (instr == 0x00100073) {
          printf("[Trap]    Program Execution Halted (EBREAK) at PC = 0x%08x\n", cpu.pc);
          cpu.state = NEMU_END;
        }
        break;
      default:
        printf("[Execute] Unknown opcode: 0x%02x\n", opcode);
        cpu.state = NEMU_STOP;
    }
    
    cpu.pc += 4;
    if (cpu.state != NEMU_RUNNING) break;
  }
}

int main() {
  char buf[128];
  init_mem();
  printf("Welcome to NEMU-RV32! Type 'q' to quit, 'c' to execute, 'info r' to inspect.\n");

  while (true) {
    printf("(nemu) ");
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
          printf("%-4s (%-3s): 0x%08x (%d)\n", 
                 (char[]){'x', (i/10)+'0', (i%10)+'0', '\0'}, regs[i], cpu.gpr[i], cpu.gpr[i]);
        }
        printf("%-10s: 0x%08x (%d)\n", "pc", cpu.pc, cpu.pc);
      }
    } else {
      printf("Unknown command: %s\n", token);
    }
  }

  return 0;
}
