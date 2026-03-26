#ifndef __CPU_H__
#define __CPU_H__

#include <stdint.h>

typedef uint32_t word_t;

typedef struct {
  word_t gpr[32];
  word_t pc;
  int state;
} CPU_state;

enum { NEMU_RUNNING, NEMU_STOP, NEMU_END };

extern CPU_state cpu;

// Extract bits [hi, lo] from x
#define BITS(x, hi, lo) (((x) >> (lo)) & ((1U << ((hi) - (lo) + 1)) - 1))

// RISC-V fields
#define OPCODE(i) BITS(i, 6, 0)
#define RD(i)     BITS(i, 11, 7)
#define FUNC3(i)  BITS(i, 14, 12)
#define RS1(i)    BITS(i, 19, 15)
#define RS2(i)    BITS(i, 24, 20)
#define FUNC7(i)  BITS(i, 31, 25)
#define SHAMT(i)  BITS(i, 24, 20)
#define IMM_I(i)  BITS(i, 31, 20)
#define IMM_S(i)  ((BITS(i, 31, 25) << 5) | BITS(i, 11, 7))
#define IMM_U(i)  (i & 0xfffff000)
#define IMM_B(i)  ((BITS(i, 31, 31) << 12) | (BITS(i, 7, 7) << 11) | (BITS(i, 30, 25) << 5) | (BITS(i, 11, 8) << 1))
#define IMM_J(i)  ((BITS(i, 31, 31) << 20) | (BITS(i, 19, 12) << 12) | (BITS(i, 20, 20) << 11) | (BITS(i, 30, 21) << 1))

static inline int32_t sext(uint32_t x, int len) {
  int32_t res = (int32_t)x;
  return (res << (32 - len)) >> (32 - len);
}

#endif
