#include "am.h"

void _start() {
  uint32_t conf = io_read(VGACTL_ADDR);
  int width = conf >> 16;
  int height = conf & 0xffff;

  int bird_y = height / 2;
  int bird_vy = 0;
  int pipe_x = width;
  int pipe_w = 40;
  int pipe_gap = 80;
  int pipe_y = height / 2 - 40;

  uint64_t next_frame = uptime();

  while (1) {
    // FPS Control (~60 FPS)
    while (uptime() < next_frame);
    next_frame += 16666;

    // Input Handling
    if (io_read(KBD_ADDR) != 0) {
      bird_vy = -4;
    }

    // Physics Update
    bird_vy += 1;
    bird_y += bird_vy;
    pipe_x -= 3;

    if (pipe_x < -pipe_w) {
      pipe_x = width;
    }

    if (bird_y < 0) bird_y = 0;
    if (bird_y > height - 10) bird_y = height - 10;

    // Draw Screen
    uint32_t *fb = (uint32_t *)FB_ADDR;
    for (int i = 0; i < width * height; i++) {
      int x = i % width;
      int y = i / width;

      // Draw Bird (Yellow)
      if (x >= 50 && x < 65 && y >= bird_y && y < bird_y + 15) {
        fb[i] = 0xFFFF00;
      }
      // Draw Pipe (Green)
      else if (x >= pipe_x && x < pipe_x + pipe_w && (y < pipe_y || y > pipe_y + pipe_gap)) {
        fb[i] = 0x00FF00;
      }
      // Background (Sky Blue)
      else {
        fb[i] = 0x87CEEB;
      }
    }
  }
}
