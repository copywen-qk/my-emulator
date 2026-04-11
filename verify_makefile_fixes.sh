#!/bin/bash

echo "=== 驗證 Makefile 修復 ==="
echo ""

# 檢查每個 Makefile 的 DPI 使用
echo "1. 檢查 DPI 使用情況："
echo ""

for makefile in Makefile_verilator*; do
    echo "檢查 $makefile:"
    
    # 檢查是否使用 dpi.c 或 dpi_simple.c
    if grep -q "src/dpi\.c\|src/dpi_simple\.c" "$makefile"; then
        echo "   ❌ 仍然使用有問題的 DPI"
    elif grep -q "csrc/dpi_minimal\.c" "$makefile"; then
        echo "   ✅ 使用 dpi_minimal.c"
    else
        echo "   ⚠️  未使用 DPI 或使用其他 DPI"
    fi
    
    # 檢查模擬主程序
    vsrc=$(grep -E "VSRC.*=.*\.v|vsrc/.*\.v" "$makefile" | head -1 | sed 's/.*= *//' | tr -d ' ' | sed 's/.*vsrc\///')
    csrc=$(grep -E "CSRC.*=.*\.cpp|csrc/.*\.cpp" "$makefile" | head -1 | sed 's/.*= *//' | tr -d ' ' | sed 's/.*csrc\///')
    
    if [ -n "$vsrc" ] && [ -n "$csrc" ]; then
        module=$(basename "$vsrc" .v 2>/dev/null)
        echo "   - Verilog: $vsrc"
        echo "   - C++: $csrc"
        echo "   - 模塊: $module"
    fi
    echo ""
done

# 測試關鍵 Makefile 的編譯
echo "2. 測試關鍵 Makefile 編譯："
echo ""

# 測試主 Makefile
echo "測試主 Makefile..."
make clean > /dev/null 2>&1
if make 2>&1 | grep -q "error"; then
    echo "   ❌ 編譯失敗"
else
    echo "   ✅ 編譯成功"
fi
echo ""

# 測試基本 Verilator
echo "測試 Makefile_verilator..."
make -f Makefile_verilator clean > /dev/null 2>&1
if make -f Makefile_verilator 2>&1 | grep -q "error"; then
    echo "   ❌ 編譯失敗"
else
    echo "   ✅ 編譯成功"
fi
echo ""

# 測試改進版本
echo "測試 Makefile_verilator_improved..."
make -f Makefile_verilator_improved clean > /dev/null 2>&1
if make -f Makefile_verilator_improved 2>&1 | tail -5 | grep -q "error\|Error"; then
    echo "   ❌ 編譯失敗"
else
    echo "   ✅ 編譯成功"
fi
echo ""

# 測試新的 RV32IM CPU
echo "測試 Makefile_verilator_new..."
make -f Makefile_verilator_new clean > /dev/null 2>&1
if make -f Makefile_verilator_new 2>&1 | tail -5 | grep -q "error\|Error"; then
    echo "   ❌ 編譯失敗"
else
    echo "   ✅ 編譯成功"
fi
echo ""

echo "=== 驗證完成 ==="