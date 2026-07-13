# =====================================================
# Telas de menus, game over e vitoria
# =====================================================

.text

# Contrato: a0=1 para START; a0=0 para LEAVE.
menu_game_screen:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, selected
    sw zero, 0(t0)

menu_redraw:
    call begin_frame
    call draw_menu_screen
    call end_frame
    call menu_wait_key

    li t0, 'q'
    beq a0, t0, menu_leave
    li t0, 'Q'
    beq a0, t0, menu_leave

    li t0, 'w'
    beq a0, t0, menu_move_up
    li t0, 'W'
    beq a0, t0, menu_move_up
    li t0, 'k'
    beq a0, t0, menu_move_up
    li t0, 'K'
    beq a0, t0, menu_move_up

    li t0, 's'
    beq a0, t0, menu_move_down
    li t0, 'S'
    beq a0, t0, menu_move_down
    li t0, 'j'
    beq a0, t0, menu_move_down
    li t0, 'J'
    beq a0, t0, menu_move_down

    li t0, 32
    beq a0, t0, menu_confirm
    li t0, 10
    beq a0, t0, menu_confirm
    li t0, 13
    beq a0, t0, menu_confirm
    j menu_redraw

menu_move_up:
    la t0, selected
    lw t1, 0(t0)
    addi t1, t1, -1
    bgez t1, menu_store_selection
    li t1, 2
    j menu_store_selection

menu_move_down:
    la t0, selected
    lw t1, 0(t0)
    addi t1, t1, 1
    li t2, 3
    blt t1, t2, menu_store_selection
    li t1, 0

menu_store_selection:
    sw t1, 0(t0)
    j menu_redraw

menu_confirm:
    la t0, selected
    lw t1, 0(t0)
    beqz t1, menu_start
    li t2, 1
    beq t1, t2, options_redraw
    j menu_leave

options_redraw:
    call begin_frame
    call draw_options_screen
    call end_frame
    call menu_wait_key

    li t0, 'q'
    beq a0, t0, menu_leave
    li t0, 'Q'
    beq a0, t0, menu_leave

    li t0, 'w'
    beq a0, t0, options_move_up
    li t0, 'W'
    beq a0, t0, options_move_up
    li t0, 'k'
    beq a0, t0, options_move_up
    li t0, 'K'
    beq a0, t0, options_move_up

    li t0, 's'
    beq a0, t0, options_move_down
    li t0, 'S'
    beq a0, t0, options_move_down
    li t0, 'j'
    beq a0, t0, options_move_down
    li t0, 'J'
    beq a0, t0, options_move_down

    li t0, 32
    beq a0, t0, options_confirm
    li t0, 10
    beq a0, t0, options_confirm
    li t0, 13
    beq a0, t0, options_confirm
    j options_redraw

options_move_up:
    la t0, option_selected
    lw t1, 0(t0)
    addi t1, t1, -1
    bgez t1, options_store_selection
    li t1, 2
    j options_store_selection

options_move_down:
    la t0, option_selected
    lw t1, 0(t0)
    addi t1, t1, 1
    li t2, 3
    blt t1, t2, options_store_selection
    li t1, 0

options_store_selection:
    sw t1, 0(t0)
    j options_redraw

options_confirm:
    la t0, option_selected
    lw t1, 0(t0)
    beqz t1, options_toggle_music
    li t2, 1
    beq t1, t2, options_toggle_sfx
    j menu_redraw

options_toggle_music:
    la t0, music_enabled
    lw t1, 0(t0)
    xori t1, t1, 1
    sw t1, 0(t0)
    j options_redraw

options_toggle_sfx:
    la t0, sfx_enabled
    lw t1, 0(t0)
    xori t1, t1, 1
    sw t1, 0(t0)
    j options_redraw

menu_start:
    li a0, 1
    j menu_return

menu_leave:
    li a0, 0

menu_return:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# A leitura do registrador de dados consome exatamente um evento MMIO.
menu_wait_key:
    li t0, KDMMIO_Ctrl

menu_wait_key_loop:
    lw t1, 0(t0)
    andi t1, t1, 1
    beqz t1, menu_wait_key_loop
    li t0, KDMMIO_Data
    lw a0, 0(t0)
    ret

# Estados globais de audio consultados pelas chamadas MIDI reais.
play_music_note:
    la t0, music_enabled
    lw t1, 0(t0)
    beqz t1, end_play_music_note
    li a7, 31
    ecall

end_play_music_note:
    ret

# Caminho unico de inicializacao usado por START e RETRY.
start_new_game_from_menu:
    addi sp, sp, -4
    sw ra, 0(sp)

    call clear_input_frame

    li a0, 72
    li a1, 120
    li a2, 9
    li a3, 80
    call play_music_note

    call reset_game_run
    call set_state_cutscene_intro

    call clear_input_frame

    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# ------------------------------------------------------------
# update_cutscene. SPACE ou ENTER avanca para a fase associada.
# Outras teclas, inclusive C/c, nao alteram o estado.
# ------------------------------------------------------------

# Retorna a0=1 quando o evento do frame e SPACE ou ENTER.
cutscene_advance_pressed:
    li a0, 0

    la t0, key_pressed
    lw t1, 0(t0)
    beqz t1, end_cutscene_advance_pressed

    la t0, last_key
    lw t1, 0(t0)
    li t2, 32
    beq t1, t2, cutscene_accept_key
    li t2, 10
    beq t1, t2, cutscene_accept_key
    li t2, 13
    bne t1, t2, end_cutscene_advance_pressed

cutscene_accept_key:
    li a0, 1

end_cutscene_advance_pressed:
    ret

# Descarta eventos pendentes, exibe o texto e espera um novo evento valido.
# O READY e baseado em eventos: ler KDMMIO_Data consome exatamente um evento.
show_text_cutscene:
    addi sp, sp, -4
    sw ra, 0(sp)

    call discard_pending_keyboard_events

cutscene_render_text:
    la t0, cutscene_text_visible
    li t1, 1
    sw t1, 0(t0)

    call clear_input_frame
    call begin_frame
    call draw_cutscene_screen
    call end_frame

cutscene_wait_new_event:
    li t0, KDMMIO_Ctrl
    lw t1, 0(t0)
    andi t1, t1, 1
    beqz t1, cutscene_wait_new_event

    li t0, KDMMIO_Data
    lw a0, 0(t0)
    li t2, 32
    beq a0, t2, end_show_text_cutscene
    li t2, 10
    beq a0, t2, end_show_text_cutscene
    li t2, 13
    bne a0, t2, cutscene_wait_new_event

end_show_text_cutscene:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

show_text_cutscene_3:
    j show_text_cutscene

discard_pending_keyboard_events:
    li t0, KDMMIO_Ctrl

cutscene_discard_pending_loop:
    lw t1, 0(t0)
    andi t1, t1, 1
    beqz t1, end_discard_pending_keyboard_events
    li t2, KDMMIO_Data
    lw t3, 0(t2)
    j cutscene_discard_pending_loop

end_discard_pending_keyboard_events:
    ret

update_cutscene:
    addi sp, sp, -4
    sw ra, 0(sp)

    call cutscene_advance_pressed
    beqz a0, end_update_cutscene
    j show_current_text_cutscene

advance_cutscene:
    call clear_input_frame

    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_CUTSCENE_INTRO
    beq t1, t2, advance_cutscene_to_level1
    li t2, STATE_CUTSCENE_LEVEL2
    beq t1, t2, advance_cutscene_to_level2
    li t2, STATE_CUTSCENE_LEVEL3
    beq t1, t2, advance_cutscene_to_level3
    j end_update_cutscene

show_current_text_cutscene:
    call show_text_cutscene
    j advance_cutscene

advance_cutscene_to_level1:
    call set_state_level1
    j finish_advance_cutscene

advance_cutscene_to_level2:
    call set_state_level2
    j finish_advance_cutscene

advance_cutscene_to_level3:
    call set_state_level3

finish_advance_cutscene:
    call clear_input_frame

end_update_cutscene:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

update_post_boss_detonator:
    addi sp, sp, -4
    sw ra, 0(sp)

    call cutscene_advance_pressed
    beqz a0, end_update_post_boss_detonator
    j advance_to_post_boss_explosion

advance_to_post_boss_explosion:
    call clear_input_frame
    call set_state_cutscene_explosion
    call clear_input_frame
    j end_update_post_boss_detonator

end_update_post_boss_detonator:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

update_post_boss_explosion:
    addi sp, sp, -4
    sw ra, 0(sp)

    call discard_pending_keyboard_events
    call begin_frame
    call draw_cutscene_screen
    call end_frame
    call wait_post_boss_explosion_key
    jal show_text_cutscene_3
    call set_state_victory

end_update_post_boss_explosion:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

wait_post_boss_explosion_key:
    li t0, KDMMIO_Ctrl
    lw t1, 0(t0)
    andi t1, t1, 1
    beqz t1, wait_post_boss_explosion_key

    li t0, KDMMIO_Data
    lw a0, 0(t0)
    li t2, 32
    beq a0, t2, end_wait_post_boss_explosion_key
    li t2, 10
    beq a0, t2, end_wait_post_boss_explosion_key
    li t2, 13
    bne a0, t2, wait_post_boss_explosion_key

end_wait_post_boss_explosion_key:
    ret

# Entrada a0=score; retorno a0=1 RETRY, a0=0 LEAVE.
game_over_screen:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, game_over_score
    sw a0, 0(t0)
    la t0, game_over_selected
    sw zero, 0(t0)

game_over_redraw:
    call begin_frame
    call draw_game_over_screen
    call end_frame
    call menu_wait_key

    li t0, 'q'
    beq a0, t0, game_over_leave
    li t0, 'Q'
    beq a0, t0, game_over_leave

    li t0, 'w'
    beq a0, t0, game_over_toggle
    li t0, 'W'
    beq a0, t0, game_over_toggle
    li t0, 'k'
    beq a0, t0, game_over_toggle
    li t0, 'K'
    beq a0, t0, game_over_toggle
    li t0, 's'
    beq a0, t0, game_over_toggle
    li t0, 'S'
    beq a0, t0, game_over_toggle
    li t0, 'j'
    beq a0, t0, game_over_toggle
    li t0, 'J'
    beq a0, t0, game_over_toggle

    li t0, 32
    beq a0, t0, game_over_confirm
    li t0, 10
    beq a0, t0, game_over_confirm
    li t0, 13
    beq a0, t0, game_over_confirm
    j game_over_redraw

game_over_toggle:
    la t0, game_over_selected
    lw t1, 0(t0)
    xori t1, t1, 1
    sw t1, 0(t0)
    j game_over_redraw

game_over_confirm:
    la t0, game_over_selected
    lw t1, 0(t0)
    bnez t1, game_over_leave
    li a0, 1
    j game_over_return

game_over_leave:
    li a0, 0

game_over_return:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# Entrada a0=score; retorno a0=1 MENU, a0=0 LEAVE.
victory_screen:
    addi sp, sp, -4
    sw ra, 0(sp)

    call discard_pending_keyboard_events

    la t0, victory_score
    sw a0, 0(t0)
    la t0, victory_selected
    sw zero, 0(t0)

victory_redraw:
    call begin_frame
    call draw_victory_screen
    call end_frame
    call menu_wait_key

    li t0, 'q'
    beq a0, t0, victory_leave
    li t0, 'Q'
    beq a0, t0, victory_leave

    li t0, 'w'
    beq a0, t0, victory_toggle
    li t0, 'W'
    beq a0, t0, victory_toggle
    li t0, 'k'
    beq a0, t0, victory_toggle
    li t0, 'K'
    beq a0, t0, victory_toggle
    li t0, 's'
    beq a0, t0, victory_toggle
    li t0, 'S'
    beq a0, t0, victory_toggle
    li t0, 'j'
    beq a0, t0, victory_toggle
    li t0, 'J'
    beq a0, t0, victory_toggle

    li t0, 32
    beq a0, t0, victory_confirm
    li t0, 10
    beq a0, t0, victory_confirm
    li t0, 13
    beq a0, t0, victory_confirm
    j victory_redraw

victory_toggle:
    la t0, victory_selected
    lw t1, 0(t0)
    xori t1, t1, 1
    sw t1, 0(t0)
    j victory_redraw

victory_confirm:
    la t0, victory_selected
    lw t1, 0(t0)
    bnez t1, victory_leave
    li a0, 1
    j victory_return

victory_leave:
    li a0, 0

victory_return:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# ------------------------------------------------------------
# reset_game_run
# Reinicializa todos os dados mutaveis da partida.
#
# Nao escolhe o estado final.
# Quem chama decide se vai para menu ou level1.
# ------------------------------------------------------------

reset_game_run:
    addi sp, sp, -4
    sw ra, 0(sp)

    call init_game
    call init_player
    call init_bullets
    call init_enemy_bullets
    call init_enemies
    call init_boss
    call init_inventory
    call init_powerups

    lw ra, 0(sp)
    addi sp, sp, 4

    ret
