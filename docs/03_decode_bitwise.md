# NEMU-RV32: Decode & Bitwise Operations

## [韌體筆記]
### C 語言中的 Bitwise 操作
在底層開發（如驅動程式、模擬器或嵌入式系統）中，Bitwise 操作（Masking & Shifting）至關重要，原因如下：
1. **硬體寄存器映射：** 硬體寄存器通常將多個功能控制位（Fields）壓縮在一個 32-bit 或 16-bit 的空間中。我們需要透過 `&` (AND)、`|` (OR) 與 `>>` (Right Shift) 來提取或設定特定的位元。
2. **效能：** 位元運算直接對應到處理器的邏輯指令，執行速度極快。
3. **通訊協定：** 許多工業通訊協定（如 CAN, SPI）的封包格式也是以位元為單位定義的。

## [CSAPP 筆記]
根據《CSAPP》第二章關於 Right Shift 的說明：
- **邏輯位移 (Logical Shift)：** 在左端補 0。適用於 `unsigned` 類型。
- **算術位移 (Arithmetic Shift)：** 在左端補最高有效位元（符號位）。適用於 `signed` 類型，能保持數值的正負號。
- **在 Decode 中的意義：** 當我們提取立即數（Immediate）時，通常需要進行「符號擴展 (Sign Extension)」，這時必須確保使用 `int32_t` 進行算術右移，以正確保留負數符號。而在提取 Opcode 等欄位時，我們使用 `1U` 或 `uint32_t` 來確保執行的是邏輯位移。
