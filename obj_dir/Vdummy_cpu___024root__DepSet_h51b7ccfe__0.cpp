// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vdummy_cpu.h for the primary calling header

#include "Vdummy_cpu__pch.h"
#include "Vdummy_cpu__Syms.h"
#include "Vdummy_cpu___024root.h"

extern "C" int paddr_read(int addr, int len);

VL_INLINE_OPT void Vdummy_cpu___024root____Vdpiimwrap_dummy_cpu__DOT__paddr_read_TOP(const VerilatedScope* __Vscopep, const char* __Vfilenamep, IData/*31:0*/ __Vlineno, IData/*31:0*/ addr, IData/*31:0*/ len, IData/*31:0*/ &paddr_read__Vfuncrtn) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdummy_cpu___024root____Vdpiimwrap_dummy_cpu__DOT__paddr_read_TOP\n"); );
    // Body
    int addr__Vcvt;
    for (size_t addr__Vidx = 0; addr__Vidx < 1; ++addr__Vidx) addr__Vcvt = addr;
    int len__Vcvt;
    for (size_t len__Vidx = 0; len__Vidx < 1; ++len__Vidx) len__Vcvt = len;
    Verilated::dpiContext(__Vscopep, __Vfilenamep, __Vlineno);
    int paddr_read__Vfuncrtn__Vcvt;
    paddr_read__Vfuncrtn__Vcvt = paddr_read(addr__Vcvt, len__Vcvt);
    paddr_read__Vfuncrtn = paddr_read__Vfuncrtn__Vcvt;
}

extern "C" void difftest_step(int dut_pc);

VL_INLINE_OPT void Vdummy_cpu___024root____Vdpiimwrap_dummy_cpu__DOT__difftest_step_TOP(const VerilatedScope* __Vscopep, const char* __Vfilenamep, IData/*31:0*/ __Vlineno, IData/*31:0*/ dut_pc) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdummy_cpu___024root____Vdpiimwrap_dummy_cpu__DOT__difftest_step_TOP\n"); );
    // Body
    int dut_pc__Vcvt;
    for (size_t dut_pc__Vidx = 0; dut_pc__Vidx < 1; ++dut_pc__Vidx) dut_pc__Vcvt = dut_pc;
    Verilated::dpiContext(__Vscopep, __Vfilenamep, __Vlineno);
    difftest_step(dut_pc__Vcvt);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vdummy_cpu___024root___dump_triggers__act(Vdummy_cpu___024root* vlSelf);
#endif  // VL_DEBUG

void Vdummy_cpu___024root___eval_triggers__act(Vdummy_cpu___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vdummy_cpu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdummy_cpu___024root___eval_triggers__act\n"); );
    // Body
    vlSelf->__VactTriggered.set(0U, ((IData)(vlSelf->clk) 
                                     & (~ (IData)(vlSelf->__Vtrigprevexpr___TOP__clk__0))));
    vlSelf->__Vtrigprevexpr___TOP__clk__0 = vlSelf->clk;
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vdummy_cpu___024root___dump_triggers__act(vlSelf);
    }
#endif
}

VL_INLINE_OPT void Vdummy_cpu___024root___nba_sequent__TOP__0(Vdummy_cpu___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vdummy_cpu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdummy_cpu___024root___nba_sequent__TOP__0\n"); );
    // Body
    VL_WRITEF("[Verilog] PC = 0x%x, Inst = 0x%x\n",
              32,vlSelf->dummy_cpu__DOT__pc,32,vlSelf->dummy_cpu__DOT__inst);
    Vdummy_cpu___024root____Vdpiimwrap_dummy_cpu__DOT__difftest_step_TOP(
                                                                         (&(vlSymsp->__Vscope_dummy_cpu)), 
                                                                         "vsrc/dummy_cpu.v", 0xfU, vlSelf->dummy_cpu__DOT__pc);
    vlSelf->dummy_cpu__DOT__pc = ((IData)(4U) + vlSelf->dummy_cpu__DOT__pc);
    Vdummy_cpu___024root____Vdpiimwrap_dummy_cpu__DOT__paddr_read_TOP(
                                                                      (&(vlSymsp->__Vscope_dummy_cpu)), 
                                                                      "vsrc/dummy_cpu.v", 0xbU, vlSelf->dummy_cpu__DOT__pc, 4U, vlSelf->__Vfunc_dummy_cpu__DOT__paddr_read__0__Vfuncout);
    vlSelf->dummy_cpu__DOT__inst = vlSelf->__Vfunc_dummy_cpu__DOT__paddr_read__0__Vfuncout;
}
