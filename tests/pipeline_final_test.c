// Simple test for final pipeline implementation
void _start() {
    // Test 1: Basic arithmetic
    int a = 10;
    int b = 20;
    int c = a + b;  // Should be 30
    
    // Test 2: Memory access
    int *ptr = (int*)0x1000;
    *ptr = c;
    
    // Test 3: Load back
    int d = *ptr;
    
    // Test 4: Loop
    int sum = 0;
    for (int i = 0; i < 5; i++) {
        sum += i;
    }
    
    // Halt
    asm volatile("ebreak");
}
