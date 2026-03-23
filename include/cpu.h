#ifndef __CPU_H__
#define __CPU_H__

#include <stdint.h>

typedef uint32_t word_t;

typedef struct {
  word_t gpr[32];
  word_t pc;
} CPU_state;

extern CPU_state cpu;

#endif
