# NEMU-RV32: R-Type & Expanded I-Type Instructions

## [韌體筆記]
### 位元運算與硬體暫存器遮罩 (Masking)
在韌體開發中，AND/OR/XOR 常被用於操控硬體暫存器（Memory-Mapped I/O）：
- **OR (`|`)**: 用於「設定」位元（Setting bits）。例如 `REG |= (1 << 5)` 會將第 5 位元設為 1，而不影響其他位元。
- **AND (`&`)**: 用於「清除」或「提取」位元（Clearing/Masking bits）。例如 `REG &= ~(1 << 5)` 會將第 5 位元清零；`if (REG & 0xF)` 則提取低 4 位元。
- **XOR (`^`)**: 用於「翻轉」位元（Toggling bits）。

## [CSAPP 筆記]
### 算術右移 vs 邏輯右移
- **邏輯右移 (Logical Right Shift)**: 適用於 `unsigned` 數值。補入的位元固定為 0。對應 RISC-V 的 `SRL` / `SRLI`。
- **算術右移 (Arithmetic Right Shift)**: 適用於 `signed` 數值（2 的補數表示）。補入的位元等於原始數值的最高有效位元（符號位）。這保證了有號數除以 2 的冪次後符號不變。對應 RISC-V 的 `SRA` / `SRAI`。
- **C 語言實作**: 在 C 語言中，對 `int32_t` (signed) 執行 `>>` 通常是算術右移；對 `uint32_t` (unsigned) 執行 `>>` 則是邏輯右移。在模擬器中，我們透過強制轉型來確保模擬行為符合 RISC-V 規範。
