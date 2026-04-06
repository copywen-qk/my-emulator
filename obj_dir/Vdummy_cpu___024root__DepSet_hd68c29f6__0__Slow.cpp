// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vdummy_cpu.h for the primary calling header

#include "Vdummy_cpu__pch.h"
#include "Vdummy_cpu___024root.h"

VL_ATTR_COLD void Vdummy_cpu___024root___eval_static(Vdummy_cpu___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vdummy_cpu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdummy_cpu___024root___eval_static\n"); );
}

VL_ATTR_COLD void Vdummy_cpu___024root___eval_initial__TOP(Vdummy_cpu___024root* vlSelf);

VL_ATTR_COLD void Vdummy_cpu___024root___eval_initial(Vdummy_cpu___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vdummy_cpu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdummy_cpu___024root___eval_initial\n"); );
    // Body
    Vdummy_cpu___024root___eval_initial__TOP(vlSelf);
    vlSelf->__Vtrigprevexpr___TOP__clk__0 = vlSelf->clk;
}

VL_ATTR_COLD void Vdummy_cpu___024root___eval_initial__TOP(Vdummy_cpu___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vdummy_cpu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdummy_cpu___024root___eval_initial__TOP\n"); );
    // Body
    vlSelf->dummy_cpu__DOT__pc = 0x80000000U;
}

VL_ATTR_COLD void Vdummy_cpu___024root___eval_final(Vdummy_cpu___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vdummy_cpu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdummy_cpu___024root___eval_final\n"); );
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vdummy_cpu___024root___dump_triggers__stl(Vdummy_cpu___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vdummy_cpu___024root___eval_phase__stl(Vdummy_cpu___024root* vlSelf);

VL_ATTR_COLD void Vdummy_cpu___024root___eval_settle(Vdummy_cpu___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vdummy_cpu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdummy_cpu___024root___eval_settle\n"); );
    // Init
    IData/*31:0*/ __VstlIterCount;
    CData/*0:0*/ __VstlContinue;
    // Body
    __VstlIterCount = 0U;
    vlSelf->__VstlFirstIteration = 1U;
    __VstlContinue = 1U;
    while (__VstlContinue) {
        if (VL_UNLIKELY((0x64U < __VstlIterCount))) {
#ifdef VL_DEBUG
            Vdummy_cpu___024root___dump_triggers__stl(vlSelf);
#endif
            VL_FATAL_MT("vsrc/dummy_cpu.v", 1, "", "Settle region did not converge.");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        __VstlContinue = 0U;
        if (Vdummy_cpu___024root___eval_phase__stl(vlSelf)) {
            __VstlContinue = 1U;
        }
        vlSelf->__VstlFirstIteration = 0U;
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vdummy_cpu___024root___dump_triggers__stl(Vdummy_cpu___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vdummy_cpu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdummy_cpu___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VstlTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VstlTriggered.word(0U))) {
        VL_DBG_MSGF("         'stl' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vdummy_cpu___024root___stl_sequent__TOP__0(Vdummy_cpu___024root* vlSelf);

VL_ATTR_COLD void Vdummy_cpu___024root___eval_stl(Vdummy_cpu___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vdummy_cpu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdummy_cpu___024root___eval_stl\n"); );
    // Body
    if ((1ULL & vlSelf->__VstlTriggered.word(0U))) {
        Vdummy_cpu___024root___stl_sequent__TOP__0(vlSelf);
    }
}

VL_ATTR_COLD void Vdummy_cpu___024root___eval_triggers__stl(Vdummy_cpu___024root* vlSelf);

VL_ATTR_COLD bool Vdummy_cpu___024root___eval_phase__stl(Vdummy_cpu___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vdummy_cpu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdummy_cpu___024root___eval_phase__stl\n"); );
    // Init
    CData/*0:0*/ __VstlExecute;
    // Body
    Vdummy_cpu___024root___eval_triggers__stl(vlSelf);
    __VstlExecute = vlSelf->__VstlTriggered.any();
    if (__VstlExecute) {
        Vdummy_cpu___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vdummy_cpu___024root___dump_triggers__act(Vdummy_cpu___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vdummy_cpu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdummy_cpu___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VactTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @(posedge clk)\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vdummy_cpu___024root___dump_triggers__nba(Vdummy_cpu___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vdummy_cpu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdummy_cpu___024root___dump_triggers__nba\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VnbaTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @(posedge clk)\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vdummy_cpu___024root___ctor_var_reset(Vdummy_cpu___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vdummy_cpu__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vdummy_cpu___024root___ctor_var_reset\n"); );
    // Body
    vlSelf->clk = VL_RAND_RESET_I(1);
    vlSelf->dummy_cpu__DOT__pc = VL_RAND_RESET_I(32);
    vlSelf->dummy_cpu__DOT__inst = VL_RAND_RESET_I(32);
    vlSelf->__Vfunc_dummy_cpu__DOT__paddr_read__0__Vfuncout = 0;
    vlSelf->__Vtrigprevexpr___TOP__clk__0 = VL_RAND_RESET_I(1);
}
