// Complete pipeline test program
void _start() {
    // Test 1: Basic arithmetic with dependencies
    int a = 10;
    int b = 20;
    int c = a + b;      // RAW hazard: a and b used immediately
    
    // Test 2: Chain of dependencies
    int d = c + 5;      // Forwarding from previous instruction
    int e = d * 2;      // Another dependency
    
    // Test 3: Memory operations
    int *ptr = (int*)0x1000;
    *ptr = e;           // Store
    
    // Test 4: Load-use hazard
    int f = *ptr;       // Load followed by use
    
    // Test 5: Use loaded value
    int g = f + 1;
    
    // Store final result
    int *result = (int*)0x2000;
    *result = g;
    
    // Halt
    asm volatile("ebreak");
}
