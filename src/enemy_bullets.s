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
    addi sp, sp, -4
    sw ra, 0(sp)
    la t0, game_state
    lw t1, 0(t0)

    li t2, STATE_LEVEL1
    beq t1, t2, update_enemy_bullets_state_ok

    li t2, STATE_LEVEL2
    beq t1, t2, update_enemy_bullets_state_ok

    li t2, STATE_LEVEL3
    beq t1, t2, update_enemy_bullets_state_ok

    li t2, STATE_BOSS
    beq t1, t2, update_enemy_bullets_state_ok

    j end_update_enemy_bullets

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

    la t0, current_level
    lw t5, 0(t0)
    li t6, LEVEL_TOWN
    bne t5, t6, move_enemy_bullet_without_town_obstacles

    addi sp, sp, -4
    sw t1, 0(sp)
    mv a0, t1
    call move_town_enemy_bullet_with_substeps
    lw t1, 0(sp)
    addi sp, sp, 4
    slli t3, t1, 2
    beqz a0, deactivate_enemy_bullet
    j next_enemy_bullet_update

move_enemy_bullet_without_town_obstacles:
    slli t3, t1, 2

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
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# Usa a mesma broad phase swept e candidatos internos dos tiros do jogador.
move_town_enemy_bullet_with_substeps:
    addi sp, sp, -28
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)
    sw s5, 24(sp)

    slli s0, a0, 2
    la t0, enemy_bullet_x
    add t0, t0, s0
    lw s1, 0(t0)
    la t0, enemy_bullet_y
    add t0, t0, s0
    lw s2, 0(t0)
    la t0, enemy_bullet_dx
    add t0, t0, s0
    lw s3, 0(t0)
    la t0, enemy_bullet_dy
    add t0, t0, s0
    lw s4, 0(t0)
    la t0, enemy_bullet_size
    add t0, t0, s0
    lw s5, 0(t0)

    mv a0, s1
    mv a1, s2
    mv a2, s3
    mv a3, s4
    mv a4, s5
    call move_town_projectile_swept
    beqz a0, finish_move_town_enemy_bullet_with_substeps

    add t1, s1, s3
    la t0, enemy_bullet_x
    add t0, t0, s0
    sw t1, 0(t0)
    add t1, s2, s4
    la t0, enemy_bullet_y
    add t0, t0, s0
    sw t1, 0(t0)
    li a0, 1

finish_move_town_enemy_bullet_with_substeps:
    lw s5, 24(sp)
    lw s4, 20(sp)
    lw s3, 16(sp)
    lw s2, 12(sp)
    lw s1, 8(sp)
    lw s0, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 28
    ret
