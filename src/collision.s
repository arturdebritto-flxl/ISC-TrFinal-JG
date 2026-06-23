# ============================================================
# Colisoes do jogo
# ============================================================

.text

# ------------------------------------------------------------
# check_bullet_enemy_collisions
# Verifica colisao entre tiros ativos e inimigos ativos.
#
# Regra:
#   bullet 3x3 contra enemy 8x8
#
# Se colidir:
#   bullet_active = 0
#   enemy_hp -= 1
#   se enemy_hp <= 0:
#       enemy_active = 0
#       remaining_enemies -= 1
#       score += pontos conforme tipo
#
# Modifica: t0-t6, a0-a4
# ------------------------------------------------------------

check_bullet_enemy_collisions:
    addi sp, sp, -4
    sw ra, 0(sp)

    li t1, 0                      # indice do tiro

bullet_collision_loop:
    li t6, MAX_BULLETS
    beq t1, t6, end_bullet_enemy_collisions

    slli t2, t1, 2                # offset do tiro = indice * 4

    # Verifica se o tiro esta ativo
    la t0, bullet_active
    add t5, t0, t2
    lw t6, 0(t5)
    beqz t6, next_collision_bullet

    # a0 = bullet_x
    la t0, bullet_x
    add t5, t0, t2
    lw a0, 0(t5)

    # a1 = bullet_y
    la t0, bullet_y
    add t5, t0, t2
    lw a1, 0(t5)

    li t3, 0                      # indice do inimigo

enemy_collision_loop:
    li t6, MAX_ENEMIES
    beq t3, t6, next_collision_bullet

    slli t4, t3, 2                # offset do inimigo = indice * 4

    # Verifica se o inimigo esta ativo
    la t0, enemy_active
    add t5, t0, t4
    lw t6, 0(t5)
    beqz t6, next_collision_enemy

    # a2 = enemy_x
    la t0, enemy_x
    add t5, t0, t4
    lw a2, 0(t5)

    # a3 = enemy_y
    la t0, enemy_y
    add t5, t0, t4
    lw a3, 0(t5)

    # --------------------------------------------------------
    # AABB: bullet 3x3 contra enemy 8x8
    # Sem colisao se:
    #   bullet_right <= enemy_left
    #   bullet_left  >= enemy_right
    #   bullet_bottom <= enemy_top
    #   bullet_top    >= enemy_bottom
    # --------------------------------------------------------

    # bullet_right = bullet_x + BULLET_SIZE
    li t6, BULLET_SIZE
    add a4, a0, t6
    ble a4, a2, next_collision_enemy

    # enemy_right = enemy_x + ENEMY_SIZE
    li t6, ENEMY_SIZE
    add a4, a2, t6
    bge a0, a4, next_collision_enemy

    # bullet_bottom = bullet_y + BULLET_SIZE
    li t6, BULLET_SIZE
    add a4, a1, t6
    ble a4, a3, next_collision_enemy

    # enemy_bottom = enemy_y + ENEMY_SIZE
    li t6, ENEMY_SIZE
    add a4, a3, t6
    bge a1, a4, next_collision_enemy

    # --------------------------------------------------------
    # Colisao confirmada
    # --------------------------------------------------------

    # Desativa tiro
    la t0, bullet_active
    add t5, t0, t2
    sw zero, 0(t5)

    la t0, bullet_damage
    add t5, t0, t2
    lw a5, 0(t5)
    bgtz a5, bullet_damage_ok
    li a5, WEAPON_NORMAL_DAMAGE

bullet_damage_ok:
    la t0, enemy_hp
    add t5, t0, t4
    lw t6, 0(t5)
    sub t6, t6, a5
    sw t6, 0(t5)

    # Se ainda tem HP, nao morre
    bgtz t6, next_collision_bullet

    # Desativa inimigo
    la t0, enemy_active
    add t5, t0, t4
    sw zero, 0(t5)

    # remaining_enemies -= 1
    la t0, remaining_enemies
    lw t6, 0(t0)
    addi t6, t6, -1
    sw t6, 0(t0)

    # score += pontuacao conforme tipo
    la t0, enemy_type
    add t5, t0, t4
    lw t6, 0(t5)

    li a4, RAT_COMMON
    beq t6, a4, score_common_rat

    li a4, RAT_ECHO
    beq t6, a4, score_echo_rat

    li a4, RAT_MUTANT
    beq t6, a4, score_mutant_rat

    li a4, RAT_SPITTER
    beq t6, a4, score_spitter_rat

    # fallback
    li a4, SCORE_RAT_COMMON
    j apply_rat_score

score_common_rat:
    li a4, SCORE_RAT_COMMON
    j apply_rat_score

score_echo_rat:
    li a4, SCORE_RAT_ECHO
    j apply_rat_score

score_mutant_rat:
    li a4, SCORE_RAT_MUTANT
    j apply_rat_score

score_spitter_rat:
    li a4, SCORE_RAT_SPITTER

apply_rat_score:
    la t0, score
    lw t6, 0(t0)
    add t6, t6, a4
    sw t6, 0(t0)

    addi sp, sp, -12
    sw t1, 0(sp)
    sw a2, 4(sp)
    sw a3, 8(sp)

    la t0, current_level
    lw t6, 0(t0)
    li a4, LEVEL_SEWER
    bne t6, a4, skip_shotgun_unlock
    call unlock_shotgun

skip_shotgun_unlock:
    lw a2, 4(sp)
    lw a3, 8(sp)
    mv a0, a2
    mv a1, a3
    call spawn_powerup_from_enemy_death
    lw t1, 0(sp)
    addi sp, sp, 12

    j next_collision_bullet

next_collision_enemy:
    addi t3, t3, 1
    j enemy_collision_loop

next_collision_bullet:
    addi t1, t1, 1
    j bullet_collision_loop

end_bullet_enemy_collisions:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret


# ------------------------------------------------------------
# check_enemy_player_collisions
# Verifica colisao entre inimigos ativos e jogador.
#
# Regra:
#   player 8x8 contra enemy 8x8
#
# Se colidir:
#   enemy_active = 0
#   remaining_enemies -= 1
#   player_lives -= 1
#   se player_lives <= 0 -> GAME OVER
#
# Modifica: t0-t6, a0-a4
# ------------------------------------------------------------

check_enemy_player_collisions:
    addi sp, sp, -4
    sw ra, 0(sp)

    # a0 = player_x
    la t0, player_x
    lw a0, 0(t0)

    # a1 = player_y
    la t0, player_y
    lw a1, 0(t0)

    li t1, 0                      # indice do inimigo

enemy_player_loop:
    li t2, MAX_ENEMIES
    beq t1, t2, end_enemy_player_collisions

    slli t3, t1, 2                # offset = indice * 4

    # Verifica se inimigo esta ativo
    la t0, enemy_active
    add t4, t0, t3
    lw t5, 0(t4)
    beqz t5, next_enemy_player

    # a2 = enemy_x
    la t0, enemy_x
    add t4, t0, t3
    lw a2, 0(t4)

    # a3 = enemy_y
    la t0, enemy_y
    add t4, t0, t3
    lw a3, 0(t4)

    # AABB: player 8x8 contra enemy 8x8
    li t6, PLAYER_SIZE
    add a4, a0, t6
    ble a4, a2, next_enemy_player

    li t6, ENEMY_SIZE
    add a4, a2, t6
    bge a0, a4, next_enemy_player

    li t6, PLAYER_SIZE
    add a4, a1, t6
    ble a4, a3, next_enemy_player

    li t6, ENEMY_SIZE
    add a4, a3, t6
    bge a1, a4, next_enemy_player

    # Colisao confirmada: desativa inimigo
    la t0, enemy_active
    add t4, t0, t3
    sw zero, 0(t4)

    # remaining_enemies -= 1
    la t0, remaining_enemies
    lw t5, 0(t0)
    addi t5, t5, -1
    sw t5, 0(t0)

    # player_lives -= 1
    la t0, player_lives
    lw t5, 0(t0)
    addi t5, t5, -1
    sw t5, 0(t0)

    # Se vidas chegaram a 0, GAME OVER
    blez t5, enemy_player_game_over

    # Evita que varios inimigos tirem varias vidas no mesmo frame
    j end_enemy_player_collisions

enemy_player_game_over:
    call set_state_game_over
    j end_enemy_player_collisions

next_enemy_player:
    addi t1, t1, 1
    j enemy_player_loop

end_enemy_player_collisions:
    lw ra, 0(sp)
    addi sp, sp, 4

    ret

# ------------------------------------------------------------
# check_enemy_bullet_player_collisions
# Verifica colisao entre projeteis inimigos e jogador.
#
# Regra:
#   enemy bullet 3x3 contra player 8x8
#
# Se colidir:
#   enemy_bullet_active = 0
#   player_lives -= 1
#   se player_lives <= 0 -> GAME OVER
#
# Modifica: t0-t6, a0-a4
# ------------------------------------------------------------

check_enemy_bullet_player_collisions:
    addi sp, sp, -4
    sw ra, 0(sp)

    # a2 = player_x
    la t0, player_x
    lw a2, 0(t0)

    # a3 = player_y
    la t0, player_y
    lw a3, 0(t0)

    li t1, 0

enemy_bullet_player_loop:
    li t2, MAX_ENEMY_BULLETS
    beq t1, t2, end_enemy_bullet_player_collisions

    slli t3, t1, 2

    # Verifica se o projeteil inimigo esta ativo
    la t0, enemy_bullet_active
    add t4, t0, t3
    lw t5, 0(t4)
    beqz t5, next_enemy_bullet_player

    # a0 = enemy_bullet_x
    la t0, enemy_bullet_x
    add t4, t0, t3
    lw a0, 0(t4)

    # a1 = enemy_bullet_y
    la t0, enemy_bullet_y
    add t4, t0, t3
    lw a1, 0(t4)

    # --------------------------------------------------------
    # AABB: enemy bullet 3x3 contra player 8x8
    # --------------------------------------------------------

    la t0, enemy_bullet_size
    add t4, t0, t3
    lw t6, 0(t4)
    bgtz t6, enemy_bullet_size_ok
    li t6, ENEMY_BULLET_SIZE

enemy_bullet_size_ok:
    add a4, a0, t6
    ble a4, a2, next_enemy_bullet_player

    # player_right = player_x + PLAYER_SIZE
    li t6, PLAYER_SIZE
    add a4, a2, t6
    bge a0, a4, next_enemy_bullet_player

    la t0, enemy_bullet_size
    add t4, t0, t3
    lw t6, 0(t4)
    bgtz t6, enemy_bullet_size_y_ok
    li t6, ENEMY_BULLET_SIZE

enemy_bullet_size_y_ok:
    add a4, a1, t6
    ble a4, a3, next_enemy_bullet_player

    # player_bottom = player_y + PLAYER_SIZE
    li t6, PLAYER_SIZE
    add a4, a3, t6
    bge a1, a4, next_enemy_bullet_player

    # ---------------------------------------------------------
    # Colisao confirmada
    # ---------------------------------------------------------

    # Desativa projeteil inimigo
    la t0, enemy_bullet_active
    add t4, t0, t3
    sw zero, 0(t4)

    la t0, enemy_bullet_damage
    add t4, t0, t3
    lw t6, 0(t4)
    bgtz t6, enemy_bullet_damage_ok
    li t6, SPITTER_PROJECTILE_DAMAGE

enemy_bullet_damage_ok:
    la t0, player_lives
    lw t5, 0(t0)
    sub t5, t5, t6
    sw t5, 0(t0)

    # Se vidas <= 0, GAME OVER
    blez t5, enemy_bullet_player_game_over

    j next_enemy_bullet_player

enemy_bullet_player_game_over:
    call set_state_game_over
    j end_enemy_bullet_player_collisions

next_enemy_bullet_player:
    addi t1, t1, 1
    j enemy_bullet_player_loop

end_enemy_bullet_player_collisions:
    lw ra, 0(sp)
    addi sp, sp, 4

    ret


# ------------------------------------------------------------
# check_bullet_boss_collisions
# Verifica colisao entre tiros do jogador e boss.
#
# Regra:
#   bullet 3x3 contra boss 16x16
#
# Se colidir:
#   bullet_active = 0
#   boss_hp -= 1
#   se boss_hp <= 0:
#       boss_active = 0
#       score += SCORE_BOSS
#       set_state_victory
#
# Modifica: t0-t6, a0-a4
# ------------------------------------------------------------

check_bullet_boss_collisions:
    addi sp, sp, -4
    sw ra, 0(sp)

    la t0, boss_active
    lw t1, 0(t0)
    beqz t1, end_bullet_boss_collisions

    # a2 = boss_x
    la t0, boss_x
    lw a2, 0(t0)

    # a3 = boss_y
    la t0, boss_y
    lw a3, 0(t0)

    li t1, 0

bullet_boss_loop:
    li t2, MAX_BULLETS
    beq t1, t2, end_bullet_boss_collisions

    slli t3, t1, 2

    # Verifica se o tiro esta ativo
    la t0, bullet_active
    add t4, t0, t3
    lw t5, 0(t4)
    beqz t5, next_bullet_boss

    # a0 = bullet_x
    la t0, bullet_x
    add t4, t0, t3
    lw a0, 0(t4)

    # a1 = bullet_y
    la t0, bullet_y
    add t4, t0, t3
    lw a1, 0(t4)

    # --------------------------------------------------------
    # AABB bullet 3x3 contra boss 16x16
    # --------------------------------------------------------

    # bullet_right = bullet_x + BULLET_SIZE
    li t6, BULLET_SIZE
    add a4, a0, t6
    ble a4, a2, next_bullet_boss

    # boss_right = boss_x + BOSS_SIZE
    li t6, BOSS_SIZE
    add a4, a2, t6
    bge a0, a4, next_bullet_boss

    # bullet_bottom = bullet_y + BULLET_SIZE
    li t6, BULLET_SIZE
    add a4, a1, t6
    ble a4, a3, next_bullet_boss

    # boss_bottom = boss_y + BOSS_SIZE
    li t6, BOSS_SIZE
    add a4, a3, t6
    bge a1, a4, next_bullet_boss

    # --------------------------------------------------------
    # Colisao confirmada
    # --------------------------------------------------------

    # Desativa tiro
    la t0, bullet_active
    add t4, t0, t3
    sw zero, 0(t4)

    la t0, bullet_damage
    add t4, t0, t3
    lw a5, 0(t4)
    bgtz a5, boss_bullet_damage_ok
    li a5, WEAPON_NORMAL_DAMAGE

boss_bullet_damage_ok:
    la t0, boss_hp
    lw t5, 0(t0)
    sub t5, t5, a5
    sw t5, 0(t0)

    # Se hp <= 0, derrota boss
    blez t5, boss_defeated

    j next_bullet_boss

boss_defeated:
    # boss_active = 0
    la t0, boss_active
    sw zero, 0(t0)

    # score += SCORE_BOSS
    la t0, score
    lw t5, 0(t0)
    li t6, SCORE_BOSS
    add t5, t5, t6
    sw t5, 0(t0)

    call set_state_victory

    j end_bullet_boss_collisions

next_bullet_boss:
    addi t1, t1, 1
    j bullet_boss_loop

end_bullet_boss_collisions:
    lw ra, 0(sp)
    addi sp, sp, 4

    ret
