#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "memory.h"

static uint8_t pmem[MEM_SIZE];

uint8_t* guest_to_host(uint32_t addr) { return pmem + (addr - MEM_BASE); }

uint32_t paddr_read(uint32_t addr, int len) {
  if (addr < MEM_BASE || addr >= MEM_BASE + MEM_SIZE) {
    printf("[Memory] Invalid read address: 0x%08x\n", addr);
    return 0;
  }
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
  if (addr < MEM_BASE || addr >= MEM_BASE + MEM_SIZE) {
    printf("[Memory] Invalid write address: 0x%08x\n", addr);
    return;
  }
  uint8_t *p = guest_to_host(addr);
  for (int i = 0; i < len; i++) {
    p[i] = (data >> (i * 8)) & 0xff;
  }
}

void init_mem() {
  uint32_t *p = (uint32_t *)guest_to_host(MEM_BASE);
  // Hello Loop: Prints 'H', 'I', '\n'
  p[0] = 0xa00002b7; // 0x80000000: lui x5, 0xa0000 (0xa0000000)
  p[1] = 0x00300313; // 0x80000004: addi x6, x0, 3 (counter)
  p[2] = 0x04800393; // 0x80000008: addi x7, x0, 72 ('H')
  p[3] = 0x3e728c23; // 0x8000000c: sb x7, 1016(x5) (0xa00003f8)
  p[4] = 0x04900393; // 0x80000010: addi x7, x0, 73 ('I')
  p[5] = 0x3e728c23; // 0x80000014: sb x7, 1016(x5)
  p[6] = 0x00a00393; // 0x80000018: addi x7, x0, 10 ('\n')
  p[7] = 0x3e728c23; // 0x8000001c: sb x7, 1016(x5)
  p[8] = 0xfff30313; // 0x80000020: addi x6, x6, -1
  // BNE x6, x0, -24 (Target: 0x8000000c). Offset = -24.
  // IMM_B bit breakdown for -24 (0xffffffea):
  // 12: 1, 11: 1, 10:5: 111111, 4:1: 0101 (wait, let's just use raw bits)
  // -24 = 0x...FE8. In B-Type encoding: 0xfe0314e3 (Wait, let's re-verify)
  p[9] = 0xfe0314e3; // 0x80000024: bne x6, x0, -24
  p[10] = 0x00100073;// 0x80000028: ebreak
  printf("Memory initialized with Hello Loop (BNE test).\n");
}
