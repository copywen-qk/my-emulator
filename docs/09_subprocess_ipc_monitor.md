# NEMU-RV32: Subprocess IPC Monitor

## [韌體筆記]
### fflush(stdout) 與 UART TX FIFO
- **緩衝區刷新：** 在 C 語言中使用 `putchar` 輸出字元到 `stdout` 時，作業系統或標準函式庫通常會進行緩衝（Buffering）。如果不呼叫 `fflush(stdout)`，輸出可能會停留在記憶體緩衝區中，而不會立即傳送到 Pipe 或終端機。
- **UART 類比：** 這與硬體 UART 驅動程式中「等待 TX FIFO 緩衝區清空」的動作非常相似。在嵌入式開發中，如果你不檢查 TX Status Register 就寫入下一字元，資料可能會遺失或覆蓋；同樣地，如果不 Flush，外部觀測者（如除錯器或我們的 Python Monitor）就無法即時看到輸出。

## [CSAPP 筆記]
### 行程 (Process) 與 I/O 緩衝機制
- **行程 (Process)：** 根據《CSAPP》第八章，每個運行中的程式都是一個行程，擁有獨立的位址空間。透過 `subprocess.Popen`，Python 行程創建了一個子行程（C 模擬器）。
- **I/O 緩衝機制：** 根據第十章，`stdout` 在連接到終端機時通常是 **行緩衝 (Line Buffered)**，但當它被重導向到 Pipe（如 `subprocess.PIPE`）時，通常會變成 **全緩衝 (Fully Buffered)**。
- **IPC 通訊影響：** 如果 C 程式不手動 `fflush`，在全緩衝模式下，輸出只有在緩衝區滿（通常為 4KB）或程式結束時才會發送。這對於需要即時互動的模擬器來說是不可接受的。因此，`fflush` 是確保跨行程通訊 (IPC) 流暢的關鍵。
