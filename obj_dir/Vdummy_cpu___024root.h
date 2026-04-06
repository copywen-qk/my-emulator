// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vdummy_cpu.h for the primary calling header

#ifndef VERILATED_VDUMMY_CPU___024ROOT_H_
#define VERILATED_VDUMMY_CPU___024ROOT_H_  // guard

#include "verilated.h"


class Vdummy_cpu__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vdummy_cpu___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(clk,0,0);
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __Vtrigprevexpr___TOP__clk__0;
    CData/*0:0*/ __VactContinue;
    IData/*31:0*/ dummy_cpu__DOT__pc;
    IData/*31:0*/ dummy_cpu__DOT__inst;
    IData/*31:0*/ __Vfunc_dummy_cpu__DOT__paddr_read__0__Vfuncout;
    IData/*31:0*/ __VactIterCount;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VactTriggered;
    VlTriggerVec<1> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vdummy_cpu__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vdummy_cpu___024root(Vdummy_cpu__Syms* symsp, const char* v__name);
    ~Vdummy_cpu___024root();
    VL_UNCOPYABLE(Vdummy_cpu___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
