// Direct pipeline test
// Tests basic pipeline flow and data hazards

void _start() {
    int result = 0;
    
    // Test 1: Simple arithmetic pipeline
    // This creates a RAW hazard that needs forwarding
    asm volatile("li x1, 100");      // x1 = 100
    asm volatile("li x2, 200");      // x2 = 200
    asm volatile("add x3, x1, x2");  // x3 = 300 (RAW hazard on x1, x2)
    asm volatile("add x4, x3, x1");  // x4 = 400 (RAW hazard on x3)
    
    // Test 2: Load-use hazard
    volatile int* mem = (volatile int*)0x1000;
    *mem = 0x12345678;
    
    asm volatile("li x5, 0x1000");
    asm volatile("lw x6, 0(x5)");    // Load from memory
    asm volatile("addi x7, x6, 1");  // Load-use hazard on x6
    
    // Test 3: Store after load
    asm volatile("sw x7, 4(x5)");    // Store to memory
    
    // Test 4: Pipeline fill with NOPs
    asm volatile("nop");
    asm volatile("nop");
    asm volatile("nop");
    asm volatile("nop");
    asm volatile("nop");
    
    // Halt
    asm volatile("ebreak");
}
