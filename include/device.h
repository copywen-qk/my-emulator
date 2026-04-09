#ifndef __DEVICE_H__
#define __DEVICE_H__

#include <stdint.h>

#define RTC_ADDR 0xa0000048
#define KBD_ADDR 0xa0000060
#define VGACTL_ADDR 0xa0000100
#define FB_ADDR 0xa1000000

void init_device();
void device_update();
uint32_t rtc_read(int offset);
uint32_t kbd_read();
uint32_t vgactl_read(int offset);
void vgactl_write(int offset, uint32_t data);
void fb_write(uint32_t addr, int len, uint32_t data);

#endif
