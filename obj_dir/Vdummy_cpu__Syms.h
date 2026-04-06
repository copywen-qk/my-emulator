// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VDUMMY_CPU__SYMS_H_
#define VERILATED_VDUMMY_CPU__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vdummy_cpu.h"

// INCLUDE MODULE CLASSES
#include "Vdummy_cpu___024root.h"

// DPI TYPES for DPI Export callbacks (Internal use)

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES)Vdummy_cpu__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vdummy_cpu* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vdummy_cpu___024root           TOP;

    // SCOPE NAMES
    VerilatedScope __Vscope_dummy_cpu;

    // CONSTRUCTORS
    Vdummy_cpu__Syms(VerilatedContext* contextp, const char* namep, Vdummy_cpu* modelp);
    ~Vdummy_cpu__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
};

#endif  // guard
