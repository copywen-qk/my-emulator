#include "am.h"

// 遊戲常量
#define BIRD_WIDTH 15
#define BIRD_HEIGHT 15
#define PIPE_WIDTH 40
#define PIPE_GAP 80
#define GRAVITY 1
#define JUMP_FORCE -4
#define PIPE_SPEED 3
#define INITIAL_LIVES 3
#define BLINK_DURATION 30

// 遊戲狀態
typedef struct {
    int bird_y;
    int bird_vy;
    int pipe_x;
    int pipe_y;
    int score;
    int high_score;
    int lives;
    int blink_timer;
    int passed_pipe;
    int game_over;
} GameState;

// 初始化遊戲
void game_init(GameState *g, int screen_width, int screen_height) {
    g->bird_y = screen_height / 2;
    g->bird_vy = 0;
    g->pipe_x = screen_width;
    g->pipe_y = screen_height / 2 - 40;
    g->score = 0;
    g->high_score = 0;
    g->lives = INITIAL_LIVES;
    g->blink_timer = 0;
    g->passed_pipe = 0;
    g->game_over = 0;
}

// 碰撞檢測
int check_collision(GameState *g, int screen_height) {
    // 鳥的邊界
    int bird_top = g->bird_y;
    int bird_bottom = g->bird_y + BIRD_HEIGHT;
    int bird_left = 50;
    int bird_right = 50 + BIRD_WIDTH;
    
    // 柱子的邊界
    int pipe_left = g->pipe_x;
    int pipe_right = g->pipe_x + PIPE_WIDTH;
    int pipe_top = g->pipe_y;
    int pipe_bottom = g->pipe_y + PIPE_GAP;
    
    // 檢查柱子碰撞
    if (bird_right > pipe_left && bird_left < pipe_right) {
        if (bird_top < pipe_top || bird_bottom > pipe_bottom) {
            return 1;
        }
    }
    
    // 檢查邊界碰撞
    if (bird_top < 0 || bird_bottom > screen_height) {
        return 1;
    }
    
    return 0;
}

// 繪製鳥
void draw_bird(uint32_t *fb, GameState *g, int screen_width) {
    if (g->blink_timer > 0 && (g->blink_timer / 5) % 2 == 0) {
        return; // 閃爍時不繪製
    }
    
    for (int y = g->bird_y; y < g->bird_y + BIRD_HEIGHT; y++) {
        for (int x = 50; x < 50 + BIRD_WIDTH; x++) {
            int idx = y * screen_width + x;
            
            // 簡單的鳥形狀
            int rel_x = x - 50;
            int rel_y = y - g->bird_y;
            
            // 繪製橢圓形鳥
            int dx = rel_x - BIRD_WIDTH/2;
            int dy = rel_y - BIRD_HEIGHT/2;
            if (dx*dx*4 + dy*dy < BIRD_WIDTH*BIRD_HEIGHT/4) {
                fb[idx] = 0xFFFFFF00; // 黃色
            }
        }
    }
}

// 繪製柱子
void draw_pipe(uint32_t *fb, GameState *g, int screen_width, int screen_height) {
    // 上方的柱子
    for (int y = 0; y < g->pipe_y; y++) {
        for (int x = g->pipe_x; x < g->pipe_x + PIPE_WIDTH; x++) {
            int idx = y * screen_width + x;
            fb[idx] = 0xFF00FF00; // 綠色
        }
    }
    
    // 下方的柱子
    for (int y = g->pipe_y + PIPE_GAP; y < screen_height; y++) {
        for (int x = g->pipe_x; x < g->pipe_x + PIPE_WIDTH; x++) {
            int idx = y * screen_width + x;
            fb[idx] = 0xFF00FF00; // 綠色
        }
    }
}

// 繪製生命值
void draw_lives(uint32_t *fb, GameState *g, int screen_width) {
    for (int i = 0; i < g->lives; i++) {
        int heart_x = 10 + i * 20;
        int heart_y = 10;
        
        // 簡單的心形
        for (int dy = 0; dy < 8; dy++) {
            for (int dx = 0; dx < 8; dx++) {
                int x = heart_x + dx;
                int y = heart_y + dy;
                int idx = y * screen_width + x;
                
                // 心形圖案
                if ((dx == 1 || dx == 6) && dy >= 2 && dy <= 6) fb[idx] = 0xFFFF0000;
                if ((dx == 2 || dx == 5) && dy >= 1 && dy <= 7) fb[idx] = 0xFFFF0000;
                if ((dx == 3 || dx == 4) && dy >= 0 && dy <= 8) fb[idx] = 0xFFFF0000;
            }
        }
    }
}

// 繪製分數
void draw_score(uint32_t *fb, GameState *g, int screen_width, int screen_height) {
    // 當前分數
    char score_str[20];
    int len = 0;
    int temp = g->score;
    
    if (temp == 0) {
        score_str[len++] = '0';
    } else {
        while (temp > 0) {
            score_str[len++] = '0' + (temp % 10);
            temp /= 10;
        }
    }
    score_str[len] = '\0';
    
    // 反轉字串
    for (int i = 0; i < len/2; i++) {
        char tmp = score_str[i];
        score_str[i] = score_str[len-1-i];
        score_str[len-1-i] = tmp;
    }
    
    // 繪製分數
    int score_x = screen_width - 100;
    int score_y = 15;
    
    for (int i = 0; i < len; i++) {
        int digit = score_str[i] - '0';
        int digit_x = score_x + i * 12;
        
        // 簡單的7段顯示器數字
        for (int dy = 0; dy < 10; dy++) {
            for (int dx = 0; dx < 8; dx++) {
                int x = digit_x + dx;
                int y = score_y + dy;
                int idx = y * screen_width + x;
                
                int draw = 0;
                switch(digit) {
                    case 0: draw = (dx==0||dx==7)||(dy==0||dy==9); break;
                    case 1: draw = (dx==3||dx==4); break;
                    case 2: draw = (dy==0||dy==4||dy==9)||(dx==7&&dy<4)||(dx==0&&dy>4); break;
                    case 3: draw = (dy==0||dy==4||dy==9)||(dx==7); break;
                    case 4: draw = (dy==4)||(dx==7)||(dx==0&&dy<4); break;
                    case 5: draw = (dy==0||dy==4||dy==9)||(dx==0&&dy<4)||(dx==7&&dy>4); break;
                    case 6: draw = (dy==0||dy==4||dy==9)||(dx==0)||(dx==7&&dy>4); break;
                    case 7: draw = (dy==0)||(dx==7); break;
                    case 8: draw = (dx==0||dx==7)||(dy==0||dy==4||dy==9); break;
                    case 9: draw = (dx==7)||(dx==0&&dy<4)||(dy==0||dy==4||dy==9); break;
                }
                
                if (draw) {
                    fb[idx] = 0xFFFFFFFF; // 白色
                }
            }
        }
    }
    
    // 最高分
    int hi_x = screen_width - 200;
    int hi_y = 15;
    
    // 繪製 "HI:"
    const char *hi_label = "HI:";
    for (int i = 0; i < 3; i++) {
        int char_x = hi_x + i * 12;
        for (int dy = 0; dy < 10; dy++) {
            for (int dx = 0; dx < 8; dx++) {
                int x = char_x + dx;
                int y = hi_y + dy;
                int idx = y * screen_width + x;
                
                // 簡單的字母
                if ((dx==0||dx==7)||(dy==0||dy==4||dy==9)) {
                    fb[idx] = 0xFFFFA500; // 橙色
                }
            }
        }
    }
    
    // 繪製最高分數字
    char hi_str[20];
    len = 0;
    temp = g->high_score;
    
    if (temp == 0) {
        hi_str[len++] = '0';
    } else {
        while (temp > 0) {
            hi_str[len++] = '0' + (temp % 10);
            temp /= 10;
        }
    }
    hi_str[len] = '\0';
    
    // 反轉字串
    for (int i = 0; i < len/2; i++) {
        char tmp = hi_str[i];
        hi_str[i] = hi_str[len-1-i];
        hi_str[len-1-i] = tmp;
    }
    
    int hi_num_x = hi_x + 40;
    for (int i = 0; i < len; i++) {
        int digit = hi_str[i] - '0';
        int digit_x = hi_num_x + i * 12;
        
        for (int dy = 0; dy < 10; dy++) {
            for (int dx = 0; dx < 8; dx++) {
                int x = digit_x + dx;
                int y = hi_y + dy;
                int idx = y * screen_width + x;
                
                int draw = 0;
                switch(digit) {
                    case 0: draw = (dx==0||dx==7)||(dy==0||dy==9); break;
                    case 1: draw = (dx==3||dx==4); break;
                    case 2: draw = (dy==0||dy==4||dy==9)||(dx==7&&dy<4)||(dx==0&&dy>4); break;
                    case 3: draw = (dy==0||dy==4||dy==9)||(dx==7); break;
                    case 4: draw = (dy==4)||(dx==7)||(dx==0&&dy<4); break;
                    case 5: draw = (dy==0||dy==4||dy==9)||(dx==0&&dy<4)||(dx==7&&dy>4); break;
                    case 6: draw = (dy==0||dy==4||dy==9)||(dx==0)||(dx==7&&dy>4); break;
                    case 7: draw = (dy==0)||(dx==7); break;
                    case 8: draw = (dx==0||dx==7)||(dy==0||dy==4||dy==9); break;
                    case 9: draw = (dx==7)||(dx==0&&dy<4)||(dy==0||dy==4||dy==9); break;
                }
                
                if (draw) {
                    fb[idx] = 0xFFFFA500; // 橙色
                }
            }
        }
    }
}

// 繪製遊戲結束畫面
void draw_game_over(uint32_t *fb, GameState *g, int screen_width, int screen_height) {
    if (!g->game_over) return;
    
    // 半透明黑色覆蓋層
    for (int y = screen_height/2 - 50; y < screen_height/2 + 50; y++) {
        for (int x = screen_width/2 - 100; x < screen_width/2 + 100; x++) {
            int idx = y * screen_width + x;
            fb[idx] = 0x80000000; // 半透明黑色
        }
    }
    
    // "GAME OVER" 文字
    int text_x = screen_width/2 - 45;
    int text_y = screen_height/2 - 20;
    
    const char *game_over = "GAME OVER";
    for (int i = 0; i < 9; i++) {
        int char_x = text_x + i * 10;
        for (int dy = 0; dy < 15; dy++) {
            for (int dx = 0; dx < 8; dx++) {
                int x = char_x + dx;
                int y = text_y + dy;
                int idx = y * screen_width + x;
                
                // 簡單的字元邊框
                if (dx == 0 || dx == 7 || dy == 0 || dy == 14) {
                    fb[idx] = 0xFFFF0000; // 紅色
                }
            }
        }
    }
    
    // 分數顯示
    int score_x = screen_width/2 - 30;
    int score_y = screen_height/2 + 10;
    
    char final_score[50];
    int len = 0;
    final_score[len++] = 'S';
    final_score[len++] = 'c';
    final_score[len++] = 'o';
    final_score[len++] = 'r';
    final_score[len++] = 'e';
    final_score[len++] = ':';
    final_score[len++] = ' ';
    
    int temp = g->score;
    if (temp == 0) {
        final_score[len++] = '0';
    } else {
        char temp_str[20];
        int temp_len = 0;
        while (temp > 0) {
            temp_str[temp_len++] = '0' + (temp % 10);
            temp /= 10;
        }
        for (int i = temp_len-1; i >= 0; i--) {
            final_score[len++] = temp_str[i];
        }
    }
    final_score[len] = '\0';
    
    for (int i = 0; i < len; i++) {
        int char_x = score_x + i * 8;
        for (int dy = 0; dy < 10; dy++) {
            for (int dx = 0; dx < 6; dx++) {
                int x = char_x + dx;
                int y = score_y + dy;
                int idx = y * screen_width + x;
                
                if (dx == 0 || dx == 5 || dy == 0 || dy == 9) {
                    fb[idx] = 0xFFFFFF00; // 黃色
                }
            }
        }
    }
    
    // 重新開始提示
    int restart_x = screen_width/2 - 70;
    int restart_y = screen_height/2 + 30;
    
    const char *restart = "PRESS ANY KEY TO RESTART";
    for (int i = 0; i < 24; i++) {
        int char_x = restart_x + i * 6;
        for (int dy = 0; dy < 8; dy++) {
            for (int dx = 0; dx < 4; dx++) {
                int x = char_x + dx;
                int y = restart_y + dy;
                int idx = y * screen_width + x;
                
                if (dx == 0 || dx == 3 || dy == 0 || dy == 7) {
                    fb[idx] = 0xFF00FF00; // 綠色
                }
            }
        }
    }
}

void _start() {
    uint32_t conf = io_read(VGACTL_ADDR);
    int width = conf >> 16;
    int height = conf & 0xffff;
    
    GameState game;
    game_init(&game, width, height);
    
    uint64_t next_frame = uptime();
    uint32_t *fb = (uint32_t *)FB_ADDR;
    
    while (1) {
        // FPS 控制 (~60 FPS)
        while (uptime() < next_frame);
        next_frame += 16666;
        
        // 清除屏幕（天空藍）
        for (int i = 0; i < width * height; i++) {
            fb[i] = 0xFF87CEEB;
        }
        
        if (!game.game_over) {
            // 輸入處理
            if (io_read(KBD_ADDR) != 0) {
                game.bird_vy = JUMP_FORCE;
            }
            
            // 物理更新
            game.bird_vy += GRAVITY;
            game.bird_y += game.bird_vy;
            game.pipe_x -= PIPE_SPEED;
            
            // 柱子重置
            if (game.pipe_x < -PIPE_WIDTH) {
                game.pipe_x = width;
                game.passed_pipe = 0;
                // 隨機柱子高度（使用32位運算避免鏈接問題）
                uint32_t rand_val = (uint32_t)uptime();
                game.pipe_y = 50 + (rand_val % (height - PIPE_GAP - 100));
            }
            
            // 檢查通過柱子
            if (!game.passed_pipe && game.pipe_x + PIPE_WIDTH < 50) {
                game.score++;
                game.passed_pipe = 1;
                
                // 更新最高分
                if (game.score > game.high_score) {
                    game.high_score = game.score;
                }
            }
            
            // 邊界檢查
            if (game.bird_y < 0) game.bird_y = 0;
            if (game.bird_y > height - BIRD_HEIGHT) game.bird_y = height - BIRD_HEIGHT;
            
            // 碰撞檢測
            if (check_collision(&game, height)) {
                game.lives--;
                game.blink_timer = BLINK_DURATION;
                
                if (game.lives <= 0) {
                    game.game_over = 1;
                } else {
                    // 重置鳥的位置
                    game.bird_y = height / 2;
                    game.bird_vy = 0;
                }
            }
            
            // 更新閃爍計時器
            if (game.blink_timer > 0) {
                game.blink_timer--;
            }
        } else {
            // 遊戲結束狀態，等待重新開始
            if (io_read(KBD_ADDR) != 0) {
                game_init(&game, width, height);
            }
        }
        
        // 繪製遊戲元素
        draw_pipe(fb, &game, width, height);
        draw_bird(fb, &game, width);
        draw_lives(fb, &game, width);
        draw_score(fb, &game, width, height);
        draw_game_over(fb, &game, width, height);
    }
}

// 注意：這個遊戲需要適當的硬體支持（顯示器、鍵盤輸入）
// 在真實的 NEMU 環境中運行前，請確保相關硬體模組已正確實現