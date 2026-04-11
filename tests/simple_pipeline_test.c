#include "am.h"

void _start() {
    // Simple test: add two numbers
    int a = 5;
    int b = 3;
    int c = a + b;  // Should be 8
    
    // Store result to memory
    int *ptr = (int*)0x1000;
    *ptr = c;
    
    // Load from memory
    int d = *ptr;
    
    // Halt
    asm volatile("ebreak");
}