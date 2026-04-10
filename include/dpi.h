#ifndef __DPI_H__
#define __DPI_H__

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// DPI-C functions for Verilator simulation
int paddr_read_wrapper(int addr, int len);
void paddr_write_wrapper(int addr, int len, int data);
void difftest_step_wrapper(int dut_pc);

#ifdef __cplusplus
}
#endif

#endif // __DPI_H__