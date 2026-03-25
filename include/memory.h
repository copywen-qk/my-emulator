#ifndef __MEMORY_H__
#define __MEMORY_H__

#include <stdint.h>

#define MEM_SIZE (128 * 1024 * 1024)
#define MEM_BASE 0x80000000
#define SERIAL_PORT 0xa00003f8

uint32_t paddr_read(uint32_t addr, int len);
void paddr_write(uint32_t addr, int len, uint32_t data);
void init_mem();

#endif
