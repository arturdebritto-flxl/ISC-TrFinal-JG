# ============================================================
# Gerenciamento de fases e hordas
# ============================================================

.text

# ------------------------------------------------------------
# init_level1
# Inicializa os dados específicos da primeira fase: Town.
#
# Entrada: nenhuma
# Saída: contadores da fase 1 configurados
# Modifica: t0, t1
# ------------------------------------------------------------

init_level1:
    la t0, current_wave
    li t1, 1
    sw t1, 0(t0)

    la t0, total_waves
    li t1, TOWN_TOTAL_WAVES
    sw t1, 0(t0)

    la t0, remaining_enemies
    li t1, TOWN_WAVE1_ENEMIES
    sw t1, 0(t0)

    la t0, wave_spawned
    sw zero, 0(t0)

    ret

# ------------------------------------------------------------
# init_level2
# Inicializa os dados especificos da segunda fase: Sewer.
#
# Entrada: nenhuma
# Saida: contadores da fase 2 configurados
# Modifica: t0, t1
# ------------------------------------------------------------

init_level2:
    la t0, current_wave
    li t1, 1
    sw t1, 0(t0)

    la t0, total_waves
    li t1, SEWER_TOTAL_WAVES
    sw t1, 0(t0)

    la t0, remaining_enemies
    li t1, SEWER_WAVE1_ENEMIES
    sw t1, 0(t0)

    la t0, wave_spawned
    sw zero, 0(t0)

    ret

# ------------------------------------------------------------
# init_level3
# Inicializa os dados da terceira fase: Laboratory.
# O boss aparecera somente depois da terceira wave.
#
# Entrada: nenhuma
# Saida: contadores iniciais do laboratorio configurados
# Modifica: t0, t1
# ------------------------------------------------------------

init_level3:
    la t0, current_wave
    li t1, 1
    sw t1, 0(t0)

    la t0, total_waves
    li t1, LABORATORY_TOTAL_WAVES
    sw t1, 0(t0)

    la t0, remaining_enemies
    li t1, LABORATORY_WAVE1_ENEMIES
    sw t1, 0(t0)

    la t0, wave_spawned
    sw zero, 0(t0)

    la t0, boss_active
    sw zero, 0(t0)

    ret

# ------------------------------------------------------------
# handle_next_level_cheat
# Cheat explicito de gameplay: C avanca para a proxima transicao.
# Retorna a0 = 1 quando consumiu a tecla e mudou de fase.
# ------------------------------------------------------------

handle_next_level_cheat:
    addi sp, sp, -4
    sw ra, 0(sp)

    li a0, 0

    la t0, game_state
    lw t1, 0(t0)

    li t2, STATE_LEVEL1
    beq t1, t2, next_level_cheat_state_ok

    li t2, STATE_LEVEL2
    beq t1, t2, next_level_cheat_state_ok

    li t2, STATE_BOSS
    bne t1, t2, end_handle_next_level_cheat

next_level_cheat_state_ok:
    la t0, key_pressed
    lw t1, 0(t0)
    beqz t1, end_handle_next_level_cheat

    la t0, last_key
    lw t1, 0(t0)

    li t2, 'c'
    beq t1, t2, try_next_level_cheat

    li t2, 'C'
    bne t1, t2, end_handle_next_level_cheat

try_next_level_cheat:
    la t0, current_level
    lw t1, 0(t0)

    li t2, LEVEL_TOWN
    beq t1, t2, cheat_to_level2

    li t2, LEVEL_SEWER
    beq t1, t2, cheat_to_level3

    li t2, LEVEL_LABORATORY
    beq t1, t2, cheat_to_victory

    j end_handle_next_level_cheat

cheat_to_level2:
    call reset_transient_level_state
    call set_state_cutscene_level2
    li a0, 1
    j end_handle_next_level_cheat

cheat_to_level3:
    call reset_transient_level_state
    call set_state_cutscene_level3
    li a0, 1
    j end_handle_next_level_cheat

cheat_to_victory:
    call reset_transient_level_state
    call set_state_victory
    li a0, 1

end_handle_next_level_cheat:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# ------------------------------------------------------------
# reset_transient_level_state
# Limpa entidades e timers de fase sem apagar player/inventario.
# ------------------------------------------------------------

reset_transient_level_state:
    addi sp, sp, -4
    sw ra, 0(sp)

    call init_enemies
    call init_bullets
    call init_enemy_bullets
    call init_powerups
    call init_boss

    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# ------------------------------------------------------------
# advance_wave
# Avanca waves e muda de level quando a wave atual termina.
#
# Entrada: remaining_enemies deve estar em 0 para haver avanco
# Saida: atualiza wave, level ou ativa o boss
# Modifica: t0, t1, t2
# ------------------------------------------------------------

advance_wave:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, boss_active
    lw t1, 0(t0)
    bnez t1, end_advance_wave

    la t0, remaining_enemies
    lw t1, 0(t0)
    bnez t1, end_advance_wave

    la t0, current_level
    lw t1, 0(t0)

    li t2, LEVEL_TOWN
    beq t1, t2, advance_town_wave

    li t2, LEVEL_SEWER
    beq t1, t2, advance_sewer_wave

    li t2, LEVEL_LABORATORY
    beq t1, t2, advance_laboratory_wave

    j end_advance_wave


# ------------------------------------------------------------
# Progressao da Town
# ------------------------------------------------------------

advance_town_wave:
    la t0, current_wave
    lw t1, 0(t0)

    li t2, 1
    beq t1, t2, start_town_wave2

    li t2, 2
    beq t1, t2, start_town_wave3

    li t2, 3
    beq t1, t2, start_town_wave4

    li t2, 4
    beq t1, t2, finish_town

    j end_advance_wave

start_town_wave2:
    li t1, 2
    sw t1, 0(t0)

    la t0, remaining_enemies
    li t1, TOWN_WAVE2_ENEMIES
    sw t1, 0(t0)

    la t0, wave_spawned
    sw zero, 0(t0)

    j end_advance_wave

start_town_wave3:
    li t1, 3
    sw t1, 0(t0)

    la t0, remaining_enemies
    li t1, TOWN_WAVE3_ENEMIES
    sw t1, 0(t0)

    la t0, wave_spawned
    sw zero, 0(t0)

    j end_advance_wave


start_town_wave4:
    li t1, 4
    sw t1, 0(t0)

    la t0, remaining_enemies
    li t1, TOWN_WAVE4_ENEMIES
    sw t1, 0(t0)

    la t0, wave_spawned
    sw zero, 0(t0)

    j end_advance_wave


finish_town:
    call set_state_cutscene_level2
    j end_advance_wave


# ------------------------------------------------------------
# Progressao do Sewer
# ------------------------------------------------------------

advance_sewer_wave:
    la t0, current_wave
    lw t1, 0(t0)

    li t2, 1
    beq t1, t2, start_sewer_wave2

    li t2, 2
    beq t1, t2, start_sewer_wave3

    li t2, 3
    beq t1, t2, start_sewer_wave4

    li t2, 4
    beq t1, t2, start_sewer_wave5

    li t2, 5
    beq t1, t2, finish_sewer

    j end_advance_wave


start_sewer_wave2:
    li t1, 2
    sw t1, 0(t0)

    la t0, remaining_enemies
    li t1, SEWER_WAVE2_ENEMIES
    sw t1, 0(t0)

    la t0, wave_spawned
    sw zero, 0(t0)

    j end_advance_wave


start_sewer_wave3:
    li t1, 3
    sw t1, 0(t0)

    la t0, remaining_enemies
    li t1, SEWER_WAVE3_ENEMIES
    sw t1, 0(t0)

    la t0, wave_spawned
    sw zero, 0(t0)

    j end_advance_wave


start_sewer_wave4:
    li t1, 4
    sw t1, 0(t0)

    la t0, remaining_enemies
    li t1, SEWER_WAVE4_ENEMIES
    sw t1, 0(t0)

    la t0, wave_spawned
    sw zero, 0(t0)

    j end_advance_wave


start_sewer_wave5:
    li t1, 5
    sw t1, 0(t0)

    la t0, remaining_enemies
    li t1, SEWER_WAVE5_ENEMIES
    sw t1, 0(t0)

    la t0, wave_spawned
    sw zero, 0(t0)

    j end_advance_wave


finish_sewer:
    call set_state_cutscene_level3
    j end_advance_wave


# ------------------------------------------------------------
# Progressao do Laboratory
# ------------------------------------------------------------

advance_laboratory_wave:
    la t0, current_wave
    lw t1, 0(t0)

    li t2, 1
    beq t1, t2, start_laboratory_wave2

    li t2, 2
    beq t1, t2, start_laboratory_wave3

    li t2, 3
    beq t1, t2, start_boss_fight

    j end_advance_wave


start_laboratory_wave2:
    la t0, current_wave
    li t1, 2
    sw t1, 0(t0)

    la t0, remaining_enemies
    li t1, LABORATORY_WAVE2_ENEMIES
    sw t1, 0(t0)

    la t0, wave_spawned
    sw zero, 0(t0)

    j end_advance_wave


start_laboratory_wave3:
    la t0, current_wave
    li t1, 3
    sw t1, 0(t0)

    la t0, remaining_enemies
    li t1, LABORATORY_WAVE3_ENEMIES
    sw t1, 0(t0)

    la t0, wave_spawned
    sw zero, 0(t0)

    j end_advance_wave


start_boss_fight:
    la t0, boss_active
    lw t1, 0(t0)
    bnez t1, end_advance_wave

    la t0, boss_active
    li t1, 1
    sw t1, 0(t0)

    la t0, boss_x
    li t1, BOSS_START_X
    sw t1, 0(t0)

    la t0, boss_y
    li t1, BOSS_START_Y
    sw t1, 0(t0)

    la t0, boss_hp
    li t1, BOSS_HP_START
    sw t1, 0(t0)

    la t0, boss_direction
    li t1, DIR_RIGHT
    sw t1, 0(t0)

    la t0, boss_attack_timer
    sw zero, 0(t0)

    la t0, boss_melee_timer
    sw zero, 0(t0)

    la t0, boss_heavy_timer
    sw zero, 0(t0)

    la t0, game_state
    li t1, STATE_BOSS
    sw t1, 0(t0)

    la t0, current_level
    li t1, LEVEL_LABORATORY
    sw t1, 0(t0)

    la t0, remaining_enemies
    li t1, BOSS_SUPPORT_ENEMIES
    sw t1, 0(t0)

    la t0, wave_spawned
    sw zero, 0(t0)

    j end_advance_wave


# ------------------------------------------------------------
# Finalizacao da rotina
# ------------------------------------------------------------

end_advance_wave:
    lw ra, 0(sp)
    addi sp, sp, 4

    ret
