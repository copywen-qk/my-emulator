#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include "cpu.h"
#include "memory.h"
#include "decode.h"

CPU_state cpu = {.pc = MEM_BASE}; // Reset vector

void cpu_exec(uint32_t n) {
  for (uint32_t i = 0; i < n; i++) {
    uint32_t instr = paddr_read(cpu.pc, 4);
    printf("[Fetch]  PC = 0x%08x, Instr = 0x%08x\n", cpu.pc, instr);
    printf("[Decode] Opcode = 0x%02x, rd = %d, funct3 = %d, rs1 = %d, rs2 = %d\n", 
           OPCODE(instr), RD(instr), FUNC3(instr), RS1(instr), RS2(instr));
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
