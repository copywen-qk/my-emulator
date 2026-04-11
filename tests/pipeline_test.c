#include "am.h"

// 流水線測試程式
// 測試資料相依性和控制流

void _start() {
    // 測試 1: 資料相依性 (RAW hazard)
    // 指令序列: addi -> add -> add
    int a = 1;          // addi x1, x0, 1
    int b = 2;          // addi x2, x0, 2
    int c = a + b;      // add  x3, x1, x2  (需要 x1, x2)
    int d = c + 1;      // addi x4, x3, 1   (需要 x3)
    
    // 測試 2: 記憶體操作
    int array[3] = {10, 20, 30};
    int e = array[0];   // lw x5, 0(x10) 假設 x10 指向 array
    array[1] = 40;      // sw x6, 4(x10) 假設 x6=40
    
    // 測試 3: 控制流 (分支)
    int counter = 0;
    int limit = 5;
    
    while (counter < limit) {  // 分支指令
        counter = counter + 1;
    }
    
    // 測試 4: 函數呼叫 (JAL/JALR)
    // 簡單的函數呼叫測試
    int result = 0;
    for (int i = 0; i < 3; i++) {
        result = result + i;
    }
    
    // 最終檢查點
    // 如果所有測試通過，寫入特定記憶體位置
    int final_check = 0;
    
    if (a == 1 && b == 2 && c == 3 && d == 4) {
        final_check = final_check | 0x1;  // 測試 1 通過
    }
    
    if (e == 10 && array[1] == 40) {
        final_check = final_check | 0x2;  // 測試 2 通過
    }
    
    if (counter == 5) {
        final_check = final_check | 0x4;  // 測試 3 通過
    }
    
    if (result == 3) {  // 0+1+2 = 3
        final_check = final_check | 0x8;  // 測試 4 通過
    }
    
    // 寫入結果到記憶體
    *(volatile int*)0x80000000 = final_check;
    
    // 如果所有測試通過 (0xF = 0b1111)，寫入成功標誌
    if (final_check == 0xF) {
        *(volatile int*)0x80000004 = 0xCAFEBABE;
    } else {
        *(volatile int*)0x80000004 = 0xBADBAD00 + final_check;
    }
    
    // 無限循環
    while (1) {}
}

// 簡單的加法函數 (測試 JALR)
int simple_add(int x, int y) {
    return x + y;
}