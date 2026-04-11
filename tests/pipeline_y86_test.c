#include "am.h"

void _start() {
    // Test 1: Simple arithmetic
    int a = 10;
    int b = 20;
    int c = a + b;  // Should be 30
    
    // Test 2: Memory operations
    int array[4] = {1, 2, 3, 4};
    int sum = array[0] + array[1] + array[2] + array[3];  // Should be 10
    
    // Test 3: Branch
    int result = 0;
    if (c > sum) {
        result = 1;  // Should be 1 (30 > 10)
    } else {
        result = 0;
    }
    
    // Test 4: Loop
    int loop_sum = 0;
    for (int i = 0; i < 5; i++) {
        loop_sum += i;  // Should be 10 (0+1+2+3+4)
    }
    
    // Halt
    asm volatile("ebreak");
}