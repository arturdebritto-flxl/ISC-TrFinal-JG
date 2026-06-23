# ============================================================
# Logica dos projeteis inimigos
# ============================================================

.text

init_enemy_bullets:
    li t1, 0

init_enemy_bullets_loop:
    li t2, MAX_ENEMY_BULLETS
    beq t1, t2, end_init_enemy_bullets

    slli t3, t1, 2

    la t0, enemy_bullet_active
    add t4, t0, t3
    sw zero, 0(t4)

    la t0, enemy_bullet_life
    add t4, t0, t3
    sw zero, 0(t4)

    addi t1, t1, 1
    j init_enemy_bullets_loop

end_init_enemy_bullets:
    ret

spawn_enemy_bullet:
    li a4, ENEMY_PROJECTILE_SPITTER
    j spawn_enemy_bullet_typed

spawn_enemy_bullet_typed:
    li t1, 0

find_free_enemy_bullet_loop:
    li t2, MAX_ENEMY_BULLETS
    beq t1, t2, end_spawn_enemy_bullet

    slli t3, t1, 2

    la t0, enemy_bullet_active
    add t4, t0, t3
    lw t5, 0(t4)
    beqz t5, create_enemy_bullet_here

    addi t1, t1, 1
    j find_free_enemy_bullet_loop

create_enemy_bullet_here:
    li t5, ENEMY_BULLET_ACTIVE
    sw t5, 0(t4)

    la t0, enemy_bullet_x
    add t6, t0, t3
    sw a0, 0(t6)

    la t0, enemy_bullet_y
    add t6, t0, t3
    sw a1, 0(t6)

    la t0, enemy_bullet_dx
    add t6, t0, t3
    sw a2, 0(t6)

    la t0, enemy_bullet_dy
    add t6, t0, t3
    sw a3, 0(t6)

    la t0, enemy_bullet_type
    add t6, t0, t3
    sw a4, 0(t6)

    li t5, ENEMY_PROJECTILE_BOSS_HEAVY
    beq a4, t5, create_boss_heavy_bullet

create_spitter_bullet:
    li t5, SPITTER_PROJECTILE_SIZE
    la t0, enemy_bullet_size
    add t6, t0, t3
    sw t5, 0(t6)

    li t5, SPITTER_PROJECTILE_DAMAGE
    la t0, enemy_bullet_damage
    add t6, t0, t3
    sw t5, 0(t6)

    li t5, SPITTER_PROJECTILE_LIFE
    la t0, enemy_bullet_life
    add t6, t0, t3
    sw t5, 0(t6)
    j end_spawn_enemy_bullet

create_boss_heavy_bullet:
    li t5, BOSS_PROJECTILE_SIZE
    la t0, enemy_bullet_size
    add t6, t0, t3
    sw t5, 0(t6)

    li t5, BOSS_PROJECTILE_DAMAGE
    la t0, enemy_bullet_damage
    add t6, t0, t3
    sw t5, 0(t6)

    li t5, BOSS_PROJECTILE_LIFE
    la t0, enemy_bullet_life
    add t6, t0, t3
    sw t5, 0(t6)

end_spawn_enemy_bullet:
    ret

update_enemy_bullets:
    la t0, game_state
    lw t1, 0(t0)

    li t2, STATE_LEVEL1
    beq t1, t2, update_enemy_bullets_state_ok

    li t2, STATE_LEVEL2
    beq t1, t2, update_enemy_bullets_state_ok

    li t2, STATE_BOSS
    beq t1, t2, update_enemy_bullets_state_ok

    ret

update_enemy_bullets_state_ok:
    li t1, 0

update_enemy_bullets_loop:
    li t2, MAX_ENEMY_BULLETS
    beq t1, t2, end_update_enemy_bullets

    slli t3, t1, 2

    la t0, enemy_bullet_active
    add t4, t0, t3
    lw t5, 0(t4)
    beqz t5, next_enemy_bullet_update

    la t0, enemy_bullet_life
    add t4, t0, t3
    lw t5, 0(t4)
    addi t5, t5, -1
    sw t5, 0(t4)
    blez t5, deactivate_enemy_bullet

    la t0, enemy_bullet_x
    add t4, t0, t3
    lw t5, 0(t4)
    la t0, enemy_bullet_dx
    add t6, t0, t3
    lw t6, 0(t6)
    add t5, t5, t6
    blt t5, zero, deactivate_enemy_bullet
    li t6, 319
    bgt t5, t6, deactivate_enemy_bullet
    sw t5, 0(t4)

    la t0, enemy_bullet_y
    add t4, t0, t3
    lw t5, 0(t4)
    la t0, enemy_bullet_dy
    add t6, t0, t3
    lw t6, 0(t6)
    add t5, t5, t6
    blt t5, zero, deactivate_enemy_bullet
    li t6, 239
    bgt t5, t6, deactivate_enemy_bullet
    sw t5, 0(t4)

    j next_enemy_bullet_update

deactivate_enemy_bullet:
    la t0, enemy_bullet_active
    add t4, t0, t3
    sw zero, 0(t4)

next_enemy_bullet_update:
    addi t1, t1, 1
    j update_enemy_bullets_loop

end_update_enemy_bullets:
    ret
