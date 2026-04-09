#include <sys/time.h>
#include <stdint.h>
#include <stddef.h>
#include "device.h"

static uint64_t boot_time = 0;

static uint64_t get_time_internal() {
    struct timeval now;
    gettimeofday(&now, NULL);
    return (uint64_t)now.tv_sec * 1000000 + now.tv_usec;
}

void init_device() {
    boot_time = get_time_internal();
}

uint32_t rtc_read(int offset) {
    uint64_t us = get_time_internal() - boot_time;
    if (offset == 0) return (uint32_t)(us & 0xFFFFFFFF);
    if (offset == 4) return (uint32_t)(us >> 32);
    return 0;
}
