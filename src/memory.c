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

void paddr_write(uint32_t addr, int len, uint32_t data) {
  if (addr == SERIAL_PORT) {
    putchar((char)data);
    fflush(stdout);
    return;
  }
  uint8_t *p = guest_to_host(addr);
  for (int i = 0; i < len; i++) {
    p[i] = (data >> (i * 8)) & 0xff;
  }
}

void init_mem() {
  uint32_t *p = (uint32_t *)guest_to_host(MEM_BASE);
  p[0] = 0xa00002b7; // lui t0, 0xa0000
  p[1] = 0x04800313; // addi t1, x0, 72  ('H')
  p[2] = 0x3f828823; // sb t1, 0x3f8(t0)
  p[3] = 0x00100073; // ebreak
  printf("Memory initialized with LUI + SB (MMIO) test instructions.\n");
}
