// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vdummy_cpu__pch.h"

//============================================================
// Constructors

Vdummy_cpu::Vdummy_cpu(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vdummy_cpu__Syms(contextp(), _vcname__, this)}
    , clk{vlSymsp->TOP.clk}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vdummy_cpu::Vdummy_cpu(const char* _vcname__)
    : Vdummy_cpu(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vdummy_cpu::~Vdummy_cpu() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vdummy_cpu___024root___eval_debug_assertions(Vdummy_cpu___024root* vlSelf);
#endif  // VL_DEBUG
void Vdummy_cpu___024root___eval_static(Vdummy_cpu___024root* vlSelf);
void Vdummy_cpu___024root___eval_initial(Vdummy_cpu___024root* vlSelf);
void Vdummy_cpu___024root___eval_settle(Vdummy_cpu___024root* vlSelf);
void Vdummy_cpu___024root___eval(Vdummy_cpu___024root* vlSelf);

void Vdummy_cpu::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vdummy_cpu::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vdummy_cpu___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vdummy_cpu___024root___eval_static(&(vlSymsp->TOP));
        Vdummy_cpu___024root___eval_initial(&(vlSymsp->TOP));
        Vdummy_cpu___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vdummy_cpu___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vdummy_cpu::eventsPending() { return false; }

uint64_t Vdummy_cpu::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "%Error: No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vdummy_cpu::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vdummy_cpu___024root___eval_final(Vdummy_cpu___024root* vlSelf);

VL_ATTR_COLD void Vdummy_cpu::final() {
    Vdummy_cpu___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vdummy_cpu::hierName() const { return vlSymsp->name(); }
const char* Vdummy_cpu::modelName() const { return "Vdummy_cpu"; }
unsigned Vdummy_cpu::threads() const { return 1; }
void Vdummy_cpu::prepareClone() const { contextp()->prepareClone(); }
void Vdummy_cpu::atClone() const {
    contextp()->threadPoolpOnClone();
}

//============================================================
// Trace configuration

VL_ATTR_COLD void Vdummy_cpu::trace(VerilatedVcdC* tfp, int levels, int options) {
    vl_fatal(__FILE__, __LINE__, __FILE__,"'Vdummy_cpu::trace()' called on model that was Verilated without --trace option");
}
