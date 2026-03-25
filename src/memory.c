#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "memory.h"

static uint8_t pmem[MEM_SIZE];

uint8_t* guest_to_host(uint32_t addr) { return pmem + (addr - MEM_BASE); }

uint32_t paddr_read(uint32_t addr, int len) {
  uint8_t *p = guest_to_host(addr);
  uint32_t ret = 0;
  // Little-Endian read
  for (int i = 0; i < len; i++) {
    ret |= (uint32_t)p[i] << (i * 8);
  }
  return ret;
}

void init_mem() {
  uint32_t *p = (uint32_t *)guest_to_host(MEM_BASE);
  p[0] = 0x06400093; // addi x1, x0, 100
  p[1] = 0x00108133; // add x2, x1, x1  (x2 = 200)
  p[2] = 0x401101b3; // sub x3, x2, x1  (x3 = 100)
  p[3] = 0x00100073; // ebreak
  printf("Memory initialized with R-Type/I-Type test instructions.\n");
}
