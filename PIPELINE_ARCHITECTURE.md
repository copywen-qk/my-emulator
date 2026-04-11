# RV32IM 流水線 CPU 架構設計

## 🏗️ **架構概述**

本文件描述了一個五級流水線的 RISC-V RV32IM CPU 實現，採用類似 Y86-64 的暫存器命名風格。

## 📊 **流水線階段**

### **階段 1: 指令提取 (Instruction Fetch - IF)**
```
輸入: PC (程式計數器)
輸出: if_id_pc, if_id_inst, if_id_valid
功能:
  - 從記憶體讀取指令 (paddr_read(pc, 4))
  - 計算下一個 PC (pc + 4)
  - 處理分支/跳轉目標
```

### **階段 2: 指令解碼 (Instruction Decode - ID)**
```
輸入: if_id_pc, if_id_inst
輸出: id_ex_*, id_ex_valA, id_ex_valB, id_ex_valC
功能:
  - 解碼指令欄位 (opcode, rd, rs1, rs2, funct3, funct7)
  - 讀取暫存器檔案 (rf[rs1], rf[rs2])
  - 生成立即數 (imm_i, imm_s, imm_b, imm_u, imm_j)
  - 映射到 Y86-64 風格的 icode
```

### **階段 3: 執行 (Execute - EX)**
```
輸入: id_ex_*, id_ex_valA, id_ex_valB, id_ex_valC
輸出: ex_mem_*, ex_mem_aluout, ex_mem_cnd
功能:
  - ALU 運算 (算術、邏輯、移位、比較)
  - 分支條件判斷
  - 計算分支目標地址
  - 計算下一個 PC (valP)
```

### **階段 4: 記憶體存取 (Memory Access - MEM)**
```
輸入: ex_mem_*, ex_mem_aluout, ex_mem_valB
輸出: mem_wb_*, mem_wb_valM
功能:
  - 記憶體讀取 (Load 指令)
  - 記憶體寫入 (Store 指令)
  - 記憶體資料處理 (位元組/半字/字擴展)
```

### **階段 5: 寫回 (Write Back - WB)**
```
輸入: mem_wb_*, mem_wb_valM, mem_wb_aluout
輸出: rf[rd] (暫存器檔案更新)
功能:
  - 選擇寫回資料 (記憶體 or ALU 結果)
  - 更新暫存器檔案
```

## 🔤 **Y86-64 風格暫存器命名**

### **核心暫存器：**
- **icode**: 指令代碼 (對應 RISC-V opcode)
- **valA**: 來源暫存器 A 的值 (對應 rs1_val)
- **valB**: 來源暫存器 B 的值 (對應 rs2_val)
- **valC**: 常數值 (對應立即數)
- **valP**: 下一個 PC 值 (pc + 4)
- **valM**: 記憶體讀取值
- **cnd**: 條件碼 (分支條件結果)

### **流水線暫存器命名規則：**
```
{stage1}_{stage2}_{register}
例如: if_id_pc, id_ex_valA, ex_mem_aluout, mem_wb_valM
```

## 🎯 **指令處理流程**

### **1. 算術指令 (ADD/SUB/ADDI)**
```
IF: 讀取指令
ID: 解碼 opcode=0x13/0x33, 讀取 rs1/rs2, 生成 imm
EX: ALU 計算 rs1 + rs2 或 rs1 + imm
MEM: 無記憶體操作
WB: 寫回結果到 rd
```

### **2. 記憶體指令 (LW/SW)**
```
IF: 讀取指令
ID: 解碼 opcode=0x03/0x23, 讀取 rs1, 生成 imm
EX: 計算記憶體地址 (rs1 + imm)
MEM: 讀取/寫入記憶體
WB: (LW) 寫回記憶體資料到 rd
```

### **3. 分支指令 (BEQ/BNE)**
```
IF: 讀取指令
ID: 解碼 opcode=0x63, 讀取 rs1/rs2, 生成 imm
EX: 比較 rs1 和 rs2, 計算分支目標 (pc + imm)
MEM: 無記憶體操作
WB: 無暫存器寫回
```

### **4. 跳轉指令 (JAL/JALR)**
```
IF: 讀取指令
ID: 解碼 opcode=0x6f/0x67, 讀取 rs1, 生成 imm
EX: 計算跳轉目標, 計算返回地址 (pc + 4)
MEM: 無記憶體操作
WB: 寫回返回地址到 rd
```

## ⚠️ **流水線危險處理 (目前版本)**

### **當前實現的簡單處理：**
1. **無資料轉發**: 依賴編譯器調度或插入 NOP
2. **簡單分支預測**: 總是預測不跳轉
3. **分支誤預測**: 沖洗 IF/ID 暫存器

### **需要改進的部分：**
1. **資料轉發 (Forwarding)**: 處理 RAW 危險
2. **停頓 (Stalling)**: 處理 Load-Use 危險
3. **分支預測器**: 提高分支預測準確率

## 🔧 **控制信號**

### **每個階段的控制信號：**
- **IF**: stall_if, flush_if
- **ID**: stall_id, flush_id
- **EX**: stall_ex
- **MEM**: stall_mem
- **WB**: stall_wb

### **信號生成邏輯：**
```verilog
// 簡單的停頓邏輯 (目前為無停頓)
assign stall_if = 1'b0;
assign stall_id = 1'b0;
assign stall_ex = 1'b0;
assign stall_mem = 1'b0;
assign stall_wb = 1'b0;

// 分支沖洗邏輯
assign flush_if = branch_taken;
assign flush_id = branch_taken;
```

## 📈 **性能分析**

### **理論性能：**
- **單週期 CPU**: 1 指令/時鐘週期
- **五級流水線 CPU**: 接近 5 指令/時鐘週期 (理想情況)

### **實際性能影響因素：**
1. **資料危險**: 需要停頓或轉發
2. **控制危險**: 分支誤預測導致沖洗
3. **結構危險**: 資源衝突

### **性能預期：**
- 無危險指令序列: ~5x 加速
- 典型程式碼: ~3-4x 加速
- 分支密集程式碼: ~2-3x 加速

## 🧪 **測試策略**

### **測試類型：**
1. **功能測試**: 驗證指令正確性
2. **流水線測試**: 驗證多指令並行執行
3. **危險測試**: 驗證資料相依性處理
4. **性能測試**: 測量實際加速比

### **測試程式：**
- `minimal_test.bin`: 基本功能測試
- `pipeline_test.bin`: 流水線特定測試
- `hazard_test.bin`: 危險處理測試

## 🚀 **下一步開發**

### **短期目標：**
1. 實現資料轉發邏輯
2. 添加 Load-Use 危險檢測
3. 改進分支預測器

### **中期目標：**
1. 實現 M 擴展 (乘除法)
2. 添加 CSR 暫存器支援
3. 實現中斷和例外處理

### **長期目標：**
1. 超純量執行
2. 亂序執行
3. 快取記憶體系統

## 📝 **設計決策**

### **1. Y86-64 風格命名**
- **優點**: 與經典教材一致，易於理解
- **缺點**: 與 RISC-V 原生命名不同，需要映射

### **2. 簡單危險處理**
- **優點**: 實現簡單，易於除錯
- **缺點**: 性能受限，需要編譯器協助

### **3. 集中式控制信號**
- **優點**: 控制邏輯集中，易於管理
- **缺點**: 可能成為時序瓶頸

## 🔍 **除錯與驗證**

### **除錯輸出：**
每個時鐘週期顯示所有流水線階段的狀態：
```
[PIPELINE] IF: PC=0x80000000, Inst=0x00000093
[PIPELINE] ID: PC=0x80000000, Icode=0x08, rd=x1
[PIPELINE] EX: PC=0x80000000, ALU=0x0000000a, rd=x1
[PIPELINE] MEM: PC=0x80000000, Addr=0x00000000, rd=x1
[PIPELINE] WB: PC=0x80000000, Data=0x0000000a, rd=x1
```

### **驗證方法：**
1. **Diff-Test**: 與 C NEMU 比對執行結果
2. **波形檢視**: 使用 Verilator 或 ModelSim
3. **單步執行**: 驗證每個流水線階段的狀態

---

**版本**: 1.0  
**日期**: 2026-04-11  
**狀態**: 基礎架構完成，待實現危險處理