#include "am.h"

// 遊戲常量
#define BIRD_X 50
#define BIRD_SIZE 15
#define PIPE_WIDTH 40
#define PIPE_GAP 80
#define INIT_LIVES 3

// 遊戲狀態
int bird_y, bird_vy;
int pipe_x, pipe_y;
int score, high_score;
int lives;
int blink;
int game_over;
int frame_count;

// 初始化遊戲
void init_game(int width, int height) {
    bird_y = height / 2;
    bird_vy = 0;
    pipe_x = width;
    pipe_y = height / 2 - 40;
    score = 0;
    high_score = 0;
    lives = INIT_LIVES;
    blink = 0;
    game_over = 0;
    frame_count = 0;
}

// 碰撞檢測
int check_collision(int height) {
    // 鳥的邊界
    int bird_top = bird_y;
    int bird_bottom = bird_y + BIRD_SIZE;
    int bird_left = BIRD_X;
    int bird_right = BIRD_X + BIRD_SIZE;
    
    // 柱子的邊界
    int pipe_left = pipe_x;
    int pipe_right = pipe_x + PIPE_WIDTH;
    int pipe_top = pipe_y;
    int pipe_bottom = pipe_y + PIPE_GAP;
    
    // 檢查柱子碰撞
    if (bird_right > pipe_left && bird_left < pipe_right) {
        if (bird_top < pipe_top || bird_bottom > pipe_bottom) {
            return 1;
        }
    }
    
    // 檢查邊界碰撞
    if (bird_top < 0 || bird_bottom > height) {
        return 1;
    }
    
    return 0;
}

// 繪製數字（簡單版本）
void draw_digit(uint32_t *fb, int x, int y, int digit, int color, int width) {
    // 簡單的7段顯示器模式
    const int segments[10][7] = {
        {1,1,1,0,1,1,1}, // 0
        {0,0,1,0,0,1,0}, // 1
        {1,0,1,1,1,0,1}, // 2
        {1,0,1,1,0,1,1}, // 3
        {0,1,1,1,0,1,0}, // 4
        {1,1,0,1,0,1,1}, // 5
        {1,1,0,1,1,1,1}, // 6
        {1,0,1,0,0,1,0}, // 7
        {1,1,1,1,1,1,1}, // 8
        {1,1,1,1,0,1,1}  // 9
    };
    
    const int *seg = segments[digit];
    
    // 繪製7段
    if (seg[0]) for (int i = 0; i < 5; i++) fb[(y)*width + (x+i)] = color;     // 上橫
    if (seg[1]) for (int i = 0; i < 5; i++) fb[(y+i)*width + (x)] = color;     // 左上豎
    if (seg[2]) for (int i = 0; i < 5; i++) fb[(y+i)*width + (x+4)] = color;   // 右上豎
    if (seg[3]) for (int i = 0; i < 5; i++) fb[(y+4)*width + (x+i)] = color;   // 中橫
    if (seg[4]) for (int i = 0; i < 5; i++) fb[(y+5+i)*width + (x)] = color;   // 左下豎
    if (seg[5]) for (int i = 0; i < 5; i++) fb[(y+5+i)*width + (x+4)] = color; // 右下豎
    if (seg[6]) for (int i = 0; i < 5; i++) fb[(y+10)*width + (x+i)] = color;  // 下橫
}

// 繪製分數
void draw_score(uint32_t *fb, int width, int height) {
    // 當前分數
    int x = width - 60;
    int y = 10;
    int temp = score;
    int digits = 0;
    
    if (temp == 0) {
        draw_digit(fb, x, y, 0, 0xFFFFFFFF, width);
    } else {
        // 計算位數
        int temp2 = temp;
        while (temp2 > 0) {
            digits++;
            temp2 /= 10;
        }
        
        // 繪製每位數字
        temp2 = temp; // 重新賦值
        for (int i = digits-1; i >= 0; i--) {
            int digit = temp2 % 10;
            temp2 /= 10;
            draw_digit(fb, x - (digits-1-i)*12, y, digit, 0xFFFFFFFF, width);
        }
    }
    
    // 最高分
    x = width - 130;
    y = 10;
    
    // 繪製 "HI"
    for (int i = 0; i < 2; i++) {
        int char_x = x + i * 12;
        // 簡單的H和I
        for (int dy = 0; dy < 11; dy++) {
            for (int dx = 0; dx < 5; dx++) {
                int idx = (y+dy)*width + (char_x+dx);
                if (i == 0) { // H
                    if (dx == 0 || dx == 4 || dy == 5) fb[idx] = 0xFFFFA500;
                } else { // I
                    if (dx == 2) fb[idx] = 0xFFFFA500;
                }
            }
        }
    }
    
    // 繪製最高分數字
    x = width - 100;
    temp = high_score;
    
    if (temp == 0) {
        draw_digit(fb, x, y, 0, 0xFFFFA500, width);
    } else {
        digits = 0;
        temp2 = temp;
        while (temp2 > 0) {
            digits++;
            temp2 /= 10;
        }
        
        temp2 = temp; // 重新賦值
        for (int i = digits-1; i >= 0; i--) {
            int digit = temp2 % 10;
            temp2 /= 10;
            draw_digit(fb, x - (digits-1-i)*12, y, digit, 0xFFFFA500, width);
        }
    }
}

// 繪製生命值
void draw_lives(uint32_t *fb, int width) {
    for (int i = 0; i < lives; i++) {
        int x = 10 + i * 20;
        int y = 10;
        
        // 簡單的心形
        for (int dy = 0; dy < 8; dy++) {
            for (int dx = 0; dx < 8; dx++) {
                int idx = (y+dy)*width + (x+dx);
                
                // 心形模式
                if ((dx == 1 || dx == 6) && dy >= 2 && dy <= 6) fb[idx] = 0xFFFF0000;
                if ((dx == 2 || dx == 5) && dy >= 1 && dy <= 7) fb[idx] = 0xFFFF0000;
                if ((dx == 3 || dx == 4) && dy >= 0 && dy <= 8) fb[idx] = 0xFFFF0000;
            }
        }
    }
}

void _start() {
    uint32_t conf = io_read(VGACTL_ADDR);
    int width = conf >> 16;
    int height = conf & 0xffff;
    
    init_game(width, height);
    
    uint64_t next_frame = uptime();
    int passed_pipe = 0;
    
    while (1) {
        // FPS 控制
        while (uptime() < next_frame);
        next_frame += 16666;
        frame_count++;
        
        // 清除屏幕
        uint32_t *fb = (uint32_t *)FB_ADDR;
        for (int i = 0; i < width * height; i++) {
            fb[i] = 0xFF87CEEB; // 天空藍
        }
        
        if (!game_over) {
            // 輸入處理
            if (io_read(KBD_ADDR) != 0) {
                bird_vy = -4;
            }
            
            // 物理更新
            bird_vy += 1;
            bird_y += bird_vy;
            pipe_x -= 3;
            
            // 柱子重置
            if (pipe_x < -PIPE_WIDTH) {
                pipe_x = width;
                passed_pipe = 0;
                // 簡單的隨機高度（使用幀計數）
                pipe_y = 50 + (frame_count % (height - PIPE_GAP - 100));
            }
            
            // 檢查通過柱子
            if (!passed_pipe && pipe_x + PIPE_WIDTH < BIRD_X) {
                score++;
                passed_pipe = 1;
                
                // 更新最高分
                if (score > high_score) {
                    high_score = score;
                }
            }
            
            // 邊界檢查
            if (bird_y < 0) bird_y = 0;
            if (bird_y > height - BIRD_SIZE) bird_y = height - BIRD_SIZE;
            
            // 碰撞檢測
            if (check_collision(height)) {
                lives--;
                blink = 30; // 閃爍30幀
                
                if (lives <= 0) {
                    game_over = 1;
                } else {
                    // 重置鳥的位置
                    bird_y = height / 2;
                    bird_vy = 0;
                }
            }
            
            // 更新閃爍
            if (blink > 0) blink--;
            
            // 繪製柱子
            for (int y = 0; y < pipe_y; y++) {
                for (int x = pipe_x; x < pipe_x + PIPE_WIDTH; x++) {
                    fb[y * width + x] = 0xFF00FF00; // 綠色
                }
            }
            for (int y = pipe_y + PIPE_GAP; y < height; y++) {
                for (int x = pipe_x; x < pipe_x + PIPE_WIDTH; x++) {
                    fb[y * width + x] = 0xFF00FF00; // 綠色
                }
            }
            
            // 繪製鳥（閃爍時隱藏）
            if (blink == 0 || (blink / 5) % 2 == 0) {
                for (int y = bird_y; y < bird_y + BIRD_SIZE; y++) {
                    for (int x = BIRD_X; x < BIRD_X + BIRD_SIZE; x++) {
                        // 簡單的圓形鳥
                        int dx = x - BIRD_X - BIRD_SIZE/2;
                        int dy = y - bird_y - BIRD_SIZE/2;
                        if (dx*dx + dy*dy < (BIRD_SIZE/2)*(BIRD_SIZE/2)) {
                            fb[y * width + x] = 0xFFFFFF00; // 黃色
                        }
                    }
                }
            }
            
            // 繪製UI
            draw_lives(fb, width);
            draw_score(fb, width, height);
            
        } else {
            // 遊戲結束畫面
            // 繪製遊戲結束文字
            int center_x = width / 2 - 40;
            int center_y = height / 2 - 20;
            
            const char *text = "GAME OVER";
            for (int i = 0; i < 9; i++) {
                int char_x = center_x + i * 10;
                for (int dy = 0; dy < 15; dy++) {
                    for (int dx = 0; dx < 8; dx++) {
                        int idx = (center_y+dy)*width + (char_x+dx);
                        if (dx == 0 || dx == 7 || dy == 0 || dy == 14) {
                            fb[idx] = 0xFFFF0000; // 紅色邊框
                        }
                    }
                }
            }
            
            // 等待重新開始
            if (io_read(KBD_ADDR) != 0) {
                init_game(width, height);
                passed_pipe = 0;
            }
        }
    }
}