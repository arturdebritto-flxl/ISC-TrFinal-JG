# ============================================================
# Loop principal do jogo
# ============================================================

.text

game_loop:
    addi sp, sp, -4
    sw ra, 0(sp)

loop_frame:
    la t0, frame_counter
    lw t1, 0(t0)
    addi t1, t1, 1
    sw t1, 0(t0)

    la t0, game_state
    lw t1, 0(t0)

    li t2, STATE_MENU
    beq t1, t2, loop_menu

    li t2, STATE_CUTSCENE_INTRO
    beq t1, t2, loop_cutscene

    li t2, STATE_CUTSCENE_LEVEL2
    beq t1, t2, loop_cutscene

    li t2, STATE_CUTSCENE_LEVEL3
    beq t1, t2, loop_cutscene

    li t2, STATE_CUTSCENE_DETONATOR
    beq t1, t2, loop_post_boss_detonator

    li t2, STATE_CUTSCENE_EXPLOSION
    beq t1, t2, loop_post_boss_explosion

    li t2, STATE_LEVEL1
    beq t1, t2, loop_playing_level

    li t2, STATE_LEVEL2
    beq t1, t2, loop_playing_level

    li t2, STATE_LEVEL3
    beq t1, t2, loop_playing_level

    li t2, STATE_BOSS
    beq t1, t2, loop_playing_level

    li t2, STATE_GAME_OVER
    beq t1, t2, loop_game_over

    li t2, STATE_VICTORY
    beq t1, t2, loop_victory

    j loop_frame

loop_menu:
    call menu_game_screen
    beqz a0, leave_game_loop
    call start_new_game_from_menu
    j loop_frame

loop_cutscene:
    call read_input

    call begin_frame
    call draw_cutscene_screen
    call end_frame

    call update_cutscene
    call clear_input_frame
    call frame_delay
    j loop_frame

loop_post_boss_detonator:
    call read_input

    call begin_frame
    call draw_cutscene_screen
    call end_frame

    call update_post_boss_detonator
    call clear_input_frame
    call frame_delay
    j loop_frame

loop_post_boss_explosion:
    call update_post_boss_explosion
    call clear_input_frame
    j loop_frame

loop_playing_level:
    call read_input
    call handle_next_level_cheat
    bnez a0, render_cheat_transition_frame

    call update_player
    call update_bullets
    call update_enemy_bullets

    call spawn_wave_if_needed
    call update_enemies
    call update_boss

    call update_powerups
    call update_inventory

    call check_bullet_enemy_collisions
    call check_bullet_boss_collisions
    call check_enemy_player_collisions
    call check_enemy_bullet_player_collisions
    call check_player_powerup_collisions

    call advance_wave
    call update_town_exit
    call update_animation_frame

    call begin_frame

    call draw_background
    call draw_player_square
    call draw_enemies
    call draw_boss_square
    call draw_bullets
    call draw_enemy_bullets
    call draw_powerups
    call draw_inventory
    call draw_hud

    call end_frame

finish_playing_frame:
    call clear_input_frame
    call frame_delay

    j loop_frame

render_cheat_transition_frame:
    call begin_frame

    la t0, game_state
    lw t1, 0(t0)

    li t2, STATE_CUTSCENE_LEVEL2
    beq t1, t2, draw_cheat_cutscene_frame

    li t2, STATE_CUTSCENE_LEVEL3
    beq t1, t2, draw_cheat_cutscene_frame

    li t2, STATE_CUTSCENE_DETONATOR
    beq t1, t2, draw_cheat_cutscene_frame

    li t2, STATE_CUTSCENE_EXPLOSION
    beq t1, t2, draw_cheat_cutscene_frame

    li t2, STATE_VICTORY
    beq t1, t2, draw_cheat_victory_frame

    j end_cheat_transition_frame

draw_cheat_cutscene_frame:
    call draw_cutscene_screen
    j end_cheat_transition_frame

draw_cheat_victory_frame:
    la t0, score
    lw t1, 0(t0)
    la t0, victory_score
    sw t1, 0(t0)
    la t0, victory_selected
    sw zero, 0(t0)
    call draw_victory_screen

end_cheat_transition_frame:
    call end_frame
    j finish_playing_frame

loop_game_over:
    la t0, score
    lw a0, 0(t0)
    call game_over_screen
    beqz a0, leave_game_loop
    call start_new_game_from_menu
    j loop_frame

loop_victory:
    la t0, score
    lw a0, 0(t0)
    call victory_screen
    beqz a0, leave_game_loop
    call reset_game_run
    call set_state_menu
    j loop_frame

leave_game_loop:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

frame_delay:
    li a0, DEBUG_FRAME_DELAY_MS
    li a7, 132
    ecall
    ret

debug_stop_after_frames:
    la t0, frame_counter
    lw t1, 0(t0)

    li t2, DEBUG_LOOP_FRAMES
    blt t1, t2, end_debug_stop_after_frames

    li a7, 10
    ecall

end_debug_stop_after_frames:
    ret

debug_draw_core_state:
    j draw_hud
