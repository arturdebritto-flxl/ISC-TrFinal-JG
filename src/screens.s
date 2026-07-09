# =====================================================
# Telas de menus, game over e vitoria
# =====================================================

.text

# ------------------------------------------------------------
# update_menu. Se SPACE ou ENTER for pressionado, inicia o jogo.
# ------------------------------------------------------------

update_menu:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, key_pressed
    lw t1, 0(t0)
    beqz t1, end_update_menu

    la t0, last_key
    lw t1, 0(t0)

    # SPACE = 32
    li t2, 32
    beq t1, t2, start_new_game_from_menu

    # ENTER pode vir como 10
    li t2, 10
    beq t1, t2, start_new_game_from_menu

    # ENTER pode vir como 13
    li t2, 13
    beq t1, t2, start_new_game_from_menu

    j end_update_menu


start_new_game_from_menu:
    call clear_input_frame

    li a0, 72
    li a1, 120
    li a2, 9
    li a3, 80
    li a7, 31
    ecall

    call reset_game_run
    call set_state_cutscene_intro

    call clear_input_frame

    j end_update_menu


end_update_menu:
    lw ra, 0(sp)
    addi sp, sp, 4

    ret

# ------------------------------------------------------------
# update_cutscene. SPACE ou ENTER avanca para a fase associada.
# Outras teclas, inclusive C/c, nao alteram o estado.
# ------------------------------------------------------------

update_cutscene:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, key_pressed
    lw t1, 0(t0)
    beqz t1, end_update_cutscene

    la t0, last_key
    lw t1, 0(t0)
    li t2, 32
    beq t1, t2, advance_cutscene
    li t2, 10
    beq t1, t2, advance_cutscene
    li t2, 13
    bne t1, t2, end_update_cutscene

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

# ------------------------------------------------------------
# update_game_over. Se R ou T for pressionado, volta ao menu.
# ------------------------------------------------------------

update_game_over:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, key_pressed
    lw t1, 0(t0)
    beqz t1, end_update_game_over

    la t0, last_key
    lw t1, 0(t0)

    li t2, 't'
    beq t1, t2, return_to_menu_game_over

    li t2, 'T'
    beq t1, t2, return_to_menu_game_over

    li t2, 'r'
    beq t1, t2, return_to_menu_game_over

    li t2, 'R'
    beq t1, t2, return_to_menu_game_over

    j end_update_game_over

return_to_menu_game_over:
    call clear_input_frame
    call reset_game_run
    call set_state_menu
    call clear_input_frame

end_update_game_over:
    lw ra, 0(sp)
    addi sp, sp, 4

    ret

# ------------------------------------------------------------
# update_victory. Se R ou T for pressionado, volta ao menu.
# ------------------------------------------------------------

update_victory:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, key_pressed
    lw t1, 0(t0)
    beqz t1, end_update_victory

    la t0, last_key
    lw t1, 0(t0)

    li t2, 't'
    beq t1, t2, return_to_menu_victory

    li t2, 'T'
    beq t1, t2, return_to_menu_victory

    li t2, 'r'
    beq t1, t2, return_to_menu_victory

    li t2, 'R'
    beq t1, t2, return_to_menu_victory

    j end_update_victory

return_to_menu_victory:
    call clear_input_frame
    call reset_game_run
    call set_state_menu
    call clear_input_frame

end_update_victory:
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
