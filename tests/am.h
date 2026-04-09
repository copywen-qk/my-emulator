#ifndef __AM_H__
#define __AM_H__

#include <stdint.h>

#define RTC_ADDR     0xa0000048
#define KBD_ADDR     0xa0000060
#define VGACTL_ADDR  0xa0000100
#define FB_ADDR      0xa1000000

static inline uint32_t io_read(uint32_t addr) {
  return *(volatile uint32_t *)addr;
}

static inline void io_write(uint32_t addr, uint32_t val) {
  *(volatile uint32_t *)addr = val;
}

static inline uint64_t uptime() {
  uint32_t lo = io_read(RTC_ADDR);
  uint32_t hi = io_read(RTC_ADDR + 4);
  return ((uint64_t)hi << 32) | lo;
}

#endif
