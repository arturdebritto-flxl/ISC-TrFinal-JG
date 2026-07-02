# ============================================================
# Regressao da prioridade visual: tiro > movimento > ultima
# ============================================================

.include "src/constants.s"
.include "data/game_data.s"
.include "data/player_data.s"
.include "data/bullet_data.s"

.data
facing_tests_passed_message: .asciz "player facing tests: PASS\n"
facing_tests_failed_message: .asciz "player facing tests: FAIL count="

.text
.globl main

main:
    li s0, 0

    # Movimento sem tiro: esquerda.
    li a0, DIR_DOWN
    li a1, DIR_LEFT
    li a2, 1
    li a3, DIR_UP
    li a4, 0
    li a5, DIR_LEFT
    call run_facing_case

    # Movimento sem tiro: cima.
    li a0, DIR_LEFT
    li a1, DIR_UP
    li a2, 1
    li a3, DIR_DOWN
    li a4, 0
    li a5, DIR_UP
    call run_facing_case

    # Tiro parado: baixo.
    li a0, DIR_LEFT
    li a1, DIR_UP
    li a2, 0
    li a3, DIR_DOWN
    li a4, 1
    li a5, DIR_DOWN
    call run_facing_case

    # Movimento e tiro na mesma direcao.
    li a0, DIR_DOWN
    li a1, DIR_UP
    li a2, 1
    li a3, DIR_UP
    li a4, 1
    li a5, DIR_UP
    call run_facing_case

    # Movimento e tiro opostos: tiro vence.
    li a0, DIR_UP
    li a1, DIR_LEFT
    li a2, 1
    li a3, DIR_RIGHT
    li a4, 1
    li a5, DIR_RIGHT
    call run_facing_case

    # Tiro terminou enquanto o movimento continua.
    li a0, DIR_RIGHT
    li a1, DIR_LEFT
    li a2, 1
    li a3, DIR_RIGHT
    li a4, 0
    li a5, DIR_LEFT
    call run_facing_case

    # Movimento terminou enquanto o tiro continua.
    li a0, DIR_LEFT
    li a1, DIR_LEFT
    li a2, 0
    li a3, DIR_DOWN
    li a4, 1
    li a5, DIR_DOWN
    call run_facing_case

    # Parado preserva a ultima direcao visual.
    li a0, DIR_RIGHT
    li a1, DIR_UP
    li a2, 0
    li a3, DIR_DOWN
    li a4, 0
    li a5, DIR_RIGHT
    call run_facing_case

    # Parado depois de andar preserva a direcao do movimento.
    li a0, DIR_UP
    li a1, DIR_LEFT
    li a2, 0
    li a3, DIR_DOWN
    li a4, 0
    li a5, DIR_UP
    call run_facing_case

    # Parado depois de atirar preserva a direcao do tiro.
    li a0, DIR_DOWN
    li a1, DIR_LEFT
    li a2, 0
    li a3, DIR_RIGHT
    li a4, 0
    li a5, DIR_DOWN
    call run_facing_case

    beqz s0, facing_tests_passed

    la a0, facing_tests_failed_message
    li a7, 4
    ecall
    mv a0, s0
    li a7, 1
    ecall
    li a0, 1
    li a7, 93
    ecall

facing_tests_passed:
    la a0, facing_tests_passed_message
    li a7, 4
    ecall
    li a0, 0
    li a7, 93
    ecall

run_facing_case:
    la t0, player_direction
    sw a0, 0(t0)

    la t0, player_move_direction
    sw a1, 0(t0)

    la t0, player_moved
    sw a2, 0(t0)

    la t0, shoot_direction
    sw a3, 0(t0)

    la t0, shoot_hold_timer
    sw a4, 0(t0)

    addi sp, sp, -8
    sw ra, 0(sp)
    sw a5, 4(sp)
    call update_player_facing_direction

    la t0, player_direction
    lw t1, 0(t0)
    lw t2, 4(sp)
    beq t1, t2, facing_case_done
    addi s0, s0, 1

facing_case_done:
    lw ra, 0(sp)
    addi sp, sp, 8
    ret

.include "src/player.s"
