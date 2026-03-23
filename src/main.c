#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include "cpu.h"

CPU_state cpu = {.pc = 0x80000000}; // Reset vector

void cpu_exec(uint32_t n) {
  for (uint32_t i = 0; i < n; i++) {
    printf("CPU executes one cycle at PC=0x%08x\n", cpu.pc);
    cpu.pc += 4;
  }
}

int main() {
  char buf[128];
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
