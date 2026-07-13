# ============================================================
# Dados globais controlados pelo core
# ============================================================

.data

# ------------------------------------------------------------
# Estado atual do jogo
# ------------------------------------------------------------

game_state:             .word STATE_MENU
current_level:          .word LEVEL_NONE

# ------------------------------------------------------------
# Controle de hordas e progressão
# ------------------------------------------------------------

current_wave:           .word 0
total_waves:            .word 0
remaining_enemies:      .word 0
wave_spawned:           .word 0
boss_active:            .word 0

# ------------------------------------------------------------
# Pontuação e controle temporal
# ------------------------------------------------------------

score:                  .word 0
frame_counter:          .word 0
draw_frame:             .word 1
animation_tick:         .word 0
animation_frame:        .word 0
post_boss_explosion_timer: .word 0
town_spawn_timer:       .word 0
town_exit_unlocked:     .word 0
town_exit_blink_timer:  .word 0
town_exit_blink_frame:  .word 0
town_exit_transitioned: .word 0

# Obstaculos internos autoritativos do Town: x0, y0, x1, y1.
# Intervalos semiabertos; os limites externos sao testados diretamente.
town_collision_aabbs:
    .word 182,28,203,38, 193,37,203,55
    .word 271,31,302,42, 265,40,281,54, 286,40,296,50
    .word 171,80,181,126, 179,88,199,98
    .word 179,116,197,126, 187,124,197,142
    .word 37,141,88,173, 86,154,119,160
    .word 100,196,110,217, 216,211,244,221
town_collision_aabbs_end:

# ------------------------------------------------------------
# Controle de testes e apresentação
# ------------------------------------------------------------

debug_mode:             .word 1

# ------------------------------------------------------------
# Entrada de teclado
# ------------------------------------------------------------

last_key:               .word 0
key_pressed:            .word 0
cutscene_text_visible:  .word 0
shoot_request_pending:  .word 0
noise_timer:            .word 0
