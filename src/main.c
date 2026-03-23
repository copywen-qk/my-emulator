#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include "cpu.h"
#include "memory.h"

CPU_state cpu = {.pc = MEM_BASE}; // Reset vector

void cpu_exec(uint32_t n) {
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
        printf("[Execute] ADDI x%d, x%d, %d -> x%d = %d\n", rd, rs1, imm, rd, cpu.gpr[rd]);
        break;
      default:
        printf("[Execute] Unknown opcode: 0x%02x\n", opcode);
    }
    
    cpu.pc += 4;
  }
}

int main() {
  char buf[128];
  init_mem();
  printf("Welcome to NEMU-RV32! Type 'q' to quit, 'c' to execute a cycle.\n");

  while (true) {
    printf("(nemu) ");
    if (fgets(buf, sizeof(buf), stdin) == NULL) break;

    char *token = strtok(buf, " \n");
    if (token == NULL) continue;

    if (strcmp(token, "q") == 0) {
      break;
    } else if (strcmp(token, "c") == 0) {
      cpu_exec(1);
    } else {
      printf("Unknown command: %s\n", token);
    }
  }

  return 0;
}
