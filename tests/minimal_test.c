#include "am.h"

// Minimal test: just do some arithmetic and store result
void _start() {
    // Simple arithmetic test
    int result = 0;
    
    // Test ADDI: 1 + 2 = 3
    result = 1 + 2;
    
    // Test store result to memory
    *(volatile int*)0x80001000 = result;
    
    // If result == 3, write success code
    if (result == 3) {
        *(volatile int*)0x80000000 = 0xDEADBEEF;
    } else {
        *(volatile int*)0x80000000 = 0xBADBAD00;
    }
    
    // Halt
    while (1) {}
}