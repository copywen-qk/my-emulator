#include "am.h"

void _start() {
    // Test 1: Basic arithmetic
    int a = 10;
    int b = 20;
    int c = a + b;      // ADDI/ADD
    int d = a - b;      // SUB
    int e = a & b;      // AND
    int f = a | b;      // OR
    int g = a ^ b;      // XOR
    
    // Test 2: Shifts
    int h = a << 2;     // SLLI
    int i = a >> 1;     // SRLI
    int j = -10 >> 1;   // SRAI
    
    // Test 3: Comparisons
    int k = (a < b);    // SLTI
    int l = (a == b);   // SEQ (via XOR + SLTIU)
    
    // Test 4: Load/Store (if memory works)
    int arr[2] = {100, 200};
    int m = arr[0];     // LW
    int n = arr[1];     // LW
    arr[0] = 300;       // SW
    
    // Test 5: Control flow
    int counter = 0;
    while (counter < 5) {  // BNE, ADDI
        counter = counter + 1;
    }
    
    // If we reach here, all tests passed
    // Write success code to memory location 0x80000000
    *(volatile int*)0x80000000 = 0x12345678;
    
    // Infinite loop
    while (1) {}
}