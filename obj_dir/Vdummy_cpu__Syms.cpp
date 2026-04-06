// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "Vdummy_cpu__pch.h"
#include "Vdummy_cpu.h"
#include "Vdummy_cpu___024root.h"

// FUNCTIONS
Vdummy_cpu__Syms::~Vdummy_cpu__Syms()
{
}

Vdummy_cpu__Syms::Vdummy_cpu__Syms(VerilatedContext* contextp, const char* namep, Vdummy_cpu* modelp)
    : VerilatedSyms{contextp}
    // Setup internal state of the Syms class
    , __Vm_modelp{modelp}
    // Setup module instances
    , TOP{this, namep}
{
    // Configure time unit / time precision
    _vm_contextp__->timeunit(-12);
    _vm_contextp__->timeprecision(-12);
    // Setup each module's pointers to their submodules
    // Setup each module's pointer back to symbol table (for public functions)
    TOP.__Vconfigure(true);
    // Setup scopes
    __Vscope_dummy_cpu.configure(this, name(), "dummy_cpu", "dummy_cpu", -12, VerilatedScope::SCOPE_OTHER);
    // Setup export functions
    for (int __Vfinal = 0; __Vfinal < 2; ++__Vfinal) {
    }
}
