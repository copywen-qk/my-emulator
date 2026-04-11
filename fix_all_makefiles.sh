#!/bin/bash

echo "=== 修復所有 Makefile 問題 ==="
echo ""

# 1. 檢查並修復主 Makefile
echo "1. 檢查主 Makefile..."
if grep -q "dpi_simple.c" Makefile; then
    echo "   ✅ 已排除 dpi_simple.c"
else
    echo "   ⚠️  需要手動檢查"
fi
echo ""

# 2. 檢查所有 Verilator Makefile
echo "2. 檢查 Verilator Makefile 配對..."
echo ""

# 檢查每個 Makefile 的模塊和模擬主程序配對
for makefile in Makefile_verilator*; do
    echo "檢查 $makefile:"
    
    # 提取 Verilog 源碼
    vsrc=$(grep -E "VSRC.*=.*\.v" $makefile | head -1 | sed 's/.*= *//' | tr -d ' ')
    if [ -z "$vsrc" ]; then
        vsrc=$(grep -E "vsrc/.*\.v" $makefile | head -1 | awk '{print $NF}')
    fi
    
    # 提取 C++ 源碼
    csrc=$(grep -E "CSRC.*=.*\.cpp" $makefile | head -1 | sed 's/.*= *//' | tr -d ' ')
    if [ -z "$csrc" ]; then
        csrc=$(grep -E "csrc/.*\.cpp" $makefile | head -1 | awk '{print $NF}')
    fi
    
    # 提取模塊名稱
    module=$(basename "$vsrc" .v 2>/dev/null)
    
    if [ -n "$vsrc" ] && [ -n "$csrc" ] && [ -n "$module" ]; then
        echo "   - Verilog: $vsrc"
        echo "   - C++: $csrc"
        echo "   - 模塊: $module"
        
        # 檢查模擬主程序是否包含正確的模塊名稱
        if grep -q "V${module}" "$csrc" 2>/dev/null; then
            echo "   ✅ 配對正確"
        else
            echo "   ❌ 配對不正確！需要修復"
            echo "      模擬主程序應該包含 V${module}"
        fi
    else
        echo "   ⚠️  無法解析"
    fi
    echo ""
done

# 3. 建議修復方案
echo "3. 建議修復方案："
echo ""
echo "a) 對於使用 sim_main_new.cpp 的 Makefile："
echo "   sim_main_new.cpp 是為 rv32im_y86_pipeline 設計的"
echo "   應該改用對應的模擬主程序："
echo "   - rv32im_pipeline_improved.v → sim_main_improved.cpp"
echo "   - rv32im_pipeline_final.v → sim_main_final.cpp"
echo "   - rv32im_pipeline_y86.v → sim_main_new.cpp (正確)"
echo ""
echo "b) DPI 問題："
echo "   使用 dpi_minimal.c 替代 dpi.c 或 dpi_simple.c"
echo "   避免重複定義和依賴問題"
echo ""
echo "c) 測試建議："
echo "   1. 先測試基本功能：make -f Makefile_verilator"
echo "   2. 測試流水線：使用正確配對的 Makefile"
echo "   3. 運行測試：./obj_dir/Vxxx tests/minimal_test.bin"
echo ""
echo "=== 修復完成 ==="