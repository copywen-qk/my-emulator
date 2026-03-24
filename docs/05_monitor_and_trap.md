# NEMU-RV32: Monitor & Trap

## [韌體筆記]
### EBREAK 與軟體中斷 (Software Breakpoint)
- **EBREAK 指令：** 在 RISC-V 中，`ebreak` 指令用於將控制權轉交給除錯環境（Debug Environment）。
- **除錯器互動：** 當 GDB 或模擬器遇到 `ebreak` 時，會觸發一個 Breakpoint Exception。在實體硬體上，這通常會跳轉到特定的 Trap Handler；在我們的模擬器中，我們透過改變 `cpu.state` 來停止執行循環，讓使用者可以在 Monitor 中檢查暫存器狀態。

## [CSAPP 筆記]
### CPU 架構狀態 (Architectural State)
- **定義：** 指的是為了確保程式正確執行，硬體必須維護的所有狀態集合。在 RISC-V 中，這包括 32 個通用暫存器（GPRs）以及程式計數器（PC）。
- **除錯意義：** 當我們在除錯時（例如使用 `info r`），我們實際上是在觀察該指令週期結束後的「架構狀態」。只有理解了架構狀態的變化，才能驗證指令實作（如 `ADDI`）是否正確符合規範。
