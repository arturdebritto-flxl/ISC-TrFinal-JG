# ============================================================
# Controle dos estados gerais do jogo
# ============================================================

.text

init_game:
    la t0, game_state
    li t1, STATE_MENU
    sw t1, 0(t0)

    la t0, current_level
    li t1, LEVEL_NONE
    sw t1, 0(t0)

    la t0, current_wave
    sw zero, 0(t0)

    la t0, total_waves
    sw zero, 0(t0)

    la t0, remaining_enemies
    sw zero, 0(t0)

    la t0, wave_spawned
    sw zero, 0(t0)

    la t0, boss_active
    sw zero, 0(t0)

    la t0, score
    sw zero, 0(t0)

    la t0, frame_counter
    sw zero, 0(t0)

    la t0, animation_tick
    sw zero, 0(t0)

    la t0, animation_frame
    sw zero, 0(t0)

    la t0, post_boss_explosion_timer
    sw zero, 0(t0)

    la t0, town_spawn_timer
    sw zero, 0(t0)

    la t0, town_exit_unlocked
    sw zero, 0(t0)

    la t0, town_exit_blink_timer
    sw zero, 0(t0)

    la t0, town_exit_blink_frame
    sw zero, 0(t0)

    la t0, town_exit_transitioned
    sw zero, 0(t0)

    la t0, debug_mode
    li t1, 1
    sw t1, 0(t0)

    la t0, last_key
    sw zero, 0(t0)

    la t0, key_pressed
    sw zero, 0(t0)

    la t0, shoot_request_pending
    sw zero, 0(t0)

    ret

# Limpa eventos e buffers que nao podem atravessar mudancas de estado.
clear_input_buffers:
    la t0, last_key
    sw zero, 0(t0)

    la t0, key_pressed
    sw zero, 0(t0)

    la t0, cutscene_text_visible
    sw zero, 0(t0)

    la t0, shoot_request_pending
    sw zero, 0(t0)

    la t0, shoot_hold_timer
    sw zero, 0(t0)

    la t0, move_x_direction
    sw zero, 0(t0)

    la t0, move_x_timer
    sw zero, 0(t0)

    la t0, move_y_direction
    sw zero, 0(t0)

    la t0, move_y_timer
    sw zero, 0(t0)

    la t0, player_burst_remaining
    sw zero, 0(t0)

    la t0, player_burst_interval_timer
    sw zero, 0(t0)

    ret

# ------------------------------------------------------------
# set_state_level1
# Coloca o jogo na primeira fase: cidade.
#
# Entrada: nenhuma
# Saída: estado e cenário atualizados
# Modifica: t0, t1
# ------------------------------------------------------------

set_state_level1:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, game_state
    li t1, STATE_LEVEL1
    sw t1, 0(t0)

    la t0, current_level
    li t1, LEVEL_TOWN
    sw t1, 0(t0)

    la t0, player_x
    li t1, PLAYER_START_X
    sw t1, 0(t0)

    la t0, player_y
    li t1, PLAYER_START_Y
    sw t1, 0(t0)

    call init_level1
    call clear_input_buffers

    lw ra,0(sp)
    addi sp, sp, 4

    ret

# ------------------------------------------------------------
# set_state_level2
# Coloca o jogo na segunda fase: esgoto, e inicializa a fase.
#
# Entrada: nenhuma
# Saida: estado, cenario e dados da fase 2 atualizados
# Modifica: t0, t1
# ------------------------------------------------------------

set_state_level2:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, game_state
    li t1, STATE_LEVEL2
    sw t1, 0(t0)

    la t0, current_level
    li t1, LEVEL_SEWER
    sw t1, 0(t0)

    la t0, player_x
    li t1, PLAYER_START_X
    sw t1, 0(t0)

    la t0, player_y
    li t1, PLAYER_START_Y
    sw t1, 0(t0)

    call init_level2
    call clear_input_buffers

    lw ra, 0(sp)
    addi sp, sp, 4

    ret

# ------------------------------------------------------------
# set_state_level3
# Coloca o jogo na fase final: laboratorio.
# A fase comeca com hordas; o boss aparecera depois.
#
# Entrada: nenhuma
# Saida: estado, cenario e dados iniciais do laboratorio atualizados
# Modifica: t0, t1
# ------------------------------------------------------------

set_state_level3:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, game_state
    li t1, STATE_LEVEL3
    sw t1, 0(t0)

    la t0, current_level
    li t1, LEVEL_LABORATORY
    sw t1, 0(t0)

    la t0, player_x
    li t1, PLAYER_LAB_START_X
    sw t1, 0(t0)

    la t0, player_y
    li t1, PLAYER_LAB_START_Y
    sw t1, 0(t0)

    call init_level3
    call clear_input_buffers

    lw ra, 0(sp)
    addi sp, sp, 4

    ret

# ------------------------------------------------------------
# Estados de cutscene. A fase de destino e inicializada somente
# quando o jogador avanca a tela com SPACE ou ENTER.
# ------------------------------------------------------------

set_state_cutscene_intro:
    la t0, game_state
    li t1, STATE_CUTSCENE_INTRO
    sw t1, 0(t0)
    j clear_input_buffers

set_state_cutscene_level2:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, game_state
    li t1, STATE_CUTSCENE_LEVEL2
    sw t1, 0(t0)

    call clear_input_buffers

    lw ra, 0(sp)
    addi sp, sp, 4
    ret

set_state_cutscene_level3:
    la t0, game_state
    li t1, STATE_CUTSCENE_LEVEL3
    sw t1, 0(t0)
    j clear_input_buffers

set_state_cutscene_detonator:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, game_state
    li t1, STATE_CUTSCENE_DETONATOR
    sw t1, 0(t0)

    la t0, post_boss_explosion_timer
    sw zero, 0(t0)

    call clear_input_buffers

    lw ra, 0(sp)
    addi sp, sp, 4
    ret

set_state_cutscene_explosion:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, game_state
    li t1, STATE_CUTSCENE_EXPLOSION
    sw t1, 0(t0)

    la t0, post_boss_explosion_timer
    sw zero, 0(t0)

    call clear_input_buffers

    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# ------------------------------------------------------------
# set_state_victory
# Coloca o jogo no estado de vitoria.
# ------------------------------------------------------------

set_state_victory:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, game_state
    li t1, STATE_VICTORY
    sw t1, 0(t0)

    li a0, 88
    li a1, 180
    li a2, 9
    li a3, 90
    call play_music_note

    call clear_input_buffers

    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# ------------------------------------------------------------
# set_state_game_over
# Coloca o jogo no estado de derrota.
# ------------------------------------------------------------

set_state_game_over:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, game_state
    li t1, STATE_GAME_OVER
    sw t1, 0(t0)

    li a0, 38
    li a1, 180
    li a2, 9
    li a3, 80
    call play_music_note

    call clear_input_buffers

    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# ------------------------------------------------------------
# set_state_menu
# Volta para o menu inicial.
# ------------------------------------------------------------

set_state_menu:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, game_state
    li t1, STATE_MENU
    sw t1, 0(t0)

    la t0, current_level
    li t1, LEVEL_NONE
    sw t1, 0(t0)

    la t0, current_wave
    sw zero, 0(t0)

    la t0, total_waves
    sw zero, 0(t0)

    la t0, remaining_enemies
    sw zero, 0(t0)

    la t0, wave_spawned
    sw zero, 0(t0)

    la t0, boss_active
    sw zero, 0(t0)

    call clear_input_buffers

    lw ra, 0(sp)
    addi sp, sp, 4
    ret
