# ============================================================
# Arquivo principal
# ============================================================

.include "System/MACROSv24.s"
.include "src/constants.s"

.include "data/game_data.s"
.include "data/boss_data.s"

.text
.globl main

main:
    # Inicializa o jogo e entra na primeira fase
    call init_game
    call set_state_level1

    # Town: Wave 1 -> Wave 2 -> Wave 3 -> Wave 4 -> Sewer
    call simulate_wave_clear
    call simulate_wave_clear
    call simulate_wave_clear
    call simulate_wave_clear
    call set_state_level2

    # Sewer: Wave 1 -> Wave 2 -> Wave 3 -> Wave 4 -> Wave 5 -> Laboratory
    call simulate_wave_clear
    call simulate_wave_clear
    call simulate_wave_clear
    call simulate_wave_clear
    call simulate_wave_clear
    call set_state_level3

    # Laboratory: Wave 1 -> Wave 2 -> Wave 3 -> Boss
    call simulate_wave_clear
    call simulate_wave_clear
    call simulate_wave_clear

# Simula a derrota do boss
    call set_state_victory

    # Limpa a tela uma unica vez
    li a0, 0x00
    li a1, 0
    li a7, 148
    ecall

    # Imprime game_state: esperado 5
    la t0, game_state
    lw a0, 0(t0)
    li a1, 8
    li a2, 8
    li a3, 0x000000FF
    li a4, 0
    li a7, 101
    ecall

    # Imprime current_level: esperado 3
    la t0, current_level
    lw a0, 0(t0)
    li a1, 8
    li a2, 24
    li a3, 0x000000FF
    li a4, 0
    li a7, 101
    ecall

    # Imprime current_wave: esperado 3
    la t0, current_wave
    lw a0, 0(t0)
    li a1, 8
    li a2, 40
    li a3, 0x000000FF
    li a4, 0
    li a7, 101
    ecall

    # Imprime total_waves: esperado 3
    la t0, total_waves
    lw a0, 0(t0)
    li a1, 8
    li a2, 56
    li a3, 0x000000FF
    li a4, 0
    li a7, 101
    ecall

    # Imprime remaining_enemies: esperado 5
    la t0, remaining_enemies
    lw a0, 0(t0)
    li a1, 8
    li a2, 72
    li a3, 0x000000FF
    li a4, 0
    li a7, 101
    ecall

# Imprime boss_active: esperado 1
    la t0, boss_active
    lw a0, 0(t0)
    li a1, 8
    li a2, 88
    li a3, 0x000000FF
    li a4, 0
    li a7, 101
    ecall

    li a7, 10
    ecall


# ------------------------------------------------------------
# simulate_wave_clear
# Funcao de teste.
# Simula a eliminacao de todos os inimigos da wave atual
# e solicita ao core que avance a progressao.
#
# Entrada: nenhuma
# Saida: estado atualizado por advance_wave
# Modifica: t0
# ------------------------------------------------------------

simulate_wave_clear:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, remaining_enemies
    sw zero, 0(t0)

    call advance_wave

    lw ra, 0(sp)
    addi sp, sp, 4

    ret

# Dependencias do handler de cheat incluido em level_manager.s. Este teste
# exercita somente progressao de waves, portanto os resets ficam como stubs.
init_enemies:
init_bullets:
init_enemy_bullets:
init_powerups:
init_boss:
    ret

.include "src/game_state.s"
.include "src/level_manager.s"

.include "System/SYSTEMv24.s"
