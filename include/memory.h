#ifndef __MEMORY_H__
#define __MEMORY_H__

#include <stdint.h>

#define MEM_SIZE (128 * 1024 * 1024)
#define MEM_BASE 0x80000000

uint32_t paddr_read(uint32_t addr, int len);
void init_mem();

#endif
