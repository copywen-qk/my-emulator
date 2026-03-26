# NEMU-RV32: Stream Separation (stdout vs stderr)

## [CSAPP 筆記]
### 文件描述符與標準資料流
根據《CSAPP》第十章，Unix 系統為每個進程預設開啟了三個文件描述符 (File Descriptors)：
1. **stdin (FD 0)**: 標準輸入。
2. **stdout (FD 1)**: 標準輸出。通常用於程式正常的資料輸出（Data Stream）。
3. **stderr (FD 2)**: 標準錯誤。專門用於錯誤訊息、除錯 Log（Log Stream）或診斷資訊。

### 為什麼要區分資料流？
- **純淨的管道 (Pure Pipes)**: 當我們將一個程式的輸出透過 Pipe 傳給另一個程式（如我們的 Python Monitor）時，Pipe 預設只接收 `stdout`。如果我們把除錯 Log 跟真正的 MMIO 資料都往 `stdout` 塞，接收端就無法分辨哪些是「真正的硬體輸出」，哪些是「模擬器的廢話」。
- **即時診斷**: 透過將 Log 導向 `stderr`，即使 `stdout` 被重新導向到檔案或 Pipe，使用者仍然可以在終端機畫面上即時看到 `stderr` 顯示的執行狀態或錯誤警告。這在系統程式設計與 IPC 通訊中是一項標準實踐。
