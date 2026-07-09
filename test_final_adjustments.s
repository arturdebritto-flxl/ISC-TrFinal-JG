# ============================================================
# Smoke test dos ajustes finais: UZI, cheat de fase e resets.
# ============================================================

.include "System/MACROSv24.s"
.include "src/constants.s"

.include "data/game_data.s"
.include "data/player_data.s"
.include "data/bullet_data.s"
.include "data/enemy_data.s"
.include "data/enemy_bullet_data.s"
.include "data/boss_data.s"
.include "data/powerup_data.s"
.include "data/inventory_data.s"

.data
final_adjustments_pass: .asciz "final adjustments smoke: PASS\n"
final_adjustments_fail: .asciz "final adjustments smoke: FAIL\n"

.text
.globl main

main:
    call reset_game_run

    # Cutscene ignora C/c e ENTER avanca sem reaproveitar o input.
    call set_state_cutscene_intro
    call begin_frame
    call draw_cutscene_screen
    call get_draw_base_address
    lw t1, 0(a0)
    la t0, cutscene_intro_pixels
    lw t2, 0(t0)
    bne t1, t2, fail_final_adjustments

    li a0, 'c'
    call press_cutscene_key
    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_CUTSCENE_INTRO
    bne t1, t2, fail_final_adjustments

    li a0, 13
    call press_cutscene_key
    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_LEVEL1
    bne t1, t2, fail_final_adjustments
    la t0, key_pressed
    lw t1, 0(t0)
    bnez t1, fail_final_adjustments

    call set_state_cutscene_level2
    li a0, 32
    call press_cutscene_key
    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_LEVEL2
    bne t1, t2, fail_final_adjustments

    call set_state_cutscene_level3
    li a0, 32
    call press_cutscene_key
    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_LEVEL3
    bne t1, t2, fail_final_adjustments

    call set_state_level1

    # Tecla 3 nao equipa a UZI antes da coleta.
    call press_key_3
    la t0, weapon_type
    lw t1, 0(t0)
    li t2, WEAPON_NORMAL
    bne t1, t2, fail_final_adjustments

    # Coleta real do drop desbloqueia e adiciona municao, sem equipar.
    la t0, powerup_active
    li t1, 1
    sw t1, 0(t0)
    la t0, powerup_type
    li t1, POWERUP_BOSS_WEAPON
    sw t1, 0(t0)
    la t0, player_x
    lw t1, 0(t0)
    la t0, powerup_x
    sw t1, 0(t0)
    la t0, player_y
    lw t1, 0(t0)
    la t0, powerup_y
    sw t1, 0(t0)
    call check_player_powerup_collisions

    la t0, powerup_active
    lw t1, 0(t0)
    bnez t1, fail_final_adjustments
    la t0, boss_weapon_owned
    lw t1, 0(t0)
    li t2, 1
    bne t1, t2, fail_final_adjustments
    la t0, boss_ammo_count
    lw t1, 0(t0)
    li t2, BOSS_AMMO_GAIN
    bne t1, t2, fail_final_adjustments
    la t0, weapon_type
    lw t1, 0(t0)
    li t2, WEAPON_NORMAL
    bne t1, t2, fail_final_adjustments

    # 3 equipa UZI apos coleta; 1 volta ao normal.
    call press_key_3
    la t0, weapon_type
    lw t1, 0(t0)
    li t2, WEAPON_BOSS
    bne t1, t2, fail_final_adjustments

    call press_key_1
    la t0, weapon_type
    lw t1, 0(t0)
    li t2, WEAPON_NORMAL
    bne t1, t2, fail_final_adjustments

    # 2 exige posse da shotgun.
    call press_key_2
    la t0, weapon_type
    lw t1, 0(t0)
    li t2, WEAPON_NORMAL
    bne t1, t2, fail_final_adjustments
    la t0, shotgun_owned
    li t1, 1
    sw t1, 0(t0)
    call press_key_2
    la t0, weapon_type
    lw t1, 0(t0)
    li t2, WEAPON_SHOTGUN
    bne t1, t2, fail_final_adjustments

    # C limpa entidades transientes e avanca Town -> Sewer.
    la t0, enemy_active
    li t1, 1
    sw t1, 0(t0)
    la t0, bullet_active
    sw t1, 0(t0)
    la t0, enemy_bullet_active
    sw t1, 0(t0)
    la t0, powerup_active
    sw t1, 0(t0)
    la t0, boss_active
    sw t1, 0(t0)
    li a0, 'c'
    call press_cheat_key
    beqz a0, fail_final_adjustments

    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_LEVEL2
    bne t1, t2, fail_final_adjustments
    la t0, current_level
    lw t1, 0(t0)
    li t2, LEVEL_SEWER
    bne t1, t2, fail_final_adjustments
    la t0, enemy_active
    lw t1, 0(t0)
    bnez t1, fail_final_adjustments
    la t0, bullet_active
    lw t1, 0(t0)
    bnez t1, fail_final_adjustments
    la t0, enemy_bullet_active
    lw t1, 0(t0)
    bnez t1, fail_final_adjustments
    la t0, powerup_active
    lw t1, 0(t0)
    bnez t1, fail_final_adjustments
    la t0, boss_active
    lw t1, 0(t0)
    bnez t1, fail_final_adjustments

    # C maiusculo: Sewer -> Laboratory -> Victory.
    li a0, 'C'
    call press_cheat_key
    beqz a0, fail_final_adjustments
    la t0, current_level
    lw t1, 0(t0)
    li t2, LEVEL_LABORATORY
    bne t1, t2, fail_final_adjustments

    li a0, 'C'
    call press_cheat_key
    beqz a0, fail_final_adjustments
    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_VICTORY
    bne t1, t2, fail_final_adjustments

    # Fora de gameplay, C nao altera o estado nem e consumido.
    la t0, game_state
    li t1, STATE_GAME_OVER
    sw t1, 0(t0)
    li a0, 'C'
    call press_cheat_key
    bnez a0, fail_final_adjustments
    la t0, game_state
    lw t1, 0(t0)
    li t2, STATE_GAME_OVER
    bne t1, t2, fail_final_adjustments

    la a0, final_adjustments_pass
    li a7, 4
    ecall
    li a0, 0
    li a7, 93
    ecall

fail_final_adjustments:
    la a0, final_adjustments_fail
    li a7, 4
    ecall
    li a0, 1
    li a7, 93
    ecall

press_key_1:
    li a0, '1'
    j press_weapon_key

press_key_2:
    li a0, '2'
    j press_weapon_key

press_key_3:
    li a0, '3'

press_weapon_key:
    la t0, last_key
    sw a0, 0(t0)
    la t0, key_pressed
    li t1, 1
    sw t1, 0(t0)
    j handle_weapon_select_input

press_cheat_key:
    la t0, last_key
    sw a0, 0(t0)
    la t0, key_pressed
    li t1, 1
    sw t1, 0(t0)
    j handle_next_level_cheat

press_cutscene_key:
    la t0, last_key
    sw a0, 0(t0)
    la t0, key_pressed
    li t1, 1
    sw t1, 0(t0)
    j update_cutscene

.include "src/game_state.s"
.include "src/level_manager.s"
.include "src/input.s"
.include "src/player.s"
.include "src/bullets.s"
.include "src/enemies.s"
.include "src/enemy_bullets.s"
.include "src/boss.s"
.include "src/collision.s"
.include "src/render.s"
.include "src/screens.s"
.include "src/hud.s"
.include "src/powerups.s"
.include "src/inventory.s"
.include "src/game_loop.s"
.include "System/SYSTEMv24.s"
