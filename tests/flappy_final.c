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
int passed_pipe;

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
    passed_pipe = 0;
}

// 碰撞檢測
int check_collision(int height) {
    // 鳥的邊界
    int bird_top = bird_y;
    int bird_bottom = bird_y + BIRD_SIZE;
    
    // 柱子的邊界
    int pipe_left = pipe_x;
    int pipe_right = pipe_x + PIPE_WIDTH;
    int pipe_top = pipe_y;
    int pipe_bottom = pipe_y + PIPE_GAP;
    
    // 檢查柱子碰撞
    if (60 > pipe_left && 50 < pipe_right) {
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

// 繪製生命值（簡單紅心）
void draw_lives(uint32_t *fb, int width) {
    for (int i = 0; i < lives; i++) {
        int x = 10 + i * 20;
        int y = 10;
        
        // 簡單的心形
        for (int dy = 0; dy < 8; dy++) {
            for (int dx = 0; dx < 8; dx++) {
                int idx = (y+dy)*width + (x+dx);
                int draw = 0;
                
                if ((dx == 1 || dx == 6) && dy >= 2 && dy <= 6) draw = 1;
                if ((dx == 2 || dx == 5) && dy >= 1 && dy <= 7) draw = 1;
                if ((dx == 3 || dx == 4) && dy >= 0 && dy <= 8) draw = 1;
                
                if (draw) fb[idx] = 0xFFFF0000; // 紅色
            }
        }
    }
}

// 繪製分數（簡單數字）
void draw_number(uint32_t *fb, int x, int y, int num, int color, int width) {
    char buf[10];
    int len = 0;
    
    if (num == 0) {
        buf[len++] = '0';
    } else {
        int temp = num;
        while (temp > 0) {
            buf[len++] = '0' + (temp % 10);
            temp /= 10;
        }
    }
    
    // 反轉
    for (int i = 0; i < len/2; i++) {
        char tmp = buf[i];
        buf[i] = buf[len-1-i];
        buf[len-1-i] = tmp;
    }
    
    // 繪製每個數字
    for (int i = 0; i < len; i++) {
        int digit = buf[i] - '0';
        int digit_x = x + i * 8;
        
        // 簡單的數字顯示
        for (int dy = 0; dy < 10; dy++) {
            for (int dx = 0; dx < 6; dx++) {
                int idx = (y+dy)*width + (digit_x+dx);
                int draw = 0;
                
                switch(digit) {
                    case 0: draw = (dx==0||dx==5)||(dy==0||dy==9); break;
                    case 1: draw = (dx==2||dx==3); break;
                    case 2: draw = (dy==0||dy==4||dy==9)||(dx==5&&dy<4)||(dx==0&&dy>4); break;
                    case 3: draw = (dy==0||dy==4||dy==9)||(dx==5); break;
                    case 4: draw = (dy==4)||(dx==5)||(dx==0&&dy<4); break;
                    case 5: draw = (dy==0||dy==4||dy==9)||(dx==0&&dy<4)||(dx==5&&dy>4); break;
                    case 6: draw = (dy==0||dy==4||dy==9)||(dx==0)||(dx==5&&dy>4); break;
                    case 7: draw = (dy==0)||(dx==5); break;
                    case 8: draw = (dx==0||dx==5)||(dy==0||dy==4||dy==9); break;
                    case 9: draw = (dx==5)||(dx==0&&dy<4)||(dy==0||dy==4||dy==9); break;
                }
                
                if (draw) fb[idx] = color;
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
    
    while (1) {
        // FPS 控制 (~60 FPS)
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
                // 簡單的隨機高度
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
            
            // 繪製當前分數
            draw_number(fb, width - 80, 10, score, 0xFFFFFFFF, width);
            
            // 繪製最高分
            draw_number(fb, width - 160, 10, high_score, 0xFFFFA500, width);
            
            // 繪製 "HI" 標籤
            int hi_x = width - 180;
            for (int dy = 0; dy < 10; dy++) {
                for (int dx = 0; dx < 6; dx++) {
                    int idx = (10+dy)*width + (hi_x+dx);
                    // 簡單的H
                    if (dx == 0 || dx == 5 || dy == 5) fb[idx] = 0xFFFFA500;
                }
            }
            for (int dy = 0; dy < 10; dy++) {
                for (int dx = 0; dx < 6; dx++) {
                    int idx = (10+dy)*width + (hi_x+8+dx);
                    // 簡單的I
                    if (dx == 2 || dx == 3) fb[idx] = 0xFFFFA500;
                }
            }
            
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
            
            // 顯示分數
            draw_number(fb, width/2 - 30, height/2 + 10, score, 0xFFFFFF00, width);
            
            // 等待重新開始
            if (io_read(KBD_ADDR) != 0) {
                init_game(width, height);
            }
        }
    }
}