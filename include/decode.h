#ifndef __DECODE_H__
#define __DECODE_H__

#include <stdint.h>

// Extract bits [hi, lo] from x
#define BITS(x, hi, lo) (((x) >> (lo)) & ((1U << ((hi) - (lo) + 1)) - 1))

// RISC-V fields
#define OPCODE(i) BITS(i, 6, 0)
#define RD(i)     BITS(i, 11, 7)
#define FUNC3(i)  BITS(i, 14, 12)
#define RS1(i)    BITS(i, 19, 15)
#define RS2(i)    BITS(i, 24, 20)
#define FUNC7(i)  BITS(i, 31, 25)

#endif
