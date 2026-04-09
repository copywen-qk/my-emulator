#include <sys/time.h>
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <SDL2/SDL.h>
#include "device.h"

#define SCREEN_W 400
#define SCREEN_H 300

static uint64_t boot_time = 0;
static SDL_Window *window = NULL;
static SDL_Renderer *renderer = NULL;
static SDL_Texture *texture = NULL;
static uint32_t fb[SCREEN_W * SCREEN_H];
static int key_pressed = 0;

static uint64_t get_time_internal() {
    struct timeval now;
    gettimeofday(&now, NULL);
    return (uint64_t)now.tv_sec * 1000000 + now.tv_usec;
}

void init_device() {
    boot_time = get_time_internal();

    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS) != 0) {
        fprintf(stderr, "SDL_Init Error: %s\n", SDL_GetError());
        return;
    }

    window = SDL_CreateWindow("NEMU-RV32 VGA", 
                              SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 
                              SCREEN_W, SCREEN_H, SDL_WINDOW_SHOWN);
    if (window == NULL) {
        fprintf(stderr, "SDL_CreateWindow Error: %s\n", SDL_GetError());
        return;
    }

    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888, 
                                SDL_TEXTUREACCESS_STREAMING, SCREEN_W, SCREEN_H);
}

void device_update() {
    static uint64_t last_update = 0;
    uint64_t now = get_time_internal();
    if (now - last_update < 16666) return; // ~60 FPS
    last_update = now;

    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        if (event.type == SDL_QUIT) {
            exit(0);
        } else if (event.type == SDL_KEYDOWN) {
            if (event.key.keysym.sym == SDLK_SPACE) key_pressed = 1;
        } else if (event.type == SDL_KEYUP) {
            if (event.key.keysym.sym == SDLK_SPACE) key_pressed = 0;
        }
    }

    SDL_UpdateTexture(texture, NULL, fb, SCREEN_W * sizeof(uint32_t));
    SDL_RenderClear(renderer);
    SDL_RenderCopy(renderer, texture, NULL, NULL);
    SDL_RenderPresent(renderer);
}

uint32_t rtc_read(int offset) {
    uint64_t us = get_time_internal() - boot_time;
    if (offset == 0) return (uint32_t)(us & 0xFFFFFFFF);
    if (offset == 4) return (uint32_t)(us >> 32);
    return 0;
}

uint32_t kbd_read() {
    return key_pressed;
}

uint32_t vgactl_read(int offset) {
    if (offset == 0) return (SCREEN_W << 16) | SCREEN_H;
    return 0;
}

void vgactl_write(int offset, uint32_t data) {
    // Stub
}

void fb_write(uint32_t addr, int len, uint32_t data) {
    uint32_t offset = (addr - FB_ADDR) / 4;
    if (offset < SCREEN_W * SCREEN_H) {
        fb[offset] = data;
    }
}
