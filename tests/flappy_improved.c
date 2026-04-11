#include "am.h"

// 遊戲狀態結構
typedef struct {
    int bird_y;          // 鳥的Y座標
    int bird_vy;         // 鳥的垂直速度
    int pipe_x;          // 柱子的X座標
    int pipe_w;          // 柱子寬度
    int pipe_gap;        // 柱子間隙
    int pipe_y;          // 柱子頂部Y座標
    int score;           // 當前分數
    int high_score;      // 最高分數
    int low_score;       // 最低分數（第一次遊戲時初始化）
    int lives;           // 生命值（3點血量）
    int blink_counter;   // 閃爍計數器
    int passed_pipe;     // 是否已通過當前柱子
    int game_over;       // 遊戲結束標誌
} GameState;

// 初始化遊戲狀態
void init_game(GameState *game, int width, int height) {
    game->bird_y = height / 2;
    game->bird_vy = 0;
    game->pipe_x = width;
    game->pipe_w = 40;
    game->pipe_gap = 80;
    game->pipe_y = height / 2 - 40;
    game->score = 0;
    game->high_score = 0;
    game->low_score = 9999;  // 初始化為大值
    game->lives = 3;
    game->blink_counter = 0;
    game->passed_pipe = 0;
    game->game_over = 0;
}

// 檢測碰撞
int check_collision(GameState *game, int width, int height) {
    // 鳥的邊界
    int bird_left = 50;
    int bird_right = 65;
    int bird_top = game->bird_y;
    int bird_bottom = game->bird_y + 15;
    
    // 柱子的邊界
    int pipe_left = game->pipe_x;
    int pipe_right = game->pipe_x + game->pipe_w;
    int pipe_top = game->pipe_y;
    int pipe_bottom = game->pipe_y + game->pipe_gap;
    
    // 檢查是否撞到上方的柱子
    if (bird_right > pipe_left && bird_left < pipe_right) {
        if (bird_top < pipe_top) {
            return 1;  // 撞到上方柱子
        }
    }
    
    // 檢查是否撞到下方的柱子
    if (bird_right > pipe_left && bird_left < pipe_right) {
        if (bird_bottom > pipe_bottom) {
            return 1;  // 撞到下方柱子
        }
    }
    
    // 檢查是否撞到上下邊界
    if (bird_top < 0 || bird_bottom > height) {
        return 1;  // 撞到邊界
    }
    
    return 0;  // 無碰撞
}

// 更新分數記錄
void update_score_records(GameState *game) {
    if (game->score > game->high_score) {
        game->high_score = game->score;
    }
    if (game->score < game->low_score && game->score > 0) {
        game->low_score = game->score;
    }
}

// 繪製遊戲畫面
void draw_game(uint32_t *fb, GameState *game, int width, int height) {
    for (int i = 0; i < width * height; i++) {
        int x = i % width;
        int y = i / width;
        
        // 計算顏色
        uint32_t color = 0xFF87CEEB;  // 默認背景色（天空藍）
        
        // 繪製鳥（根據閃爍狀態決定是否顯示）
        int draw_bird = 1;
        if (game->blink_counter > 0 && (game->blink_counter / 5) % 2 == 0) {
            draw_bird = 0;  // 閃爍時隱藏鳥
        }
        
        if (draw_bird && x >= 50 && x < 65 && y >= game->bird_y && y < game->bird_y + 15) {
            color = 0xFFFFFF00;  // 黃色鳥
        }
        // 繪製柱子
        else if (x >= game->pipe_x && x < game->pipe_x + game->pipe_w && 
                (y < game->pipe_y || y > game->pipe_y + game->pipe_gap)) {
            color = 0xFF00FF00;  // 綠色柱子
        }
        // 繪製分數顯示區域（頂部）
        else if (y < 20) {
            // 分數顯示背景
            color = 0xFF333333;  // 深灰色
            
            // 繪製分數文字位置
            if (y >= 5 && y < 15) {
                // 這裡可以添加文字渲染，但需要字體數據
                // 暫時用簡單的條狀顯示
            }
        }
        
        fb[i] = color;
    }
    
    // 繪製生命值（簡單的紅心表示）
    for (int life = 0; life < game->lives; life++) {
        int heart_x = 10 + life * 25;
        for (int dy = 0; dy < 10; dy++) {
            for (int dx = 0; dx < 10; dx++) {
                int px = heart_x + dx;
                int py = 5 + dy;
                if (px >= 0 && px < width && py >= 0 && py < 20) {
                    int idx = py * width + px;
                    // 簡單的心形圖案
                    if ((dx == 2 || dx == 7) && dy >= 2 && dy <= 8) fb[idx] = 0xFFFF0000;
                    if ((dx == 3 || dx == 6) && dy >= 1 && dy <= 9) fb[idx] = 0xFFFF0000;
                    if ((dx == 4 || dx == 5) && dy >= 0 && dy <= 10) fb[idx] = 0xFFFF0000;
                }
            }
        }
    }
}

// 繪製分數文字（簡單的數字顯示）
void draw_score(uint32_t *fb, GameState *game, int width) {
    // 當前分數
    int score_x = width - 100;
    int temp_score = game->score;
    int digit_pos = 0;
    
    do {
        int digit = temp_score % 10;
        temp_score /= 10;
        
        // 簡單的數字顯示（7段顯示器風格）
        for (int dy = 0; dy < 7; dy++) {
            for (int dx = 0; dx < 5; dx++) {
                int px = score_x - digit_pos * 8 - dx;
                int py = 7 + dy;
                if (px >= 0 && px < width && py >= 0 && py < 20) {
                    int idx = py * width + px;
                    
                    // 簡單的數字圖案
                    int draw_pixel = 0;
                    switch(digit) {
                        case 0:
                            if ((dx == 0 || dx == 4) && dy >= 0 && dy <= 6) draw_pixel = 1;
                            if (dx >= 0 && dx <= 4 && (dy == 0 || dy == 6)) draw_pixel = 1;
                            break;
                        case 1:
                            if (dx == 2 && dy >= 0 && dy <= 6) draw_pixel = 1;
                            break;
                        case 2:
                            if (dy == 0 || dy == 3 || dy == 6) draw_pixel = 1;
                            if ((dx == 4 && dy <= 3) || (dx == 0 && dy >= 3)) draw_pixel = 1;
                            break;
                        // 其他數字類似，這裡簡化
                        default:
                            if (dx == 2 && dy >= 0 && dy <= 6) draw_pixel = 1; // 暫時都用豎線表示
                    }
                    
                    if (draw_pixel) {
                        fb[idx] = 0xFFFFFFFF;  // 白色
                    }
                }
            }
        }
        
        digit_pos++;
    } while (temp_score > 0 && digit_pos < 5);
    
    // 繪製最高分標籤
    const char *high_label = "HI:";
    for (int i = 0; i < 3; i++) {
        int label_x = width - 200 + i * 8;
        for (int dy = 0; dy < 7; dy++) {
            for (int dx = 0; dx < 5; dx++) {
                int px = label_x + dx;
                int py = 7 + dy;
                if (px >= 0 && px < width && py >= 0 && py < 20) {
                    int idx = py * width + px;
                    // 簡單的字母顯示
                    if (dx == 0 || dx == 4 || dy == 0 || dy == 3) {
                        fb[idx] = 0xFFFFFF00;  // 黃色
                    }
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
    init_game(&game, width, height);
    
    uint64_t next_frame = uptime();
    
    while (1) {
        // FPS Control (~60 FPS)
        while (uptime() < next_frame);
        next_frame += 16666;
        
        if (!game.game_over) {
            // 輸入處理
            if (io_read(KBD_ADDR) != 0) {
                game.bird_vy = -4;
            }
            
            // 物理更新
            game.bird_vy += 1;
            game.bird_y += game.bird_vy;
            game.pipe_x -= 3;
            
            // 柱子重置
            if (game.pipe_x < -game.pipe_w) {
                game.pipe_x = width;
                game.passed_pipe = 0;
                // 隨機生成新的柱子高度
                game.pipe_y = 50 + (uptime() % 200);
                if (game.pipe_y > height - game.pipe_gap - 50) {
                    game.pipe_y = height - game.pipe_gap - 50;
                }
            }
            
            // 檢查是否通過柱子
            if (!game.passed_pipe && game.pipe_x + game.pipe_w < 50) {
                game.score++;
                game.passed_pipe = 1;
                update_score_records(&game);
            }
            
            // 邊界檢查
            if (game.bird_y < 0) game.bird_y = 0;
            if (game.bird_y > height - 10) game.bird_y = height - 10;
            
            // 碰撞檢測
            if (check_collision(&game, width, height)) {
                game.lives--;
                game.blink_counter = 30;  // 閃爍30幀（約0.5秒）
                
                if (game.lives <= 0) {
                    game.game_over = 1;
                    update_score_records(&game);
                } else {
                    // 重置鳥的位置
                    game.bird_y = height / 2;
                    game.bird_vy = 0;
                }
            }
            
            // 更新閃爍計數器
            if (game.blink_counter > 0) {
                game.blink_counter--;
            }
        } else {
            // 遊戲結束狀態，等待重新開始
            if (io_read(KBD_ADDR) != 0) {
                init_game(&game, width, height);
            }
        }
        
        // 繪製遊戲
        uint32_t *fb = (uint32_t *)FB_ADDR;
        draw_game(fb, &game, width, height);
        draw_score(fb, &game, width);
        
        // 遊戲結束顯示
        if (game.game_over) {
            // 在屏幕中央顯示遊戲結束文字
            int center_x = width / 2 - 40;
            int center_y = height / 2 - 20;
            
            const char *game_over = "GAME OVER";
            for (int i = 0; i < 9; i++) {
                int char_x = center_x + i * 10;
                for (int dy = 0; dy < 15; dy++) {
                    for (int dx = 0; dx < 8; dx++) {
                        int px = char_x + dx;
                        int py = center_y + dy;
                        if (px >= 0 && px < width && py >= 0 && py < height) {
                            int idx = py * width + px;
                            // 簡單的字元顯示
                            if (dx == 0 || dx == 7 || dy == 0 || dy == 14) {
                                fb[idx] = 0xFFFF0000;  // 紅色邊框
                            } else {
                                fb[idx] = 0xFF000000;  // 黑色填充
                            }
                        }
                    }
                }
            }
            
            // 顯示重新開始提示
            const char *restart = "PRESS ANY KEY";
            int restart_x = width / 2 - 60;
            int restart_y = center_y + 30;
            
            for (int i = 0; i < 13; i++) {
                int char_x = restart_x + i * 10;
                for (int dy = 0; dy < 10; dy++) {
                    for (int dx = 0; dx < 6; dx++) {
                        int px = char_x + dx;
                        int py = restart_y + dy;
                        if (px >= 0 && px < width && py >= 0 && py < height) {
                            int idx = py * width + px;
                            if (dx == 0 || dx == 5 || dy == 0 || dy == 9) {
                                fb[idx] = 0xFFFFFF00;  // 黃色邊框
                            }
                        }
                    }
                }
            }
        }
    }
}