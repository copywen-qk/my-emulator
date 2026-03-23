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
  p[0] = 0x00000297; // auipc t0, 0
  p[1] = 0x00028823; // sb zero, 16(t0)
  printf("Memory initialized at 0x%08x with guest image.\n", MEM_BASE);
}
