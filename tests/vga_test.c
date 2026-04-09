#include <stdint.h>

#define VGACTL_ADDR 0xa0000100
#define FB_ADDR 0xa1000000

void draw_pixel(int x, int y, int width, uint32_t color) {
    ((uint32_t *)FB_ADDR)[y * width + x] = color;
}

void _start() {
    volatile uint32_t *vgactl = (uint32_t *)VGACTL_ADDR;
    uint32_t val = *vgactl;
    int width = val >> 16;
    int height = val & 0xffff;

    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            draw_pixel(x, y, width, 0x00FF00); // Green (ARGB: 0x0000FF00)
        }
    }

    // Indicate finished with a specific pattern or just loop
    while (1);
}
