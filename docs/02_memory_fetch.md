# NEMU-RV32: Memory & Instruction Fetch

## [韌體筆記]
### Little-Endian 字節順序
在 Little-Endian（小端序）系統中，**最低有效位元組 (LSB)** 會被儲存在**最低的記憶體位址**。
- **拼字節邏輯：** 例如，一個 32-bit 的數值 `0x12345678` 儲存在位址 `A` 開始的地方，則：
  - `A`: `0x78`
  - `A+1`: `0x56`
  - `A+2`: `0x34`
  - `A+3`: `0x12`
- **對齊 (Alignment)：** RISC-V 的標準指令長度為 32-bit (4 bytes)。雖然 RISC-V 支援非對齊存取（視具體擴展而定），但為了性能與硬體實作的簡潔，取指時的 PC 通常要求 **4-byte 對齊**（即 PC 的最後兩位 bit 為 0）。若 PC 指向 `0x80000002` 進行 32-bit 取指，在某些硬體上會觸發 Alignment Exception。

## [CSAPP 筆記]
根據《CSAPP》第二章 (2.1.3 Data Size, 2.1.4 Addressing and Byte Ordering)：
- **Byte Ordering** 是電腦架構中的重要概念。不同的架構（如 x86 是 Little-Endian，某些 PowerPC 是 Big-Endian）會影響資料在記憶體中的佈局。
- 程式員在進行位元運算（Bitwise operations）或跨平台通訊時，必須特別注意 Byte Ordering 的差異。
- 我們的 `paddr_read` 實作中，明確使用了位移運算來保證無論主機架構為何，都能正確模擬 RISC-V 的 Little-Endian 讀取。
