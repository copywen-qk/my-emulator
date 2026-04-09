#include <verilated.h>
#include "Vdummy_cpu.h"
#include <iostream>

extern "C" {
    long load_image(const char *img_file);
    void init_device();
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <image.bin>" << std::endl;
        return 1;
    }

    init_device();
    load_image(argv[1]);

    Vdummy_cpu* top = new Vdummy_cpu;

    for (int i = 0; i < 10; ++i) {
        top->clk = 0;
        top->eval();
        top->clk = 1;
        top->eval();
    }

    delete top;
    return 0;
}
