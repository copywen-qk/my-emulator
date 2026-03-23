# NEMU-RV32: Infrastructure & Development Log

## [韌體筆記 - Reset Vector]
**Reset Vector** 是處理器上電（Power-On）或重置（Reset）後，程式計數器（Program Counter, PC）所指向的第一個記憶體位址。

- **為什麼需要固定位址？** 硬體邏輯在通電後需要一個確定的起點來開始取指（Instruction Fetch）。如果沒有固定的起點，CPU 將無法知道該從哪裡執行。
- **RISC-V 範例：** 在許多 RISC-V 實作（如 QEMU 或真實開發板）中，Reset Vector 通常設為 `0x80000000`。
- **對 Bootloader 的意義：** Bootloader 會被放置在 Reset Vector 所在的記憶體區域（通常是 ROM 或 Flash），負責初始化系統硬體（如 DRAM、中斷控制器）並加載操作系統內核。

## [CSAPP 筆記 - Instruction Cycle]
根據《Computer Systems: A Programmer's Perspective (CSAPP)》第四章，CPU 執行一條指令通常遵循以下循環邏輯：

1. **取指 (Fetch)：** 從 PC 指向的記憶體位址讀取指令內容。
2. **解碼 (Decode)：** 解析指令的操作碼（Opcode）和暫存器操作數。
3. **執行 (Execute)：** 由 ALU 進行算術或邏輯運算。
4. **訪存 (Memory)：** 如果是 Load/Store 指令，則存取資料記憶體。
5. **寫回 (Write Back)：** 將運算結果寫回到暫存器。
6. **更新 PC (PC Update)：** 計算下一條指令的位址（如 `PC + 4` 或跳躍目標）。

目前的 NEMU 模擬器僅實作了最基礎的 **PC Update** 邏輯。
