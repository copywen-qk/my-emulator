// Test program for pipeline forwarding and hazard detection
// This test creates RAW (Read-After-Write) hazards to test forwarding logic

#include <stdint.h>

// Simple putchar for debugging
void putchar(char c) {
  volatile char *tx = (volatile char *)0x10000000;
  *tx = c;
}

void print_hex(uint32_t val) {
  for (int i = 7; i >= 0; i--) {
    uint8_t nibble = (val >> (i * 4)) & 0xF;
    putchar(nibble < 10 ? '0' + nibble : 'A' + nibble - 10);
  }
}

void print_str(const char *str) {
  while (*str) {
    putchar(*str++);
  }
}

// Test 1: Simple RAW hazard (back-to-back dependent instructions)
void test1_raw_hazard() {
  print_str("Test 1: RAW hazard (ADD -> ADD)\n");
  
  uint32_t result;
  
  // Create RAW hazard: x1 = x2 + x3, then x4 = x1 + x5
  asm volatile (
    "li x2, 10\n"        // x2 = 10
    "li x3, 20\n"        // x3 = 20
    "li x5, 30\n"        // x5 = 30
    "add x1, x2, x3\n"   // x1 = 10 + 20 = 30 (producer)
    "add x4, x1, x5\n"   // x4 = 30 + 30 = 60 (consumer, needs forwarding)
    "mv %0, x4\n"        // store result
    : "=r"(result)
    :
    : "x1", "x2", "x3", "x4", "x5"
  );
  
  print_str("Result: ");
  print_hex(result);
  print_str(" (expected: 0000003C)\n");
  
  if (result == 60) {
    print_str("✅ PASS\n");
  } else {
    print_str("❌ FAIL\n");
  }
}

// Test 2: Load-Use hazard (requires stalling)
void test2_load_use_hazard() {
  print_str("\nTest 2: Load-Use hazard\n");
  
  uint32_t result;
  volatile uint32_t *mem = (volatile uint32_t *)0x2000;
  
  // Store value to memory first
  *mem = 0x12345678;
  
  asm volatile (
    "li x6, 0x2000\n"    // x6 = memory address
    "lw x7, 0(x6)\n"     // x7 = load from memory (takes time)
    "addi x8, x7, 1\n"   // x8 = x7 + 1 (needs stalling)
    "mv %0, x8\n"        // store result
    : "=r"(result)
    :
    : "x6", "x7", "x8"
  );
  
  print_str("Result: ");
  print_hex(result);
  print_str(" (expected: 12345679)\n");
  
  if (result == 0x12345679) {
    print_str("✅ PASS\n");
  } else {
    print_str("❌ FAIL\n");
  }
}

// Test 3: Forwarding from EX/MEM stage
void test3_ex_mem_forwarding() {
  print_str("\nTest 3: EX/MEM forwarding\n");
  
  uint32_t result;
  
  asm volatile (
    "li x9, 100\n"       // x9 = 100
    "li x10, 200\n"      // x10 = 200
    "add x11, x9, x10\n" // x11 = 300 (in EX/MEM)
    "add x12, x11, x9\n" // x12 = 400 (needs forwarding from EX/MEM)
    "mv %0, x12\n"       // store result
    : "=r"(result)
    :
    : "x9", "x10", "x11", "x12"
  );
  
  print_str("Result: ");
  print_hex(result);
  print_str(" (expected: 00000190)\n");
  
  if (result == 400) {
    print_str("✅ PASS\n");
  } else {
    print_str("❌ FAIL\n");
  }
}

// Test 4: Forwarding from MEM/WB stage
void test4_mem_wb_forwarding() {
  print_str("\nTest 4: MEM/WB forwarding\n");
  
  uint32_t result;
  
  asm volatile (
    "li x13, 5\n"        // x13 = 5
    "li x14, 7\n"        // x14 = 7
    "add x15, x13, x14\n" // x15 = 12 (in MEM/WB)
    "nop\n"              // delay
    "add x16, x15, x13\n" // x16 = 17 (needs forwarding from MEM/WB)
    "mv %0, x16\n"       // store result
    : "=r"(result)
    :
    : "x13", "x14", "x15", "x16"
  );
  
  print_str("Result: ");
  print_hex(result);
  print_str(" (expected: 00000011)\n");
  
  if (result == 17) {
    print_str("✅ PASS\n");
  } else {
    print_str("❌ FAIL\n");
  }
}

// Test 5: Complex dependency chain
void test5_complex_chain() {
  print_str("\nTest 5: Complex dependency chain\n");
  
  uint32_t result;
  
  asm volatile (
    "li x17, 1\n"        // x17 = 1
    "addi x18, x17, 1\n" // x18 = 2 (depends on x17)
    "addi x19, x18, 1\n" // x19 = 3 (depends on x18)
    "addi x20, x19, 1\n" // x20 = 4 (depends on x19)
    "addi x21, x20, 1\n" // x21 = 5 (depends on x20)
    "add x22, x21, x17\n" // x22 = 6 (depends on x21 and x17)
    "mv %0, x22\n"       // store result
    : "=r"(result)
    :
    : "x17", "x18", "x19", "x20", "x21", "x22"
  );
  
  print_str("Result: ");
  print_hex(result);
  print_str(" (expected: 00000006)\n");
  
  if (result == 6) {
    print_str("✅ PASS\n");
  } else {
    print_str("❌ FAIL\n");
  }
}

int main() {
  print_str("=== RV32IM Pipeline Forwarding Test ===\n\n");
  
  test1_raw_hazard();
  test2_load_use_hazard();
  test3_ex_mem_forwarding();
  test4_mem_wb_forwarding();
  test5_complex_chain();
  
  print_str("\n=== Test Complete ===\n");
  
  // Halt
  asm volatile ("ebreak");
  return 0;
}