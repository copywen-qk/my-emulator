#ifndef __DEVICE_H__
#define __DEVICE_H__

#include <stdint.h>

#define RTC_ADDR 0xa0000048

void init_device();
uint32_t rtc_read(int offset);

#endif
