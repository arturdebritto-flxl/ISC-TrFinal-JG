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

# ------------------------------------------------------------
# Controle de testes e apresentação
# ------------------------------------------------------------

debug_mode:             .word 1

# ------------------------------------------------------------
# Entrada de teclado
# ------------------------------------------------------------

last_key:               .word 0
key_pressed:            .word 0
noise_timer:            .word 0
