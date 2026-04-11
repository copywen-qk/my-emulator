// Simple pipeline flow test
// Tests basic instruction flow through pipeline

#include <stdint.h>

// Simple putchar for debugging
void putchar(char c) {
  volatile char *tx = (volatile char *)0x10000000;
  *tx = c;
}

void print_str(const char *str) {
  while (*str) {
    putchar(*str++);
  }
}

void print_hex(uint32_t val) {
  for (int i = 7; i >= 0; i--) {
    uint8_t nibble = (val >> (i * 4)) & 0xF;
    putchar(nibble < 10 ? '0' + nibble : 'A' + nibble - 10);
  }
}

int main() {
  print_str("=== Pipeline Flow Test ===\n");
  
  // Test 1: Simple arithmetic
  print_str("Test 1: LUI + ADDI\n");
  
  uint32_t result1, result2;
  
  asm volatile (
    "lui x1, 0x10000\n"      // x1 = 0x10000000
    "addi x2, x1, 0x123\n"   // x2 = 0x10000123
    "mv %0, x1\n"
    "mv %1, x2\n"
    : "=r"(result1), "=r"(result2)
    :
    : "x1", "x2"
  );
  
  print_str("x1 = ");
  print_hex(result1);
  print_str(" (expected: 10000000)\n");
  
  print_str("x2 = ");
  print_hex(result2);
  print_str(" (expected: 10000123)\n");
  
  // Test 2: Register-to-register operation
  print_str("\nTest 2: ADD\n");
  
  uint32_t result3;
  
  asm volatile (
    "li x3, 100\n"
    "li x4, 200\n"
    "add x5, x3, x4\n"  // x5 = 300
    "mv %0, x5\n"
    : "=r"(result3)
    :
    : "x3", "x4", "x5"
  );
  
  print_str("x5 = ");
  print_hex(result3);
  print_str(" (expected: 0000012C)\n");
  
  // Test 3: Memory access
  print_str("\nTest 3: Store/Load\n");
  
  volatile uint32_t *mem = (volatile uint32_t *)0x2000;
  uint32_t result4;
  
  // Store value
  *mem = 0xDEADBEEF;
  
  asm volatile (
    "li x6, 0x2000\n"
    "lw x7, 0(x6)\n"     // Load from memory
    "mv %0, x7\n"
    : "=r"(result4)
    :
    : "x6", "x7"
  );
  
  print_str("Loaded: ");
  print_hex(result4);
  print_str(" (expected: DEADBEEF)\n");
  
  // Test 4: Pipeline fill (NOPs to fill pipeline)
  print_str("\nTest 4: Pipeline fill with NOPs\n");
  
  asm volatile (
    "nop\n"
    "nop\n"
    "nop\n"
    "nop\n"
    "nop\n"
    "li x8, 0x55555555\n"
    "mv %0, x8\n"
    : "=r"(result4)
    :
    : "x8"
  );
  
  print_str("x8 = ");
  print_hex(result4);
  print_str(" (expected: 55555555)\n");
  
  print_str("\n=== Test Complete ===\n");
  
  // Halt
  asm volatile ("ebreak");
  return 0;
}