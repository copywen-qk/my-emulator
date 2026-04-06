// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vdummy_cpu.h for the primary calling header

#include "Vdummy_cpu__pch.h"
#include "Vdummy_cpu__Syms.h"
#include "Vdummy_cpu___024root.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void Vdummy_cpu___024root___dump_triggers__stl(Vdummy_cpu___024root* vlSelf);
#endif  // VL_DEBUG

VL_ATTR_COLD void Vdummy_cpu___024root___eval_triggers__stl(Vdummy_cpu___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vdummy_cpu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdummy_cpu___024root___eval_triggers__stl\n"); );
    // Body
    vlSelf->__VstlTriggered.set(0U, (IData)(vlSelf->__VstlFirstIteration));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vdummy_cpu___024root___dump_triggers__stl(vlSelf);
    }
#endif
}

void Vdummy_cpu___024root____Vdpiimwrap_dummy_cpu__DOT__paddr_read_TOP(const VerilatedScope* __Vscopep, const char* __Vfilenamep, IData/*31:0*/ __Vlineno, IData/*31:0*/ addr, IData/*31:0*/ len, IData/*31:0*/ &paddr_read__Vfuncrtn);

VL_ATTR_COLD void Vdummy_cpu___024root___stl_sequent__TOP__0(Vdummy_cpu___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vdummy_cpu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdummy_cpu___024root___stl_sequent__TOP__0\n"); );
    // Body
    Vdummy_cpu___024root____Vdpiimwrap_dummy_cpu__DOT__paddr_read_TOP(
                                                                      (&(vlSymsp->__Vscope_dummy_cpu)), 
                                                                      "vsrc/dummy_cpu.v", 0xbU, vlSelf->dummy_cpu__DOT__pc, 4U, vlSelf->__Vfunc_dummy_cpu__DOT__paddr_read__0__Vfuncout);
    vlSelf->dummy_cpu__DOT__inst = vlSelf->__Vfunc_dummy_cpu__DOT__paddr_read__0__Vfuncout;
}
