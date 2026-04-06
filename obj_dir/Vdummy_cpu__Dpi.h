// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Prototypes for DPI import and export functions.
//
// Verilator includes this file in all generated .cpp files that use DPI functions.
// Manually include this file where DPI .c import functions are declared to ensure
// the C functions match the expectations of the DPI imports.

#ifndef VERILATED_VDUMMY_CPU__DPI_H_
#define VERILATED_VDUMMY_CPU__DPI_H_  // guard

#include "svdpi.h"

#ifdef __cplusplus
extern "C" {
#endif


    // DPI IMPORTS
    // DPI import at vsrc/dummy_cpu.v:6:40
    extern void difftest_step(int dut_pc);
    // DPI import at vsrc/dummy_cpu.v:5:39
    extern int paddr_read(int addr, int len);

#ifdef __cplusplus
}
#endif

#endif  // guard
