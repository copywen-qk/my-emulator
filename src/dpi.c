#include <stdio.h>
#include "cpu.h"
#include "memory.h"
#include "dpi.h"

// Global CPU state (defined in main.c)
extern CPU_state cpu;

// DPI-C wrapper for memory read
int paddr_read_wrapper(int addr, int len) {
    return (int)paddr_read((uint32_t)addr, len);
}

// DPI-C wrapper for memory write
void paddr_write_wrapper(int addr, int len, int data) {
    paddr_write((uint32_t)addr, len, (uint32_t)data);
}

// DPI-C wrapper for diff-test
void difftest_step_wrapper(int dut_pc) {
    // For now, we'll just compare the PC
    // In a full implementation, this would compare all registers
    static int step_count = 0;
    
    if (step_count == 0) {
        // First step: execute one instruction in NEMU
        nemu_step();
    }
    
    // Compare PC
    if (dut_pc != cpu.pc) {
        fprintf(stderr, "[DiffTest] Mismatch at step %d: DUT PC = 0x%08x, REF PC = 0x%08x\n", 
                step_count, dut_pc, cpu.pc);
        // In a real implementation, we might exit here
    } else {
        fprintf(stderr, "[DiffTest] Step %d: PC match at 0x%08x\n", step_count, dut_pc);
    }
    
    // Execute next instruction for next comparison
    nemu_step();
    step_count++;
}